/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/database/radio_stations.db.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/models/radio_model.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/artist_bar.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/custom_bar.dart';
import 'package:musify/widgets/custom_search_bar.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/playlist_bar.dart';
import 'package:musify/widgets/radio_station_card.dart';
import 'package:musify/widgets/section_title.dart';
import 'package:musify/widgets/song_bar.dart';

// Global notifier so the search history stays reactive across the app.
final ValueNotifier<List> searchHistoryNotifier = ValueNotifier<List>(
  Hive.box('user').get('searchHistory', defaultValue: []),
);

void reloadSearchHistoryFromStorage() {
  searchHistoryNotifier.value = Hive.box('user')
      .get('searchHistory', defaultValue: []);
}

const _suggestionsDebounce = Duration(milliseconds: 300);
const _maxHistoryItems = 30;
const _maxItemsPerSection = 15;
const _maxArtists = 3;

/// Immutable snapshot of everything the page can show for one query.
class _SearchResults {
  const _SearchResults({
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
    this.radios = const [],
  });

  final List<dynamic> songs;
  final List<Map<String, dynamic>> artists;
  final List<dynamic> albums;
  final List<dynamic> playlists;
  final List<RadioStation> radios;

  bool get isEmpty =>
      songs.isEmpty &&
      artists.isEmpty &&
      albums.isEmpty &&
      playlists.isEmpty &&
      radios.isEmpty;

  _SearchResults copyWith({
    List<dynamic>? songs,
    List<Map<String, dynamic>>? artists,
    List<dynamic>? albums,
    List<dynamic>? playlists,
    List<RadioStation>? radios,
  }) {
    return _SearchResults(
      songs: songs ?? this.songs,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      playlists: playlists ?? this.playlists,
      radios: radios ?? this.radios,
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  final ValueNotifier<bool> _loading = ValueNotifier(false);

  _SearchResults _results = const _SearchResults();
  List<String> _suggestions = [];

  /// The query the current results belong to. Empty means "no search active".
  String _activeQuery = '';

  Timer? _debounce;
  int _searchRequestId = 0;
  int _suggestionRequestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchBar.dispose();
    _inputNode.dispose();
    _loading.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final requestId = ++_suggestionRequestId;

    // An emptied field goes back to the history and drops old results.
    if (value.trim().isEmpty) {
      unawaited(_search(''));
      return;
    }

    _debounce = Timer(_suggestionsDebounce, () async {
      try {
        final suggestions = await getSearchSuggestions(value);
        if (!mounted || requestId != _suggestionRequestId) return;
        setState(() => _suggestions = List<String>.from(suggestions));
      } catch (e, stackTrace) {
        logger.log(
          'Error while fetching search suggestions',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> _submit([String? query]) async {
    if (query != null) {
      _searchBar.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    _inputNode.unfocus();
    await _search(_searchBar.text);
  }

  Future<void> _search(String rawQuery) async {
    final query = rawQuery.trim();
    final requestId = ++_searchRequestId;

    // Anything still pending for suggestions is now irrelevant.
    _debounce?.cancel();
    _suggestionRequestId++;

    if (query.isEmpty) {
      _loading.value = false;
      setState(() {
        _activeQuery = '';
        _suggestions = [];
        _results = const _SearchResults();
      });
      return;
    }

    bool isStale() => !mounted || requestId != _searchRequestId;

    void update(_SearchResults Function(_SearchResults current) change) {
      if (isStale()) return;
      setState(() => _results = change(_results));
    }

    _loading.value = true;
    setState(() {
      _activeQuery = query;
      _suggestions = [];
      // Radio stations are local, so they show up immediately.
      _results = _SearchResults(radios: _searchRadioStations(query));
    });
    _saveToHistory(query);

    // Started once so the songs fallback can reuse it without a second request.
    final artistsFuture = _guard<List<Map<String, dynamic>>>(
      'artists',
      () async =>
          (await searchArtists(query))
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList(),
      const [],
    );

    final songsFuture = _guard<List<dynamic>>('songs', () async {
      final songs = await fetchSongsList(query);
      if (songs.isNotEmpty) return songs;

      final artists = await artistsFuture;
      if (artists.isEmpty) return const [];
      return _fetchSongsForArtist(query, artists.first);
    }, const []);

    final albumsFuture = _guard<List<dynamic>>(
      'albums',
      () => getPlaylists(query: query, type: 'album'),
      const [],
    );

    final playlistsFuture = _guard<List<dynamic>>(
      'playlists',
      () => getPlaylists(query: query, type: 'playlist'),
      const [],
    );

    // Each section appears as soon as its own request finishes.
    await Future.wait([
      artistsFuture.then((v) => update((r) => r.copyWith(artists: v))),
      songsFuture.then((v) => update((r) => r.copyWith(songs: v))),
      albumsFuture.then((v) => update((r) => r.copyWith(albums: v))),
      playlistsFuture.then((v) => update((r) => r.copyWith(playlists: v))),
    ]);

    if (!isStale()) _loading.value = false;
  }

  /// Runs [task], logging and returning [fallback] on failure so one broken
  /// source never blocks the others.
  Future<T> _guard<T>(
    String label,
    Future<T> Function() task,
    T fallback,
  ) async {
    try {
      return await task();
    } catch (e, stackTrace) {
      logger.log(
        'Error while searching online $label',
        error: e,
        stackTrace: stackTrace,
      );
      return fallback;
    }
  }

  /// When a query only matches an artist, look up songs by the artist's name.
  Future<List<dynamic>> _fetchSongsForArtist(
    String query,
    Map<String, dynamic> artist,
  ) async {
    final name = artist['title']?.toString().trim();
    if (name == null || name.isEmpty) return const [];

    final fallbackQueries = <String>{
      if (name.toLowerCase() != query.toLowerCase()) name,
      '$name songs',
      '$name music',
    };

    for (final fallbackQuery in fallbackQueries) {
      final songs = await fetchSongsList(fallbackQuery);
      if (songs.isNotEmpty) return songs;
    }
    return const [];
  }

  List<RadioStation> _searchRadioStations(String query) {
    final needle = query.toLowerCase();
    return radioStationsDB
        .where(
          (station) =>
              station.name.toLowerCase().contains(needle) ||
              (station.genre?.toLowerCase().contains(needle) ?? false),
        )
        .toList();
  }

  void _saveToHistory(String query) {
    // Re-searching an old query moves it back to the top.
    final updated = List.from(searchHistoryNotifier.value)
      ..remove(query)
      ..insert(0, query);
    if (updated.length > _maxHistoryItems) {
      updated.removeRange(_maxHistoryItems, updated.length);
    }
    _writeHistory(updated);
  }

  Future<void> _removeFromHistory(String query) async {
    final confirm = await _showConfirmationDialog() ?? false;
    if (!confirm) return;
    _writeHistory(List.from(searchHistoryNotifier.value)..remove(query));
  }

  void _writeHistory(List updated) {
    searchHistoryNotifier.value = updated;
    unawaited(addOrUpdateData<List>('user', 'searchHistory', updated));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final showQueries = _suggestions.isNotEmpty || _activeQuery.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.search)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: [
            CustomSearchBar(
              loadingProgressNotifier: _loading,
              controller: _searchBar,
              focusNode: _inputNode,
              labelText: '${context.l10n!.search}...',
              onChanged: _onChanged,
              onSubmitted: (_) => _submit(),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showQueries
                  ? _buildQueries()
                  : _buildResults(context, primaryColor),
            ),
            const MiniPlayerBottomSpace(),
          ],
        ),
      ),
    );
  }

  /// Suggestions while typing, otherwise the saved search history.
  Widget _buildQueries() {
    return ValueListenableBuilder<List>(
      key: const ValueKey('queries'),
      valueListenable: searchHistoryNotifier,
      builder: (context, history, _) {
        final items = _suggestions.isNotEmpty
            ? _suggestions
            : history.map((e) => e.toString()).toList();
        final isHistory = _suggestions.isEmpty;

        return Column(
          children: [
            for (var i = 0; i < items.length; i++)
              CustomBar(
                items[i],
                FluentIcons.search_24_regular,
                borderRadius: getItemBorderRadius(i, items.length),
                onTap: () => _submit(items[i]),
                onLongPress: isHistory
                    ? () => _removeFromHistory(items[i])
                    : null,
              ),
          ],
        );
      },
    );
  }

  Widget _buildResults(BuildContext context, Color primaryColor) {
    final l10n = context.l10n!;
    final results = _results;

    return Column(
      key: const ValueKey('results'),
      children: [
        ..._section<Map<String, dynamic>>(
          title: l10n.artists,
          icon: FluentIcons.person_24_filled,
          color: primaryColor,
          items: results.artists,
          limit: _maxArtists,
          itemBuilder: (artist, index, borderRadius) {
            final artistId =
                artist['ytid']?.toString() ?? artist['title']?.toString() ?? '';
            if (artistId.isEmpty) return const SizedBox.shrink();

            return ArtistBar(
              key: listItemKey('search_artist', index, artist),
              artist: artist,
              borderRadius: borderRadius,
              onTap: () => context.push(
                '${NavigationManager.searchPath}/artist/${Uri.encodeComponent(artistId)}',
                extra: artist,
              ),
            );
          },
        ),
        ..._section<dynamic>(
          title: l10n.songs,
          icon: FluentIcons.music_note_1_24_filled,
          color: primaryColor,
          items: results.songs,
          itemBuilder: (song, index, borderRadius) => SongBar(
            song,
            true,
            key: listItemKey('search_song', index, song),
            showMusicDuration: true,
            borderRadius: borderRadius,
          ),
        ),
        ..._section<dynamic>(
          title: l10n.albums,
          icon: FluentIcons.album_24_filled,
          color: primaryColor,
          items: results.albums,
          itemBuilder: (album, index, borderRadius) => PlaylistBar(
            key: listItemKey('search_album', index, album),
            album['title'],
            playlistId: album['ytid'],
            playlistArtwork: album['image'],
            cubeIcon: FluentIcons.cd_16_filled,
            isAlbum: true,
            borderRadius: borderRadius,
          ),
        ),
        ..._section<dynamic>(
          title: l10n.playlists,
          icon: FluentIcons.text_bullet_list_24_filled,
          color: primaryColor,
          items: results.playlists,
          padLast: true,
          itemBuilder: (playlist, index, borderRadius) => PlaylistBar(
            key: listItemKey('search_playlist', index, playlist),
            playlist['title'],
            playlistId: playlist['ytid'],
            playlistArtwork: playlist['image'],
            cubeIcon: FluentIcons.apps_list_24_filled,
            borderRadius: borderRadius,
          ),
        ),
        ..._section<RadioStation>(
          title: l10n.radioStations,
          icon: FluentIcons.speaker_2_24_filled,
          color: primaryColor,
          items: results.radios,
          padLast: true,
          itemBuilder: (station, index, _) => RadioStationCard(
            key: listItemKey('search_radio_station', index, station),
            station: station,
            onPressed: () => _playRadio(station),
          ),
        ),
      ],
    );
  }

  /// A titled block of results; empty input produces no widgets at all.
  List<Widget> _section<T>({
    required String title,
    required IconData icon,
    required Color color,
    required List<T> items,
    required Widget Function(T item, int index, BorderRadius borderRadius)
    itemBuilder,
    int limit = _maxItemsPerSection,
    bool padLast = false,
  }) {
    if (items.isEmpty) return const [];

    final count = items.length > limit ? limit : items.length;

    return [
      SectionTitle(title, color, icon: icon),
      for (var i = 0; i < count; i++)
        Padding(
          padding: padLast && i == count - 1
              ? commonListViewBottomPadding
              : EdgeInsets.zero,
          child: itemBuilder(items[i], i, getItemBorderRadius(i, count)),
        ),
    ];
  }

  Future<void> _playRadio(RadioStation station) async {
    final success = await audioHandler.playRadioStream(
      id: station.id,
      name: station.name,
      streamUrl: station.streamUrl,
      image: station.image,
      genre: station.genre,
    );
    if (!success && mounted) {
      showToast(context, context.l10n!.failedPlayingRadio);
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        confirmationMessage: dialogContext.l10n!.removeSearchQueryQuestion,
        submitMessage: dialogContext.l10n!.confirm,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onSubmit: () => Navigator.of(dialogContext).pop(true),
      ),
    );
  }
}
