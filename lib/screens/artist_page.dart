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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/services/artist_service.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/async_loader.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/artist_shelf.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/playlist_page/download_button.dart';
import 'package:musify/widgets/playlist_page/empty_playlist_state.dart';
import 'package:musify/widgets/playlist_page/like_button.dart';
import 'package:musify/widgets/playlist_page/playlist_action_buttons.dart';
import 'package:musify/widgets/playlist_page/playlist_header.dart';
import 'package:musify/widgets/section_header.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

/// The page an artist opens on: who the artist is, its top songs, its releases
/// and where to go next. Its song list lives one tap away, in "All songs".
class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key, required this.artistId, this.artistData});

  final String artistId;
  final Map? artistData;

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  late Future<Map<String, dynamic>?> _artistFuture;

  Map<String, dynamic>? _artist;
  List<Map<String, dynamic>> _topSongs = const [];
  List<String?> _topSongPlayCounts = const [];
  List<Map<String, dynamic>> _albums = const [];
  List<Map<String, dynamic>> _singles = const [];
  List<Map<String, dynamic>> _relatedArtists = const [];

  /// Whether the songs of the artist are being read for the play buttons.
  final _isLoadingCatalog = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // This page is the online layer: offline the artist collapses to the songs
    // of it that were downloaded, so there is nothing to load.
    _artistFuture = offlineMode.value ? Future.value() : _loadArtist();
  }

  @override
  void didUpdateWidget(covariant ArtistPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only the id says which artist this is. What came with the navigation is
    // a fresh copy of the same seed on every rebuild of the route, and a Map
    // compares by identity, so reading it here would reload the page — and
    // flash the loader over it — every time a page is pushed on top of it.
    if (oldWidget.artistId != widget.artistId) {
      _artistFuture = offlineMode.value ? Future.value() : _loadArtist();
    }
  }

  @override
  void dispose() {
    _isLoadingCatalog.dispose();
    super.dispose();
  }

  String get _resolvedArtistId =>
      _artist?['ytid']?.toString() ?? widget.artistId;

  String get _artistTitle =>
      _artist?['title']?.toString() ??
      widget.artistData?['title']?.toString() ??
      '';

  Future<Map<String, dynamic>?> _loadArtist({bool forceRefresh = false}) async {
    final artistData = widget.artistData;
    final artist = await getArtistProfile(
      widget.artistId,
      forceRefresh: forceRefresh,
      preferredName: artistData?['title']?.toString(),
      preferredImage: artistData?['image']?.toString(),
      sourceSongId: artistData?['sourceSongId']?.toString(),
      sourceVideoAuthor: artistData?['videoAuthor']?.toString(),
      preferredVerified: artistData?['isVerifiedArtist'] == true,
    );
    if (artist == null) return null;

    _artist = artist;
    // Each entry of the shelf is a song and its play count, side by side.
    final topSongs = asMapList(
      artist['topSongs'],
    ).where((entry) => entry['song'] is Map).toList();
    _topSongs = [
      for (final entry in topSongs)
        Map<String, dynamic>.from(entry['song'] as Map),
    ];
    _topSongPlayCounts = [
      for (final entry in topSongs) entry['playCount']?.toString(),
    ];
    _relatedArtists = asMapList(artist['relatedArtists']);
    // Split the discography once per load: the two shelves are rebuilt on every
    // frame and would otherwise filter it again each time.
    final releases = asMapList(artist['releases']);
    _albums = releases.where((r) => !isSingleOrEpRelease(r)).toList();
    _singles = releases.where(isSingleOrEpRelease).toList();
    return artist;
  }

  @override
  Widget build(BuildContext context) {
    if (offlineMode.value) return _buildAllSongsPage();

    return AsyncLoader<Map<String, dynamic>?>(
      future: _artistFuture,
      loadingWidget: Scaffold(appBar: AppBar(), body: const Spinner()),
      emptyWidget: _buildNotFoundPage(),
      builder: (context, _) => Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          padding: commonSingleChildScrollViewPadding,
          child: Column(
            children: [
              _buildHeaderSection(),
              _buildTopSongsSection(),
              ArtistShelf(
                title: context.l10n!.albums,
                icon: FluentIcons.cd_16_regular,
                items: _albums,
                subtitleOf: _releaseSubtitle,
                onTap: _openRelease,
              ),
              ArtistShelf(
                title: context.l10n!.singlesAndEps,
                icon: FluentIcons.music_note_2_24_regular,
                items: _singles,
                subtitleOf: _releaseSubtitle,
                onTap: _openRelease,
              ),
              // Everything of the artist first, then where to go next.
              _buildAllSongsButton(),
              ArtistShelf(
                title: context.l10n!.suggestedArtists,
                icon: FluentIcons.person_24_regular,
                items: _relatedArtists,
                cubeIcon: FluentIcons.person_24_filled,
                circular: true,
                onTap: _openArtist,
              ),
              const SizedBox(height: 16),
              const MiniPlayerBottomSpace(),
            ],
          ),
        ),
      ),
    );
  }

  /// The artist as its song list, which offline is the whole page.
  Widget _buildAllSongsPage() {
    return PlaylistPage(
      playlistId: widget.artistId,
      playlistData: artistPlaylistData({
        'ytid': widget.artistId,
        'title': widget.artistData?['title'],
        'image': widget.artistData?['image'],
      }),
      cubeIcon: FluentIcons.person_24_filled,
      isArtist: true,
    );
  }

  Widget _buildNotFoundPage() {
    return Scaffold(
      appBar: AppBar(),
      body: CustomScrollView(
        slivers: [
          // Not finding an artist is an answer, not a failure of the app.
          EmptyPlaylistState(
            icon: FluentIcons.person_24_filled,
            message: context.l10n!.artistNotFound,
          ),
          const SliverMiniPlayerBottomSpace(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final screenSize = MediaQuery.sizeOf(context);
    final isLandscape = screenSize.width > screenSize.height;

    return Column(
      children: [
        PlaylistHeader(
          PlaylistCube(
            _artist!,
            size: isLandscape
                ? 250
                : screenSize.width / commonPlaylistArtworkDivision,
            cubeIcon: FluentIcons.person_24_filled,
            showTypeLabel: false,
          ),
          _artistTitle,
          isArtist: true,
          monthlyListeners: _artist!['monthlyListeners']?.toString(),
          description: _artist!['description']?.toString(),
        ),
        _buildPlaybackButtons(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
            PlaylistLikeButton(
              playlistId: _resolvedArtistId,
              playlistData: () => artistPlaylistData(_artist!, songs: const []),
            ),
            // Downloading an artist downloads its songs, which is exactly what
            // the "All songs" playlist holds.
            PlaylistDownloadButton(
              playlistId: _resolvedArtistId,
              resolvePlaylist: _loadCatalog,
            ),
            IconButton.filledTonal(
              icon: const Icon(FluentIcons.arrow_sync_24_filled),
              iconSize: 24,
              onPressed: () => setState(() {
                _artistFuture = _loadArtist(forceRefresh: true);
              }),
              tooltip: context.l10n!.update,
            ),
          ],
        ),
      ],
    );
  }

  /// Playing the artist plays every song of it, the same list "All songs"
  /// holds, so pressing play here also fills that page and the other way
  /// around.
  Widget _buildPlaybackButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingCatalog,
      builder: (_, isLoading, __) => PlaylistActionButtons(
        isLoading: isLoading,
        onPlay: _playArtist,
        onShuffle: () => _playArtist(shuffle: true),
      ),
    );
  }

  Widget _buildTopSongsSection() {
    if (_topSongs.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.topSongs,
          icon: FluentIcons.music_note_2_24_filled,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: commonListViewBottomPadding,
          itemCount: _topSongs.length,
          itemBuilder: (context, index) => RepaintBoundary(
            key: listItemKey('artist_top_song', index, _topSongs[index]),
            child: SongBar(
              _topSongs[index],
              true,
              rank: index + 1,
              playCount: _topSongPlayCounts[index],
              borderRadius: getItemBorderRadius(index, _topSongs.length),
              onPlay: () => audioHandler.playPlaylistSong(
                playlist: {'title': _artistTitle, 'list': _topSongs},
                songIndex: index,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllSongsButton() {
    return Padding(
      // Lined up with the play and shuffle buttons of the header.
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          icon: const Icon(FluentIcons.arrow_right_24_regular),
          iconAlignment: IconAlignment.end,
          label: Text(context.l10n!.allSongs),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => context.push(
            NavigationManager.artistSongsPath(context, _resolvedArtistId),
            extra: artistPlaylistData(_artist!),
          ),
        ),
      ),
    );
  }

  String _releaseSubtitle(Map<String, dynamic> release) {
    final year = release['year']?.toString();
    final type = switch (release['releaseType']?.toString()) {
      'single' => context.l10n!.single,
      'ep' => 'EP',
      _ => context.l10n!.album,
    };
    return year == null || year.isEmpty ? type : '$type • $year';
  }

  /// Every song of the artist, read through the same call the "All songs" page
  /// makes: both show the same songs, the downloaded ones when the artist was
  /// downloaded, and the catalog is only walked once for the two of them.
  Future<Map?> _loadCatalog() => getPlaylistInfoForWidget(
    _resolvedArtistId,
    isArtist: true,
    artistName: _artistTitle,
    artistImage: _artist?['image']?.toString(),
    preferredVerified: true,
  );

  Future<void> _playArtist({bool shuffle = false}) async {
    _isLoadingCatalog.value = true;
    final catalog = await _loadCatalog();
    if (!mounted) return;
    _isLoadingCatalog.value = false;

    final songs = catalog?['list'] as List? ?? const [];
    if (songs.isEmpty) {
      showToast(context, context.l10n!.error);
      return;
    }

    if (shuffle) {
      await audioHandler.addPlaylistToQueue(
        List<Map>.from(songs.whereType<Map>())..shuffle(),
        replace: true,
        startIndex: 0,
      );
    } else {
      await audioHandler.playPlaylistSong(playlist: catalog, songIndex: 0);
    }
  }

  void _openArtist(Map<String, dynamic> artist) {
    final artistId = artist['ytid']?.toString();
    if (artistId == null || artistId.isEmpty) return;

    context.push(
      NavigationManager.artistPath(context, artistId),
      extra: artist,
    );
  }

  void _openRelease(Map<String, dynamic> release) {
    final releaseId = release['ytid']?.toString();
    if (releaseId == null || releaseId.isEmpty) return;

    context.push(
      NavigationManager.albumPath(context, releaseId),
      extra: release,
    );
  }
}
