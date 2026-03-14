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
import 'package:flutter/services.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/playlist_download_service.dart';
import 'package:musify/services/playlist_sharing.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/offline_playlist_dialogs.dart';
import 'package:musify/utilities/playlist_dialogs.dart';
import 'package:musify/utilities/sort_utils.dart';
import 'package:musify/widgets/edit_playlist_dialog.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/playlist_page/playlist_header.dart';
import 'package:musify/widgets/playlist_page/playlist_search_bar.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/sort_chips.dart';
import 'package:musify/widgets/spinner.dart';

enum PlaylistSortType { default_, title, artist }

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({
    super.key,
    this.playlistId,
    this.playlistData,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
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
  late final List<dynamic>
  _originalPlaylistList; // Keep original order separately

  late final playlistLikeStatus = ValueNotifier<bool>(
    isPlaylistAlreadyLiked(widget.playlistId),
  );
  bool playlistOfflineStatus = false;

  // Sorting
  late PlaylistSortType _sortType = PlaylistSortType.values.firstWhere(
    (e) => e.name == playlistSortSetting,
    orElse: () => PlaylistSortType.default_,
  );

  // Search
  String _searchQuery = '';

  List<dynamic> get _sourceList {
    final list = _playlist?['list'] as List<dynamic>? ?? [];
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((s) {
      final title = (s['title'] ?? '').toString().toLowerCase();
      final artist = (s['artist'] ?? '').toString().toLowerCase();
      return title.contains(q) || artist.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializePlaylist() async {
    try {
      if (widget.playlistData != null) {
        _playlist = widget.playlistData;
        final playlistList = _playlist?['list'] as List?;
        if (playlistList == null || playlistList.isEmpty) {
          final resolvedId =
              _playlist?['ytid']?.toString() ?? widget.playlistId;
          final fullPlaylist = await getPlaylistInfoForWidget(
            resolvedId,
            isArtist: widget.isArtist,
          );
          if (fullPlaylist != null) {
            _playlist = fullPlaylist;
          }
        }
      } else {
        _playlist = await getPlaylistInfoForWidget(
          widget.playlistId,
          isArtist: widget.isArtist,
        );
      }

      if (_playlist != null && _playlist['list'] != null) {
        _originalPlaylistList = List<dynamic>.from(_playlist['list'] as List);
        _sortPlaylist(_sortType);
        if (mounted) {
          setState(() {});
        }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pop(context, widget.playlistData == _playlist),
        ),
      ),
      body: _playlist != null
          ? CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeaderSection()),
                if ((_playlist['list'] as List).isNotEmpty) ...[
                  SliverPadding(
                    padding: commonListViewBottomPadding,
                    sliver: SliverList.builder(
                      itemCount: _sourceList.length,
                      itemBuilder: (context, index) {
                        final isRemovable =
                            _playlist['source'] == 'user-created';
                        return _buildSongListItem(
                          _sourceList[index],
                          index,
                          isRemovable,
                        );
                      },
                    ),
                  ),
                ] else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.music_note_1_24_regular,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(120),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.l10n!.noSongsInPlaylist,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : SizedBox(
              height: MediaQuery.sizeOf(context).height - 100,
              child: const Spinner(),
            ),
    );
  }

  Widget _buildPlaylistImage() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth > MediaQuery.sizeOf(context).height;
    return PlaylistCube(
      _playlist,
      size: isLandscape ? 250 : screenWidth / commonPlaylistArtworkDivision,
      cubeIcon: widget.cubeIcon,
      showTypeLabel: false,
    );
  }

  Widget _buildHeaderSection() {
    final songsLength = _playlist['list'].length;
    final isUserCreated = _playlist['source'] == 'user-created';
    final colorScheme = Theme.of(context).colorScheme;

    final hasSecondaryActions =
        (widget.playlistId != null && !isUserCreated && !offlineMode.value) ||
        !offlineMode.value ||
        isUserCreated;

    return Column(
      children: [
        PlaylistHeader(
          _buildPlaylistImage(),
          _playlist['title'],
          songsLength,
          isAlbum: _playlist['isAlbum'] == true,
        ),
        if (songsLength > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(FluentIcons.play_24_filled),
                    label: Text(context.l10n!.play),
                    onPressed: () => audioHandler.playPlaylistSong(
                      playlist: _playlist,
                      songIndex: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                    ),
                    icon: const Icon(FluentIcons.arrow_shuffle_24_filled),
                    label: Text(context.l10n!.shuffle),
                    onPressed: () async {
                      final songs = _playlist['list'] as List? ?? [];
                      if (songs.isEmpty) return;
                      final shuffled = List<Map>.from(songs.whereType<Map>())
                        ..shuffle();
                      await audioHandler.addPlaylistToQueue(
                        shuffled,
                        replace: true,
                        startIndex: 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasSecondaryActions) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
              if (widget.playlistId != null &&
                  !isUserCreated &&
                  !offlineMode.value)
                _buildLikeButton(),
              if (!offlineMode.value) ...[
                _buildAddToPlaylistButton(),
                _buildSyncButton(),
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
                addOrUpdateData('settings', 'playlistSortType', type.name);
                playlistSortSetting = type.name;
                _sortPlaylist(type);
              });
            },
          ),
        ],
        if (songsLength > 0) ...[
          const SizedBox(height: 16),
          PlaylistSearchBar(
            query: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
            onCleared: () => setState(() => _searchQuery = ''),
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
        final encodedPlaylist = PlaylistSharingService.encodePlaylist(
          _playlist,
        );
        final url = 'musify://playlist/custom/$encodedPlaylist';
        await Clipboard.setData(ClipboardData(text: url));
      },
    );
  }

  Widget _buildLikeButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: playlistLikeStatus,
      builder: (_, value, __) {
        final icon = value
            ? FluentIcons.heart_24_filled
            : FluentIcons.heart_24_regular;

        return value
            ? IconButton.filled(
                icon: Icon(icon),
                iconSize: 24,
                onPressed: () {
                  playlistLikeStatus.value = !playlistLikeStatus.value;
                  unawaited(
                    updatePlaylistLikeStatus(
                      _playlist['ytid'],
                      playlistLikeStatus.value,
                    ),
                  );
                  currentLikedPlaylistsLength.value =
                      currentLikedPlaylistsLength.value - 1;
                },
              )
            : IconButton.filledTonal(
                icon: Icon(icon),
                iconSize: 24,
                onPressed: () {
                  playlistLikeStatus.value = !playlistLikeStatus.value;
                  unawaited(
                    updatePlaylistLikeStatus(
                      _playlist['ytid'],
                      playlistLikeStatus.value,
                    ),
                  );
                  currentLikedPlaylistsLength.value =
                      currentLikedPlaylistsLength.value + 1;
                },
              );
      },
    );
  }

  Widget _buildSyncButton() {
    return IconButton.filledTonal(
      icon: const Icon(FluentIcons.arrow_sync_24_filled),
      iconSize: 24,
      onPressed: _handleSyncPlaylist,
    );
  }

  Widget _buildAddToPlaylistButton() {
    return IconButton.filledTonal(
      icon: const Icon(FluentIcons.album_add_24_regular),
      iconSize: 24,
      onPressed: _handleAddFullPlaylistToPlaylist,
    );
  }

  void _handleAddFullPlaylistToPlaylist() {
    if (_playlist != null && _playlist['list'] != null) {
      final List<dynamic> tracks = _playlist['list'];
      if (tracks.isEmpty) {
        showToast(context, context.l10n!.noSongsInPlaylist);
        return;
      }
      showAddToPlaylistDialog(context, songs: tracks);
    } else {
      showToast(context, context.l10n!.loading);
    }
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
              addOrUpdateData(
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
              addOrUpdateData(
                'user',
                'playlistFolders',
                userPlaylistFolders.value,
              ),
            );
          }

          setState(() => _playlist = updatedPlaylist);
          showToast(context, context.l10n!.playlistUpdated);
        }
      },
    );
  }

  Widget _buildDownloadButton() {
    final playlistId = widget.playlistId ?? _playlist['title'];

    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: offlinePlaylistService.offlinePlaylists,
      builder: (context, offlinePlaylists, _) {
        playlistOfflineStatus = offlinePlaylistService.isPlaylistDownloaded(
          playlistId,
        );

        if (playlistOfflineStatus) {
          return IconButton.filled(
            icon: Icon(
              FluentIcons.arrow_download_off_24_filled,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            iconSize: 24,
            onPressed: () => _showRemoveOfflineDialog(playlistId),
            tooltip: context.l10n!.removeOffline,
          );
        }

        return ValueListenableBuilder<DownloadProgress>(
          valueListenable: offlinePlaylistService.getProgressNotifier(
            playlistId,
          ),
          builder: (context, progress, _) {
            final isDownloading = offlinePlaylistService.isPlaylistDownloading(
              playlistId,
            );

            if (isDownloading) {
              return SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: progress.progress,
                        strokeWidth: 3,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.dismiss_24_filled, size: 16),
                      onPressed: () => offlinePlaylistService.cancelDownload(
                        context,
                        playlistId,
                      ),
                      tooltip: context.l10n!.cancel,
                    ),
                  ],
                ),
              );
            }

            if (offlineMode.value) {
              return const SizedBox.shrink();
            }

            return IconButton.filledTonal(
              icon: const Icon(FluentIcons.arrow_download_24_filled),
              iconSize: 24,
              onPressed: () =>
                  offlinePlaylistService.downloadPlaylist(context, _playlist),
              tooltip: context.l10n!.downloadPlaylist,
            );
          },
        );
      },
    );
  }

  void _showRemoveOfflineDialog(String playlistId) =>
      showRemoveOfflinePlaylistDialog(context, playlistId);

  void _handleSyncPlaylist() async {
    if (_playlist['ytid'] != null) {
      final updated = await updatePlaylistList(context, _playlist['ytid']);
      if (updated != null && mounted) {
        setState(() {
          _playlist = updated;
          if (_playlist['list'] != null) {
            _originalPlaylistList = List<dynamic>.from(
              _playlist['list'] as List,
            );
          }
        });
      }
    } else {
      final resolvedId = _playlist['ytid']?.toString() ?? widget.playlistId;
      final updatedPlaylist = await getPlaylistInfoForWidget(resolvedId);
      if (updatedPlaylist != null && mounted) {
        setState(() {
          _playlist = updatedPlaylist;
          if (_playlist['list'] != null) {
            _originalPlaylistList = List<dynamic>.from(
              _playlist['list'] as List,
            );
          }
        });
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
          addSongInCustomPlaylist(
            context,
            playlistId,
            songToRemove,
            indexToInsert: indexOfRemovedSong,
          );
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
    }
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
    }
  }

  Widget _buildSongListItem(dynamic song, int index, bool isRemovable) {
    final totalItems = _sourceList.length;
    final borderRadius = getItemBorderRadius(index, totalItems);
    final isUserCreatedPlaylist = _playlist?['source'] == 'user-created';
    final playlistId = isUserCreatedPlaylist ? _playlist!['ytid'] : null;
    final isSearching = _searchQuery.isNotEmpty;
    final playlistForQueue = isSearching
        ? {..._playlist as Map, 'list': _sourceList}
        : _playlist;

    return SongBar(
      song,
      true,
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
          playlist: playlistForQueue,
          songIndex: index,
        );
      },
      borderRadius: borderRadius,
      playlistId: playlistId,
      onRenamed: () => setState(() {}),
    );
  }
}
