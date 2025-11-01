/*
 *     Copyright (C) 2025 Valeri Gokadze
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
import 'package:musify/utilities/playlist_image_picker.dart';
import 'package:musify/utilities/sort_utils.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/playlist_header.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/sort_button.dart';
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
        actions: [
          if (widget.playlistId != null) ...[_buildLikeButton()],
          const SizedBox(width: 10),
          if (_playlist != null) ...[
            _buildSyncButton(),
            const SizedBox(width: 10),
            _buildDownloadButton(),
            const SizedBox(width: 10),
            if (_playlist['source'] == 'user-created')
              IconButton(
                icon: const Icon(FluentIcons.share_24_regular),
                onPressed: () async {
                  final encodedPlaylist = PlaylistSharingService.encodePlaylist(
                    _playlist,
                  );

                  final url = 'musify://playlist/custom/$encodedPlaylist';
                  await Clipboard.setData(ClipboardData(text: url));
                },
              ),
            const SizedBox(width: 10),
          ],
          if (_playlist != null && _playlist['source'] == 'user-created') ...[
            _buildEditButton(),
            const SizedBox(width: 10),
          ],
        ],
      ),
      body: _playlist != null
          ? PagingListener(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: buildPlaylistHeader(),
                    ),
                  ),
                  if (_playlist['list'].isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 15,
                          bottom: 20,
                          right: 20,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildSortSongActionButton(),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: commonListViewBottmomPadding,
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
      size: isLandscape ? 300 : screenWidth / 2.5,
      cubeIcon: widget.cubeIcon,
    );
  }

  Widget buildPlaylistHeader() {
    final _songsLength = _playlist['list'].length;

    return PlaylistHeader(
      _buildPlaylistImage(),
      _playlist['title'],
      _songsLength,
    );
  }

  Widget _buildLikeButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: playlistLikeStatus,
      builder: (_, value, __) {
        return IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: value
              ? const Icon(FluentIcons.heart_24_filled)
              : const Icon(FluentIcons.heart_24_regular),
          iconSize: 26,
          onPressed: () {
            playlistLikeStatus.value = !playlistLikeStatus.value;
            updatePlaylistLikeStatus(
              _playlist['ytid'],
              playlistLikeStatus.value,
            );
            currentLikedPlaylistsLength.value = value
                ? currentLikedPlaylistsLength.value + 1
                : currentLikedPlaylistsLength.value - 1;
          },
        );
      },
    );
  }

  Widget _buildSyncButton() {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.arrow_sync_24_filled),
      iconSize: 26,
      onPressed: _handleSyncPlaylist,
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.edit_24_filled),
      iconSize: 26,
      onPressed: () => showDialog(
        context: context,
        builder: (BuildContext context) {
          String customPlaylistName = _playlist['title'];
          String? imageUrl = _playlist['image'];
          var imageBase64 = (imageUrl != null && imageUrl.startsWith('data:'))
              ? imageUrl
              : null;
          if (imageBase64 != null) imageUrl = null;

          return StatefulBuilder(
            builder: (context, dialogSetState) {
              Future<void> _pickImage() async {
                final result = await pickImage();
                if (result != null) {
                  dialogSetState(() {
                    imageBase64 = result;
                    imageUrl = null;
                  });
                }
              }

              Widget _imagePreview() {
                return buildImagePreview(
                  imageBase64: imageBase64,
                  imageUrl: imageUrl,
                );
              }

              return AlertDialog(
                content: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 7),
                      TextField(
                        controller: TextEditingController(
                          text: customPlaylistName,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n!.customPlaylistName,
                        ),
                        onChanged: (value) {
                          customPlaylistName = value;
                        },
                      ),
                      if (imageBase64 == null) ...[
                        const SizedBox(height: 7),
                        TextField(
                          controller: TextEditingController(text: imageUrl),
                          decoration: InputDecoration(
                            labelText: context.l10n!.customPlaylistImgUrl,
                          ),
                          onChanged: (value) {
                            imageUrl = value;
                            imageBase64 = null;
                            dialogSetState(() {});
                          },
                        ),
                      ],
                      const SizedBox(height: 7),
                      if (imageUrl == null) ...[
                        buildImagePickerRow(
                          context,
                          _pickImage,
                          imageBase64 != null,
                        ),
                        _imagePreview(),
                      ],
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(context.l10n!.update.toUpperCase()),
                    onPressed: () {
                      final index = userCustomPlaylists.value.indexOf(
                        widget.playlistData,
                      );

                      if (index != -1) {
                        final newPlaylist = {
                          'title': customPlaylistName,
                          'source': 'user-created',
                          if (imageBase64 != null)
                            'image': imageBase64
                          else if (imageUrl != null)
                            'image': imageUrl,
                          'list': widget.playlistData['list'],
                        };
                        final updatedPlaylists = List<Map>.from(
                          userCustomPlaylists.value,
                        );
                        updatedPlaylists[index] = newPlaylist;
                        userCustomPlaylists.value = updatedPlaylists;
                        addOrUpdateData(
                          'user',
                          'customPlaylists',
                          userCustomPlaylists.value,
                        );
                        setState(() {
                          _playlist = newPlaylist;
                        });
                        showToast(context, context.l10n!.playlistUpdated);
                      }

                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
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
          return IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: const Icon(FluentIcons.arrow_download_off_24_filled),
            iconSize: 26,
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
              return Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.progress,
                    strokeWidth: 2,
                    backgroundColor: Colors.grey.withValues(alpha: .3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    icon: const Icon(FluentIcons.dismiss_24_filled),
                    iconSize: 14,
                    onPressed: () => offlinePlaylistService.cancelDownload(
                      context,
                      playlistId,
                    ),
                    tooltip: context.l10n!.cancel,
                  ),
                ],
              );
            }

            return IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: const Icon(FluentIcons.arrow_download_24_filled),
              iconSize: 26,
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n!.removeOfflinePlaylist),
          content: Text(context.l10n!.removeOfflinePlaylistConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n!.cancel.toUpperCase()),
            ),
            TextButton(
              onPressed: () {
                offlinePlaylistService.removeOfflinePlaylist(playlistId);
                Navigator.pop(context);
                showToast(context, context.l10n!.playlistRemovedFromOffline);
              },
              child: Text(context.l10n!.remove.toUpperCase()),
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
    showToastWithButton(
      context,
      context.l10n!.songRemoved,
      context.l10n!.undo.toUpperCase(),
      () {
        addSongInCustomPlaylist(
          context,
          _playlist['title'],
          songToRemove,
          indexToInsert: indexOfRemovedSong,
        );
        _pagingController.refresh();
      },
    );

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

  Widget _buildSortSongActionButton() {
    return SortButton<PlaylistSortType>(
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

        // Refresh pagination inside setState ensures UI updates properly
        _pagingController.refresh();
      },
    );
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
    );
  }
}
