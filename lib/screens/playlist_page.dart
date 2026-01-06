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

import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/playlist_download_service.dart';
import 'package:musify/services/playlist_sharing.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/sort_utils.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/edit_playlist_dialog.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/playlist_header.dart';
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

  final int _itemsPerPage = 35;
  late final PagingController<int, dynamic> _pagingController;

  late final playlistLikeStatus = ValueNotifier<bool>(
    isPlaylistAlreadyLiked(widget.playlistId),
  );
  bool playlistOfflineStatus = false;

  // Sorting
  late PlaylistSortType _sortType = PlaylistSortType.values.firstWhere(
    (e) => e.name == playlistSortSetting,
    orElse: () => PlaylistSortType.default_,
  );

  @override
  void initState() {
    super.initState();

    _pagingController = PagingController<int, dynamic>(
      getNextPageKey: (state) {
        if (_playlist == null || _playlist['list'] == null) return null;

        final playlistList = _playlist['list'] as List<dynamic>;
        final totalCount = playlistList.length;
        final currentlyLoaded = state.items?.length ?? 0;

        if (currentlyLoaded >= totalCount) return null;

        return currentlyLoaded;
      },
      fetchPage: _fetchPage,
    );

    _initializePlaylist();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _initializePlaylist() async {
    try {
      if (widget.playlistData != null) {
        _playlist = widget.playlistData;
        final playlistList = _playlist?['list'] as List?;
        if (playlistList == null || playlistList.isEmpty) {
          final fullPlaylist = await getPlaylistInfoForWidget(
            widget.playlistId,
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
      logger.log('Error initializing playlist:', e, stackTrace);
      if (mounted) {
        showToast(context, context.l10n!.error);
      }
    }
  }

  Future<List<dynamic>> _fetchPage(int pageKey) async {
    try {
      if (_playlist == null || _playlist['list'] == null) {
        return [];
      }

      final playlistList = _playlist['list'] as List<dynamic>;
      final totalCount = playlistList.length;
      final startIndex = pageKey;
      final endIndex = min(startIndex + _itemsPerPage, totalCount);

      return playlistList.sublist(startIndex, endIndex);
    } catch (error) {
      rethrow;
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
          ? PagingListener(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeaderSection()),
                  if (_playlist['list'].isNotEmpty) ...[
                    SliverPadding(
                      padding: commonListViewBottomPadding,
                      sliver: PagedSliverList(
                        state: state,
                        fetchNextPage: fetchNextPage,
                        builderDelegate: PagedChildBuilderDelegate<dynamic>(
                          itemBuilder: (context, item, index) {
                            final isRemovable =
                                _playlist['source'] == 'user-created';
                            return _buildSongListItem(item, index, isRemovable);
                          },
                        ),
                      ),
                    ),
                  ] else
                    const SliverFillRemaining(child: SizedBox.expand()),
                ],
              ),
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
      size: isLandscape ? 250 : screenWidth / 2.2,
      cubeIcon: widget.cubeIcon,
    );
  }

  Widget _buildHeaderSection() {
    final songsLength = _playlist['list'].length;
    final isUserCreated = _playlist['source'] == 'user-created';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return Column(
      children: [
        PlaylistHeader(_buildPlaylistImage(), _playlist['title'], songsLength),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (songsLength > 0) _buildPlayButton(primaryColor),
            if (widget.playlistId != null && !isUserCreated)
              _buildLikeButton(primaryColor),
            _buildSyncButton(primaryColor),
            _buildDownloadButton(),
            if (isUserCreated) ...[
              _buildShareButton(primaryColor),
              _buildEditButton(primaryColor),
            ],
          ],
        ),
        if (songsLength > 1) ...[
          const SizedBox(height: 16),
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
              _pagingController.refresh();
            },
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPlayButton(Color primaryColor) {
    return IconButton.filled(
      icon: Icon(
        FluentIcons.play_24_filled,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      iconSize: 24,
      onPressed: () =>
          audioHandler.playPlaylistSong(playlist: _playlist, songIndex: 0),
    );
  }

  Widget _buildShareButton(Color primaryColor) {
    return IconButton.filledTonal(
      icon: Icon(FluentIcons.share_24_regular, color: primaryColor),
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

  Widget _buildLikeButton(Color primaryColor) {
    return ValueListenableBuilder<bool>(
      valueListenable: playlistLikeStatus,
      builder: (_, value, __) {
        final icon = value
            ? FluentIcons.heart_24_filled
            : FluentIcons.heart_24_regular;

        return value
            ? IconButton.filled(
                icon: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                iconSize: 24,
                onPressed: () {
                  playlistLikeStatus.value = !playlistLikeStatus.value;
                  updatePlaylistLikeStatus(
                    _playlist['ytid'],
                    playlistLikeStatus.value,
                  );
                  currentLikedPlaylistsLength.value =
                      currentLikedPlaylistsLength.value - 1;
                },
              )
            : IconButton.filledTonal(
                icon: Icon(icon, color: primaryColor),
                iconSize: 24,
                onPressed: () {
                  playlistLikeStatus.value = !playlistLikeStatus.value;
                  updatePlaylistLikeStatus(
                    _playlist['ytid'],
                    playlistLikeStatus.value,
                  );
                  currentLikedPlaylistsLength.value =
                      currentLikedPlaylistsLength.value + 1;
                },
              );
      },
    );
  }

  Widget _buildSyncButton(Color primaryColor) {
    return IconButton.filledTonal(
      icon: Icon(FluentIcons.arrow_sync_24_filled, color: primaryColor),
      iconSize: 24,
      onPressed: _handleSyncPlaylist,
    );
  }

  Widget _buildEditButton(Color primaryColor) {
    return IconButton.filledTonal(
      icon: Icon(FluentIcons.edit_24_filled, color: primaryColor),
      iconSize: 24,
      onPressed: () async {
        final result = await showDialog<Map?>(
          context: context,
          builder: (context) => EditPlaylistDialog(playlistData: _playlist),
        );

        if (result != null) {
          final index = userCustomPlaylists.value.indexOf(widget.playlistData);
          if (index != -1) {
            final updatedPlaylists = List<Map>.from(userCustomPlaylists.value);
            updatedPlaylists[index] = result;
            userCustomPlaylists.value = updatedPlaylists;
            await addOrUpdateData(
              'user',
              'customPlaylists',
              userCustomPlaylists.value,
            );
            setState(() => _playlist = result);
            showToast(context, context.l10n!.playlistUpdated);
          }
        }
      },
    );
  }

  Widget _buildDownloadButton() {
    final playlistId = widget.playlistId ?? _playlist['title'];
    final primaryColor = Theme.of(context).colorScheme.primary;

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
                        backgroundColor: primaryColor.withValues(alpha: .2),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        FluentIcons.dismiss_24_filled,
                        color: primaryColor,
                        size: 16,
                      ),
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

            return IconButton.filledTonal(
              icon: Icon(
                FluentIcons.arrow_download_24_filled,
                color: primaryColor,
              ),
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

  void _showRemoveOfflineDialog(String playlistId) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: Icon(
            FluentIcons.cloud_off_24_regular,
            color: colorScheme.error,
            size: 32,
          ),
          title: Text(
            context.l10n!.removeOfflinePlaylist,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            context.l10n!.removeOfflinePlaylistConfirm,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.l10n!.cancel),
            ),
            FilledButton(
              onPressed: () {
                offlinePlaylistService.removeOfflinePlaylist(playlistId);
                Navigator.pop(context);
                showToast(context, context.l10n!.playlistRemovedFromOffline);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.l10n!.remove),
            ),
          ],
        );
      },
    );
  }

  void _handleSyncPlaylist() async {
    if (_playlist['ytid'] != null) {
      _playlist = await updatePlaylistList(context, _playlist['ytid']);
      _pagingController.refresh();
    } else {
      final updatedPlaylist = await getPlaylistInfoForWidget(widget.playlistId);
      if (updatedPlaylist != null && mounted) {
        setState(() {
          _playlist = updatedPlaylist;
        });
        _pagingController.refresh();
      }
    }
  }

  void _updateSongsListOnRemove(int indexOfRemovedSong) {
    final items = _pagingController.items ?? [];
    if (indexOfRemovedSong >= items.length) return;

    final dynamic songToRemove = items[indexOfRemovedSong];
    final playlistTitle = _playlist['title'];
    if (mounted) {
      showToastWithButton(
        context,
        context.l10n!.songRemoved,
        context.l10n!.undo.toUpperCase(),
        () {
          addSongInCustomPlaylist(
            context,
            playlistTitle,
            songToRemove,
            indexToInsert: indexOfRemovedSong,
          );
          _pagingController.refresh();
        },
      );
    } else {
      logger.log(
        '(_updateSongsListOnRemove): Widget not mounted, cannot show undo toast.',
        null,
        null,
      );
    }

    _pagingController.refresh();
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

    // Reset paging controller to top
    _pagingController.refresh();
  }

  Widget _buildSongListItem(dynamic song, int index, bool isRemovable) {
    final items = _pagingController.items ?? [];
    final totalItems = items.length;
    final borderRadius = getItemBorderRadius(index, totalItems);
    final isUserCreatedPlaylist = _playlist?['source'] == 'user-created';
    final playlistId = isUserCreatedPlaylist ? _playlist!['ytid'] : null;

    return SongBar(
      song,
      true,
      onRemove: isRemovable
          ? () => {
              if (removeSongFromPlaylist(
                _playlist,
                song,
                removeOneAtIndex: index,
              ))
                {_updateSongsListOnRemove(index)},
            }
          : null,
      onPlay: () => {
        audioHandler.playPlaylistSong(playlist: _playlist, songIndex: index),
      },
      borderRadius: borderRadius,
      playlistId: playlistId,
      onRenamed: () => setState(() {}),
    );
  }
}
