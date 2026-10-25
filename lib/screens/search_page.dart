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
import 'package:hive_flutter/hive_flutter.dart';
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
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/sort_chips.dart';

/// The result categories the search page can show, in the order their tabs
/// appear.
enum _SearchCategory { songs, albums, playlists, artists, radioStations }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

// Global ValueNotifier for search history to make it reactive
final ValueNotifier<List> searchHistoryNotifier = ValueNotifier<List>(
  Hive.box('user').get('searchHistory', defaultValue: []),
);

void reloadSearchHistoryFromStorage() {
  searchHistoryNotifier.value = Hive.box('user')
      .get('searchHistory', defaultValue: []);
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  int maxSongsInList = 15;
  List<dynamic> _songsSearchResult = [];
  List<Map<String, dynamic>> _artistsSearchResult = [];
  List<dynamic> _albumsSearchResult = [];
  List<dynamic> _playlistsSearchResult = [];
  List<RadioStation> _radioStationsSearchResult = [];
  List<String> _suggestionsList = [];
  final ScrollController _scrollController = ScrollController();
  _SearchCategory? _shownCategory;
  bool _categoryPickedByUser = false;
  Timer? _debounce;
  int _latestSuggestionRequest = 0;
  int _latestSearchRequest = 0;

  Future<void> _submitSearch([String? query]) async {
    if (query != null) {
      _searchBar.text = query;
      _searchBar.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchBar.text.length),
      );
    }

    _latestSuggestionRequest++;
    _debounce?.cancel();
    _suggestionsList = [];
    if (mounted) setState(() {});

    await search();
    _inputNode.unfocus();
  }

  @override
  void dispose() {
    _searchBar.dispose();
    _inputNode.dispose();
    _fetchingSongs.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> search() async {
    final query = _searchBar.text.trim();
    final requestId = ++_latestSearchRequest;

    if (query.isEmpty) {
      _songsSearchResult = [];
      _artistsSearchResult = [];
      _albumsSearchResult = [];
      _playlistsSearchResult = [];
      _radioStationsSearchResult = [];
      _suggestionsList = [];
      _fetchingSongs.value = false;
      _refreshShownCategory();
      if (mounted) setState(() {});
      return;
    }
    _fetchingSongs.value = true;

    _categoryPickedByUser = false;
    _songsSearchResult = [];
    _artistsSearchResult = [];
    _albumsSearchResult = [];
    _playlistsSearchResult = [];
    _radioStationsSearchResult = radioStationsDB
        .where(
          (station) =>
              station.name.toLowerCase().contains(query.toLowerCase()) ||
              (station.genre?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();
    _refreshShownCategory();
    if (mounted) setState(() {});

    if (!searchHistoryNotifier.value.contains(query)) {
      final updatedHistory = List.from(searchHistoryNotifier.value)
        ..insert(0, query);
      searchHistoryNotifier.value = updatedHistory;
      unawaited(addOrUpdateData<List>('user', 'searchHistory', updatedHistory));
    }

    try {
      final artistsFuture = searchArtists(query);

      Future<void> publishSongs() async {
        try {
          var songs = await fetchSongsList(query);
          if (!mounted || requestId != _latestSearchRequest) return;

          if (songs.isEmpty) {
            final artists = await artistsFuture;
            if (!mounted || requestId != _latestSearchRequest) return;
            if (_artistsSearchResult.isEmpty) {
              _artistsSearchResult = artists
                  .whereType<Map>()
                  .map(Map<String, dynamic>.from)
                  .toList();
            }
            if (_artistsSearchResult.isNotEmpty) {
              songs = await _fetchSongsForResolvedArtist(query);
            }
          }

          if (!mounted || requestId != _latestSearchRequest) return;
          setState(() {
            _songsSearchResult = songs;
            _refreshShownCategory();
          });
        } catch (e, stackTrace) {
          logger.log(
            'Error while searching online songs',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      Future<void> publishArtists() async {
        try {
          final artists = await artistsFuture;
          if (!mounted || requestId != _latestSearchRequest) return;
          setState(() {
            _artistsSearchResult = artists
                .whereType<Map>()
                .map(Map<String, dynamic>.from)
                .toList();
            _refreshShownCategory();
          });
        } catch (e, stackTrace) {
          logger.log(
            'Error while searching online artists',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      Future<void> publishAlbums() async {
        try {
          final albums = await getPlaylists(query: query, type: 'album');
          if (!mounted || requestId != _latestSearchRequest) return;
          setState(() {
            _albumsSearchResult = albums;
            _refreshShownCategory();
          });
        } catch (e, stackTrace) {
          logger.log(
            'Error while searching online albums',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      Future<void> publishPlaylists() async {
        try {
          final playlists = await getPlaylists(query: query, type: 'playlist');
          if (!mounted || requestId != _latestSearchRequest) return;
          setState(() {
            _playlistsSearchResult = playlists;
            _refreshShownCategory();
          });
        } catch (e, stackTrace) {
          logger.log(
            'Error while searching online playlists',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      await Future.wait([
        publishSongs(),
        publishArtists(),
        publishAlbums(),
        publishPlaylists(),
      ]);
    } catch (e, stackTrace) {
      logger.log(
        'Error while searching online songs',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (requestId == _latestSearchRequest) {
        _fetchingSongs.value = false;
        if (mounted) setState(() {});
      }
    }
  }

  Future<List<dynamic>> _fetchSongsForResolvedArtist(String query) async {
    final artistName = _artistsSearchResult.first['title']?.toString().trim();
    if (artistName == null || artistName.isEmpty) return [];

    final fallbackQueries = <String>{
      if (artistName.toLowerCase() != query.trim().toLowerCase()) artistName,
      '$artistName songs',
      '$artistName music',
    };

    for (final fallbackQuery in fallbackQueries) {
      final songs = await fetchSongsList(fallbackQuery);
      if (songs.isNotEmpty) return songs;
    }

    return [];
  }

  /// The categories that actually have something to show, in tab order.
  List<_SearchCategory> get _categoriesWithResults => [
    if (_songsSearchResult.isNotEmpty) _SearchCategory.songs,
    if (_albumsSearchResult.isNotEmpty) _SearchCategory.albums,
    if (_playlistsSearchResult.isNotEmpty) _SearchCategory.playlists,
    if (_artistsSearchResult.isNotEmpty) _SearchCategory.artists,
    if (_radioStationsSearchResult.isNotEmpty) _SearchCategory.radioStations,
  ];

  // Results come back one category at a time, so the shown tab has to be
  // arbitrated again on every arrival: as long as nothing was tapped the first
  // category holding results wins, which lets songs take over a tab that only
  // got picked because albums answered first.
  void _refreshShownCategory() {
    final categories = _categoriesWithResults;
    if (categories.isEmpty) {
      _shownCategory = null;
    } else if (!_categoryPickedByUser || !categories.contains(_shownCategory)) {
      _shownCategory = categories.first;
    }
  }

  String _categoryLabel(_SearchCategory category) {
    switch (category) {
      case _SearchCategory.songs:
        return context.l10n!.songs;
      case _SearchCategory.albums:
        return context.l10n!.albums;
      case _SearchCategory.playlists:
        return context.l10n!.playlists;
      case _SearchCategory.artists:
        return context.l10n!.artists;
      case _SearchCategory.radioStations:
        return context.l10n!.radioStations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.search)),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: <Widget>[
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final bar = ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 600 : double.infinity,
                  ),
                  child: CustomSearchBar(
                    loadingProgressNotifier: _fetchingSongs,
                    controller: _searchBar,
                    focusNode: _inputNode,
                    labelText: '${context.l10n!.search}...',
                    onChanged: (value) {
                      // debounce suggestions to avoid rapid API calls
                      _debounce?.cancel();
                      final query = value;
                      final requestId = ++_latestSuggestionRequest;

                      // An emptied field goes back to the search history, and
                      // the history only shows while nothing has been found
                      // yet. Dropping the suggestions is not enough: the
                      // results of the last search have to go with them.
                      if (query.isEmpty) {
                        unawaited(search());
                        return;
                      }

                      _debounce = Timer(
                        const Duration(milliseconds: 300),
                        () async {
                          final searchSuggestions = await getSearchSuggestions(
                            query,
                          );

                          if (!mounted ||
                              requestId != _latestSuggestionRequest ||
                              _searchBar.text != query) {
                            return;
                          }

                          _suggestionsList = List<String>.from(
                            searchSuggestions,
                          );
                          if (mounted) setState(() {});
                        },
                      );
                    },
                    onSubmitted: (String value) {
                      _submitSearch();
                    },
                  ),
                );
                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [bar],
                  );
                } else {
                  return bar;
                }
              },
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  (_suggestionsList.isNotEmpty ||
                      (_songsSearchResult.isEmpty &&
                          _artistsSearchResult.isEmpty &&
                          _albumsSearchResult.isEmpty &&
                          _playlistsSearchResult.isEmpty &&
                          _radioStationsSearchResult.isEmpty))
                  ? ValueListenableBuilder<List>(
                      valueListenable: searchHistoryNotifier,
                      builder: (context, searchHistory, _) {
                        final items = _suggestionsList.isEmpty
                            ? searchHistory
                            : _suggestionsList;

                        return Column(
                          key: ValueKey(
                            'history-${_suggestionsList.length}-${_searchBar.text}-${searchHistory.length}',
                          ),
                          children: [
                            for (int index = 0; index < items.length; index++)
                              Builder(
                                builder: (context) {
                                  final query = items[index];
                                  final borderRadius = getItemBorderRadius(
                                    index,
                                    items.length,
                                  );

                                  return CustomBar(
                                    query,
                                    FluentIcons.search_24_regular,
                                    borderRadius: borderRadius,
                                    onTap: () async {
                                      await _submitSearch(query.toString());
                                    },
                                    onLongPress: () async {
                                      final confirm =
                                          await _showConfirmationDialog(
                                            context,
                                          ) ??
                                          false;
                                      if (confirm &&
                                          searchHistory.contains(query)) {
                                        final updatedHistory = List.from(
                                          searchHistory,
                                        )..remove(query);
                                        searchHistoryNotifier.value =
                                            updatedHistory;
                                        unawaited(
                                          addOrUpdateData<List>(
                                            'user',
                                            'searchHistory',
                                            updatedHistory,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    )
                  : _buildSearchResults(context),
            ),
            const MiniPlayerBottomSpace(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final categories = _categoriesWithResults;
    if (categories.isEmpty) return const SizedBox.shrink();

    final shownCategory = _shownCategory ?? categories.first;

    return Column(
      key: ValueKey('results-${shownCategory.name}'),
      children: [
        if (categories.length > 1) ...[
          const SizedBox(height: 12),
          SortChips<_SearchCategory>(
            currentSortType: shownCategory,
            sortTypes: categories,
            sortTypeToString: _categoryLabel,
            onSelected: (category) {
              setState(() {
                _shownCategory = category;
                _categoryPickedByUser = true;
              });
              // A tab is only a shortcut if it lands on its first result.
              if (_scrollController.hasClients) _scrollController.jumpTo(0);
            },
          ),
          const SizedBox(height: 12),
        ],
        ..._buildCategoryItems(shownCategory),
      ],
    );
  }

  List<Widget> _buildCategoryItems(_SearchCategory category) {
    switch (category) {
      case _SearchCategory.songs:
        return _buildSongItems();
      case _SearchCategory.albums:
        return _buildPlaylistItems(
          _albumsSearchResult,
          keyPrefix: 'search_album',
          cubeIcon: FluentIcons.cd_16_filled,
          isAlbum: true,
        );
      case _SearchCategory.playlists:
        return _buildPlaylistItems(
          _playlistsSearchResult,
          keyPrefix: 'search_playlist',
          cubeIcon: FluentIcons.apps_list_24_filled,
        );
      case _SearchCategory.artists:
        return _buildArtistItems();
      case _SearchCategory.radioStations:
        return _buildRadioStationItems();
    }
  }

  EdgeInsets _itemPadding(int index, int count) =>
      index == count - 1 ? commonListViewBottomPadding : EdgeInsets.zero;

  List<Widget> _buildSongItems() {
    final songs = _songsSearchResult.take(maxSongsInList).toList();

    return [
      for (var index = 0; index < songs.length; index++)
        Padding(
          padding: _itemPadding(index, songs.length),
          child: SongBar(
            songs[index],
            true,
            key: listItemKey('search_song', index, songs[index]),
            showMusicDuration: true,
            borderRadius: getItemBorderRadius(index, songs.length),
          ),
        ),
    ];
  }

  List<Widget> _buildPlaylistItems(
    List<dynamic> results, {
    required String keyPrefix,
    required IconData cubeIcon,
    bool isAlbum = false,
  }) {
    final playlists = results.take(maxSongsInList).toList();

    return [
      for (var index = 0; index < playlists.length; index++)
        Padding(
          padding: _itemPadding(index, playlists.length),
          child: PlaylistBar(
            key: listItemKey(keyPrefix, index, playlists[index]),
            playlists[index]['title'],
            playlistId: playlists[index]['ytid'],
            playlistArtwork: playlists[index]['image'],
            cubeIcon: cubeIcon,
            isAlbum: isAlbum,
            borderRadius: getItemBorderRadius(index, playlists.length),
          ),
        ),
    ];
  }

  List<Widget> _buildArtistItems() {
    // Artists without an id cannot be opened, so they are dropped before the
    // list is laid out, otherwise they would punch holes in the rounding.
    final artists = _artistsSearchResult
        .take(maxSongsInList)
        .map(Map<String, dynamic>.from)
        .where((artist) => _artistId(artist).isNotEmpty)
        .toList();

    return [
      for (var index = 0; index < artists.length; index++)
        Padding(
          padding: _itemPadding(index, artists.length),
          child: ArtistBar(
            key: listItemKey('search_artist', index, artists[index]),
            artist: artists[index],
            borderRadius: getItemBorderRadius(index, artists.length),
            onTap: () {
              context.push(
                '${NavigationManager.searchPath}/artist/${Uri.encodeComponent(_artistId(artists[index]))}',
                extra: artists[index],
              );
            },
          ),
        ),
    ];
  }

  String _artistId(Map<String, dynamic> artist) =>
      artist['ytid']?.toString() ?? artist['title']?.toString() ?? '';

  List<Widget> _buildRadioStationItems() {
    final stations = _radioStationsSearchResult.take(maxSongsInList).toList();

    return [
      for (var index = 0; index < stations.length; index++)
        Padding(
          padding: _itemPadding(index, stations.length),
          child: RadioStationCard(
            key: listItemKey('search_radio_station', index, stations[index]),
            station: stations[index],
            onPressed: () async {
              final station = stations[index];
              final success = await audioHandler.playRadioStream(
                id: station.id,
                name: station.name,
                streamUrl: station.streamUrl,
                image: station.image,
                genre: station.genre,
              );
              if (!success && context.mounted) {
                showToast(context, context.l10n!.failedPlayingRadio);
              }
            },
          ),
        ),
    ];
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          confirmationMessage: context.l10n!.removeSearchQueryQuestion,
          submitMessage: context.l10n!.confirm,
          onCancel: () {
            Navigator.of(context).pop(false);
          },
          onSubmit: () {
            Navigator.of(context).pop(true);
          },
        );
      },
    );
  }
}
