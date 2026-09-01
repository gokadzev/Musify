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
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/artist_service.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/playlist_download_service.dart';
import 'package:musify/services/playlist_sharing.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/playlist_utils.dart';
import 'package:musify/utilities/song_filtering.dart';
import 'package:musify/utilities/sort_utils.dart';
import 'package:musify/widgets/edit_playlist_dialog.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/playlist_hero_artwork.dart';
import 'package:musify/widgets/playlist_page/add_to_playlist_button.dart';
import 'package:musify/widgets/playlist_page/download_button.dart';
import 'package:musify/widgets/playlist_page/empty_playlist_state.dart';
import 'package:musify/widgets/playlist_page/like_button.dart';
import 'package:musify/widgets/playlist_page/playlist_action_buttons.dart';
import 'package:musify/widgets/playlist_page/playlist_header.dart';
import 'package:musify/widgets/playlist_page/search_bar_section.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/sort_chips.dart';
import 'package:musify/widgets/spinner.dart';

enum PlaylistSortType { default_, title, artist, dateAdded }

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({
    super.key,
    this.playlistId,
    this.playlistData,
    this.cubeIcon = FluentIcons.text_bullet_list_24_filled,
    this.isArtist = false,
  });

  final String? playlistId;
  final dynamic playlistData;
  final IconData cubeIcon;
  final bool isArtist;

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  dynamic _playlist;
  late List<dynamic> _originalPlaylistList; // Keep original order separately

  bool _isInitializingPlaylist = true;

  String? get _resolvedPlaylistId =>
      _playlist?['ytid']?.toString() ??
      widget.playlistData?['ytid']?.toString() ??
      widget.playlistId;

  // Sorting
  late PlaylistSortType _sortType = PlaylistSortType.values.firstWhere(
    (e) => e.name == playlistSortSetting,
    orElse: () => PlaylistSortType.default_,
  );

  // Search
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  List _getSourceList(String searchQuery) {
    final list = _playlist?['list'] as List? ?? [];
    return filterSongsByQuery(list, searchQuery);
  }

  bool get _isArtistCatalogFailed =>
      widget.isArtist && _playlist?['catalogStatus'] == 'failed';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _initializePlaylist();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializePlaylist() async {
    try {
      final initialPlaylist = widget.playlistData;
      final resolvedId =
          initialPlaylist?['ytid']?.toString() ?? widget.playlistId;

      if (initialPlaylist != null) {
        _playlist = initialPlaylist;
        final playlistList = _playlist?['list'] as List?;
        final shouldFetchInitialPlaylist =
            playlistList == null || (!widget.isArtist && playlistList.isEmpty);
        if (shouldFetchInitialPlaylist && resolvedId != null) {
          _playlist =
              await getPlaylistInfoForWidget(
                resolvedId,
                isArtist: widget.isArtist,
                artistName: initialPlaylist?['title']?.toString(),
                artistImage: initialPlaylist?['image']?.toString(),
                sourceSongId: initialPlaylist?['sourceSongId']?.toString(),
                sourceVideoAuthor: initialPlaylist?['videoAuthor']?.toString(),
                preferredVerified: initialPlaylist?['isVerifiedArtist'] == true,
              ) ??
              initialPlaylist;
        }
      } else {
        _playlist = await getPlaylistInfoForWidget(
          resolvedId,
          isArtist: widget.isArtist,
          artistName: initialPlaylist?['title']?.toString(),
          artistImage: initialPlaylist?['image']?.toString(),
          sourceSongId: initialPlaylist?['sourceSongId']?.toString(),
          sourceVideoAuthor: initialPlaylist?['videoAuthor']?.toString(),
          preferredVerified: initialPlaylist?['isVerifiedArtist'] == true,
        );
      }

      if (_playlist != null && _playlist['list'] != null) {
        _adoptPlaylist(_playlist);
        _sortPlaylist(_sortType);
      }
    } catch (e, stackTrace) {
      logger.log(
        'Error initializing playlist:',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        showToast(context, context.l10n!.error);
      }
    } finally {
      _isInitializingPlaylist = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPlaylist = !_isInitializingPlaylist && _playlist != null;
    return Scaffold(
      appBar: showPlaylist ? null : _buildAppBar(context),
      body: Padding(
        padding: commonSingleChildScrollViewPadding,
        child: _isInitializingPlaylist
            ? SizedBox(
                height: MediaQuery.sizeOf(context).height - 100,
                child: const Spinner(),
              )
            : _playlist != null
            ? CustomScrollView(
                slivers: [
                  SliverAppBar(
                    leading: _buildBackButton(context),
                    pinned: true,
                    expandedHeight:
                        MediaQuery.sizeOf(context).width >
                            MediaQuery.sizeOf(context).height
                        ? 380
                        : 320,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      expandedTitleScale: 1.35,
                      titlePadding: const EdgeInsetsDirectional.only(
                        start: 64,
                        end: 64,
                        bottom: 16,
                      ),
                      title: Text(
                        _playlistTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      background: Padding(
                        padding: const EdgeInsets.only(top: 56, bottom: 64),
                        child: Center(child: _buildPlaylistHeroArtwork()),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildHeaderSection()),
                  if ((_playlist['list'] as List? ?? const []).isNotEmpty) ...[
                    ValueListenableBuilder<String>(
                      valueListenable: _searchQueryNotifier,
                      builder: (context, searchQuery, _) {
                        final sourceList = _getSourceList(searchQuery);
                        return SliverPadding(
                          padding: commonListViewBottomPadding,
                          sliver: SliverList.builder(
                            itemCount: sourceList.length,
                            itemBuilder: (context, index) {
                              final isRemovable =
                                  _playlist['source'] == 'user-created';
                              return _buildSongListItem(
                                sourceList[index],
                                index,
                                isRemovable,
                                sourceList,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ] else if (_isArtistCatalogFailed)
                    EmptyPlaylistState(message: context.l10n!.error)
                  else
                    EmptyPlaylistState(
                      message: context.l10n!.noSongsInPlaylist,
                    ),
                  const SliverMiniPlayerBottomSpace(),
                ],
              )
            : EmptyPlaylistState(message: context.l10n!.error),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(leading: _buildBackButton(context));
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(FluentIcons.arrow_left_24_regular),
      onPressed: () => Navigator.pop(context, widget.playlistData == _playlist),
      tooltip: context.l10n!.back,
    );
  }

  String get _playlistTitle => widget.isArtist
      ? normalizeArtistDisplayTitle(_playlist['title']?.toString() ?? '')
      : _playlist['title']?.toString() ?? '';

  Widget _buildPlaylistHeroArtwork() {
    return PlaylistHeroArtwork(
      _playlist,
      cubeIcon: widget.cubeIcon,
      isArtist: widget.isArtist,
    );
  }

  Widget _buildHeaderSection() {
    final songsLength = (_playlist['list'] as List? ?? const []).length;
    final isUserCreated = _playlist['source'] == 'user-created';
    final hasSecondaryActions =
        (widget.playlistId != null && !isUserCreated && !offlineMode.value) ||
        !offlineMode.value ||
        isUserCreated;

    return Column(
      children: [
        PlaylistHeader(
          title: _playlistTitle,
          songsLength: songsLength,
          isAlbum: _playlist['isAlbum'] == true,
          isArtist: widget.isArtist,
          showTitle: false,
        ),
        if (songsLength > 0)
          PlaylistActionButtons(
            onPlay: () => audioHandler.playPlaylistSong(
              playlist: _playlist,
              songIndex: 0,
            ),
            onShuffle: () async {
              final songs = _playlist['list'] as List? ?? [];
              if (songs.isEmpty) return;
              await audioHandler.addPlaylistToQueue(
                List<Map>.from(songs.whereType<Map>())..shuffle(),
                replace: true,
                startIndex: 0,
              );
            },
          ),
        if (hasSecondaryActions) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
              if (widget.playlistId != null &&
                  !isUserCreated &&
                  !offlineMode.value)
                PlaylistLikeButton(
                  playlistId: _resolvedPlaylistId ?? '',
                  playlistData: () => _playlist,
                ),
              if (!offlineMode.value) ...[
                PlaylistAddToPlaylistButton(
                  resolvePlaylist: () async => _playlist,
                ),
                if (!isUserCreated) _buildSyncButton(),
              ],
              if (songsLength > 0) _buildDownloadButton(),
              if (isUserCreated) ...[_buildShareButton(), _buildEditButton()],
            ],
          ),
        ],
        if (songsLength > 1) ...[
          const SizedBox(height: 12),
          SortChips<PlaylistSortType>(
            currentSortType: _sortType,
            sortTypes: PlaylistSortType.values,
            sortTypeToString: _getSortTypeDisplayText,
            onSelected: (type) {
              setState(() {
                _sortType = type;
                addOrUpdateData<String>(
                  'settings',
                  'playlistSortType',
                  type.name,
                );
                playlistSortSetting = type.name;
                _sortPlaylist(type);
              });
            },
          ),
        ],
        if (songsLength > 0) ...[
          const SizedBox(height: 16),
          SearchBarSection(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onSearchChanged: (value) => _searchQueryNotifier.value = value,
            labelText: context.l10n!.search,
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShareButton() {
    return IconButton.filledTonal(
      icon: const Icon(FluentIcons.share_24_regular),
      iconSize: 24,
      onPressed: () async {
        try {
          final encodedPlaylist = PlaylistSharingService.encodePlaylist(
            _playlist,
          );
          final url = 'musify://playlist/custom/$encodedPlaylist';
          await Clipboard.setData(ClipboardData(text: url));
          if (mounted) {
            showToast(context, context.l10n!.linkCopied);
          }
        } catch (e, stackTrace) {
          logger.log(
            'Error sharing playlist',
            error: e,
            stackTrace: stackTrace,
          );
          if (mounted) {
            showToast(context, context.l10n!.error);
          }
        }
      },
      tooltip: context.l10n!.share,
    );
  }

  Widget _buildSyncButton() {
    return IconButton.filledTonal(
      icon: const Icon(FluentIcons.arrow_sync_24_filled),
      iconSize: 24,
      onPressed: _handleSyncPlaylist,
      tooltip: context.l10n!.update,
    );
  }

  Widget _buildEditButton() {
    return IconButton.filledTonal(
      icon: const Icon(FluentIcons.edit_24_filled),
      iconSize: 24,
      onPressed: () async {
        final result = await showDialog<Map?>(
          context: context,
          builder: (context) => EditPlaylistDialog(playlistData: _playlist),
        );

        if (result != null) {
          final resolvedPlaylistYtid =
              _playlist['ytid']?.toString() ?? widget.playlistId;
          if (resolvedPlaylistYtid == null ||
              resolvedPlaylistYtid.isEmpty ||
              resolvedPlaylistYtid == 'null') {
            showToast(context, context.l10n!.error);
            return;
          }

          final updatedPlaylist = {
            ..._playlist,
            ...result,
            'ytid': resolvedPlaylistYtid,
            'source': _playlist['source'] ?? result['source'],
            'list': result['list'] ?? _playlist['list'],
          };

          // Search root list first, then inside folders.
          final rootIndex = userCustomPlaylists.value.indexWhere(
            (p) => p['ytid'] == resolvedPlaylistYtid,
          );

          if (rootIndex != -1) {
            final updatedPlaylists = List<Map>.from(userCustomPlaylists.value);
            updatedPlaylists[rootIndex] = updatedPlaylist;
            userCustomPlaylists.value = updatedPlaylists;
            unawaited(
              addOrUpdateData<List>(
                'user',
                'customPlaylists',
                userCustomPlaylists.value,
              ),
            );
          } else {
            // Playlist lives inside a folder - update it there.
            final updatedFolders = List<Map>.from(userPlaylistFolders.value);
            for (final folder in updatedFolders) {
              final folderPlaylists = List<Map>.from(
                folder['playlists'] as List? ?? [],
              );
              final fi = folderPlaylists.indexWhere(
                (p) => p['ytid'] == resolvedPlaylistYtid,
              );
              if (fi != -1) {
                folderPlaylists[fi] = updatedPlaylist;
                folder['playlists'] = folderPlaylists;
                break;
              }
            }
            userPlaylistFolders.value = updatedFolders;
            unawaited(
              addOrUpdateData<List>(
                'user',
                'playlistFolders',
                userPlaylistFolders.value,
              ),
            );
          }

          // Update offline playlist if it exists
          unawaited(syncOfflinePlaylistMetadata(updatedPlaylist));

          setState(() {
            _adoptPlaylist(updatedPlaylist);
            _sortPlaylist(_sortType);
          });
          showToast(context, context.l10n!.playlistUpdated);
        }
      },
      tooltip: context.l10n!.editPlaylist,
    );
  }

  Widget _buildDownloadButton() {
    final playlistId = _playlist?['ytid']?.toString() ?? widget.playlistId;
    if (playlistId == null || playlistId.isEmpty) {
      return const SizedBox.shrink();
    }

    return PlaylistDownloadButton(
      playlistId: playlistId,
      songs: _playlist?['list'] as List? ?? const [],
      resolvePlaylist: () async => _playlist,
    );
  }

  void _handleSyncPlaylist() async {
    final playlistId = _playlist?['ytid']?.toString();
    if (playlistId == null || playlistId.isEmpty) return;

    if (offlineMode.value &&
        offlinePlaylistService.isPlaylistDownloaded(playlistId)) {
      if (mounted) {
        showToast(context, context.l10n!.removeOffline);
      }
      return;
    }

    // Artists/releases aren't built-in playlists; refresh by dropping their cache entry.
    final isCachedPage = widget.isArtist || playlistId.startsWith('MPRE');
    final updated = widget.isArtist
        ? await getPlaylistInfoForWidget(
            playlistId,
            isArtist: true,
            artistName: _playlist?['title']?.toString(),
            artistImage: _playlist?['image']?.toString(),
            preferredVerified: _playlist?['isVerifiedArtist'] == true,
            forceRefresh: true,
          )
        : isCachedPage
        ? await getPlaylistInfoForWidget(playlistId, forceRefresh: true)
        : await updatePlaylistList(context, playlistId);
    if (updated?['catalogStatus'] == 'failed') {
      if (mounted) showToast(context, context.l10n!.error);
      return;
    }
    if (updated != null && mounted) {
      setState(() {
        _adoptPlaylist(updated);
        _sortPlaylist(_sortType);
      });
      if (isCachedPage) {
        showToast(context, context.l10n!.playlistUpdated);
      }
    }
  }

  void _updateSongsListOnRemove(int indexOfRemovedSong, dynamic songToRemove) {
    _originalPlaylistList.removeWhere((s) => s['ytid'] == songToRemove['ytid']);
    final playlistId = _playlist['ytid'];
    if (mounted) {
      setState(() {});
      showToastWithButton(
        context,
        context.l10n!.songRemoved,
        context.l10n!.undo.toUpperCase(),
        () {
          final result = addSongInCustomPlaylist(
            context,
            playlistId,
            songToRemove,
            indexToInsert: indexOfRemovedSong,
          );
          if (result == context.l10n!.songAdded &&
              !_originalPlaylistList.any(
                (song) => song['ytid'] == songToRemove['ytid'],
              )) {
            final safeIndex = indexOfRemovedSong.clamp(
              0,
              _originalPlaylistList.length,
            );
            _originalPlaylistList.insert(safeIndex, songToRemove);
            _sortPlaylist(_sortType);
          }
          if (mounted) setState(() {});
        },
      );
    } else {
      logger.log(
        '(_updateSongsListOnRemove): Widget not mounted, cannot show undo toast.',
      );
    }
  }

  String _getSortTypeDisplayText(PlaylistSortType type) {
    switch (type) {
      case PlaylistSortType.default_:
        return context.l10n!.default_;
      case PlaylistSortType.title:
        return context.l10n!.name;
      case PlaylistSortType.artist:
        return context.l10n!.artist;
      case PlaylistSortType.dateAdded:
        return context.l10n!.dateAdded;
    }
  }

  /// Copy source and snapshot its original item order.
  /// Prevents sorting changes from affecting shared cached playlist data.
  void _adoptPlaylist(dynamic source) {
    if (source is! Map) {
      _playlist = source;
      _originalPlaylistList = <dynamic>[];
      return;
    }
    _playlist = Map<String, dynamic>.from(source);
    final list = source['list'];
    _originalPlaylistList = list is List
        ? List<dynamic>.from(list)
        : <dynamic>[];
  }

  void _sortPlaylist(PlaylistSortType type) {
    if (_playlist == null || _playlist['list'] == null) return;

    switch (type) {
      case PlaylistSortType.default_:
        // Restore original order from backup
        _playlist['list'] = List<dynamic>.from(_originalPlaylistList);
        break;
      case PlaylistSortType.title:
        final playlist = List<dynamic>.from(_playlist['list']);
        sortSongsByKey(playlist, 'title');
        _playlist['list'] = playlist;
        break;
      case PlaylistSortType.artist:
        final playlist = List<dynamic>.from(_playlist['list']);
        sortSongsByKey(playlist, 'artist');
        _playlist['list'] = playlist;
        break;
      case PlaylistSortType.dateAdded:
        _playlist['list'] = List<dynamic>.from(_originalPlaylistList.reversed);
        break;
    }
  }

  Widget _buildSongListItem(
    Map song,
    int index,
    bool isRemovable,
    List sourceList,
  ) {
    final totalItems = sourceList.length;
    final borderRadius = getItemBorderRadius(index, totalItems);
    final isUserCreatedPlaylist = _playlist?['source'] == 'user-created';
    final playlistId = isUserCreatedPlaylist ? _playlist!['ytid'] : null;
    final isSearching = _searchQueryNotifier.value.isNotEmpty;
    final fullIndex = isSearching
        ? PlaylistUtils.findSongIndexByYtid(_playlist, song['ytid'])
        : index;

    if (isSearching && fullIndex == -1) {
      logger.log('Warning: Song ${song['ytid']} not found in full playlist');
    }

    return SongBar(
      song,
      true,
      key: listItemKey('playlist_song', index, song),
      onRemove: (isRemovable && !isSearching)
          ? () {
              if (removeSongFromPlaylist(
                _playlist,
                song,
                removeOneAtIndex: index,
              )) {
                _updateSongsListOnRemove(index, song);
              }
            }
          : null,
      onPlay: () {
        audioHandler.playPlaylistSong(
          playlist: _playlist,
          songIndex: fullIndex != -1 ? fullIndex : index,
        );
      },
      borderRadius: borderRadius,
      playlistId: playlistId,
      onRenamed: () => setState(() {}),
    );
  }
}
