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
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/playlist_download_service.dart';
import 'package:musify/services/playlist_sharing.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/playlist_header.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

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
  List<dynamic> _songsList = [];
  dynamic _playlist;

  bool _isLoading = true;
  bool _hasMore = true;
  final int _itemsPerPage = 35;
  var _currentPage = 0;
  var _currentLastLoadedId = 0;
  late final playlistLikeStatus = ValueNotifier<bool>(
    isPlaylistAlreadyLiked(widget.playlistId),
  );
  bool playlistOfflineStatus = false;

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
  }

  Future<void> _initializePlaylist() async {
    try {
      _playlist =
          (widget.playlistId != null)
              ? await getPlaylistInfoForWidget(
                widget.playlistId,
                isArtist: widget.isArtist,
              )
              : widget.playlistData;

      if (_playlist != null) {
        _loadMore();
      }
    } catch (e, stackTrace) {
      logger.log('Error initializing playlist:', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToast(context, context.l10n!.error);
      }
    }
  }

  void _loadMore() {
    _isLoading = true;
    fetch()
        .then((List<dynamic> fetchedList) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (fetchedList.isEmpty) {
                _hasMore = false;
              } else {
                _songsList.addAll(fetchedList);
              }
            });
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
  }

  Future<List<dynamic>> fetch() async {
    try {
      final list = <dynamic>[];
      final _count = _playlist['list'].length as int;
      final n = min(_itemsPerPage, _count - _currentPage * _itemsPerPage);
      for (var i = 0; i < n; i++) {
        list.add(_playlist['list'][_currentLastLoadedId]);
        _currentLastLoadedId++;
      }

      _currentPage++;
      return list;
    } catch (e, stackTrace) {
      logger.log('Error fetching playlist songs:', e, stackTrace);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pop(context, widget.playlistData == _playlist),
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
      body:
          _playlist != null
              ? CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: buildPlaylistHeader(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      child: buildSongActionsRow(),
                    ),
                  ),
                  SliverPadding(
                    padding: commonListViewBottmomPadding,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final isRemovable =
                              _playlist['source'] == 'user-created';
                          return _buildSongListItem(index, isRemovable);
                        },
                        childCount:
                            _hasMore
                                ? _songsList.length + 1
                                : _songsList.length,
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
          icon:
              value
                  ? const Icon(FluentIcons.heart_24_filled)
                  : const Icon(FluentIcons.heart_24_regular),
          iconSize: 26,
          onPressed: () {
            playlistLikeStatus.value = !playlistLikeStatus.value;
            updatePlaylistLikeStatus(
              _playlist['ytid'],
              playlistLikeStatus.value,
            );
            currentLikedPlaylistsLength.value =
                value
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
      onPressed:
          () => showDialog(
            context: context,
            builder: (BuildContext context) {
              var customPlaylistName = _playlist['title'];
              var imageUrl = _playlist['image'];

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
                      const SizedBox(height: 7),
                      TextField(
                        controller: TextEditingController(text: imageUrl),
                        decoration: InputDecoration(
                          labelText: context.l10n!.customPlaylistImgUrl,
                        ),
                        onChanged: (value) {
                          imageUrl = value;
                        },
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(context.l10n!.add.toUpperCase()),
                    onPressed: () {
                      setState(() {
                        final index = userCustomPlaylists.value.indexOf(
                          widget.playlistData,
                        );

                        if (index != -1) {
                          final newPlaylist = {
                            'title': customPlaylistName,
                            'source': 'user-created',
                            if (imageUrl != null) 'image': imageUrl,
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
                            userCustomPlaylists,
                          );
                          _playlist = newPlaylist;
                          showToast(context, context.l10n!.playlistUpdated);
                        }

                        Navigator.pop(context);
                      });
                    },
                  ),
                ],
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
                    onPressed:
                        () => offlinePlaylistService.cancelDownload(
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
              onPressed:
                  () => offlinePlaylistService.downloadPlaylist(
                    context,
                    _playlist,
                  ),
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
      _hasMore = true;
      _songsList.clear();
      setState(() {
        _currentPage = 0;
        _currentLastLoadedId = 0;
        _loadMore();
      });
    } else {
      final updatedPlaylist = await getPlaylistInfoForWidget(widget.playlistId);
      if (updatedPlaylist != null) {
        setState(() {
          _songsList = updatedPlaylist['list'];
        });
      }
    }
  }

  void _updateSongsListOnRemove(int indexOfRemovedSong) {
    final dynamic songToRemove = _songsList.elementAt(indexOfRemovedSong);
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
        _songsList.insert(indexOfRemovedSong, songToRemove);
        setState(() {});
      },
    );

    setState(() {
      _songsList.removeAt(indexOfRemovedSong);
    });
  }

  Widget _buildShuffleSongActionButton() {
    return IconButton(
      color: Theme.of(context).colorScheme.primary,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.arrow_shuffle_16_filled),
      iconSize: 25,
      onPressed: () {
        final _newList = List.of(_playlist['list'])..shuffle();
        setActivePlaylist({
          'title': _playlist['title'],
          'image': _playlist['image'],
          'list': _newList,
        });
      },
    );
  }

  Widget _buildSortSongActionButton() {
    return DropdownButton<String>(
      borderRadius: BorderRadius.circular(5),
      dropdownColor: Theme.of(context).colorScheme.secondaryContainer,
      underline: const SizedBox.shrink(),
      iconEnabledColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      iconSize: 25,
      icon: const Icon(FluentIcons.filter_16_filled),
      items:
          <String>[context.l10n!.name, context.l10n!.artist].map((
            String value,
          ) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (item) {
        setState(() {
          final playlist = _playlist['list'];

          void sortBy(String key) {
            playlist.sort((a, b) {
              final valueA = a[key].toString().toLowerCase();
              final valueB = b[key].toString().toLowerCase();
              return valueA.compareTo(valueB);
            });
          }

          if (item == context.l10n!.name) {
            sortBy('title');
          } else if (item == context.l10n!.artist) {
            sortBy('artist');
          }

          _playlist['list'] = playlist;

          // Reset pagination and reload
          _hasMore = true;
          _songsList.clear();
          _currentPage = 0;
          _currentLastLoadedId = 0;
          _loadMore();
        });
      },
    );
  }

  Widget buildSongActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildSortSongActionButton(),
        const SizedBox(width: 5),
        _buildShuffleSongActionButton(),
      ],
    );
  }

  Widget _buildSongListItem(int index, bool isRemovable) {
    if (index >= _songsList.length) {
      if (!_isLoading) {
        _loadMore();
      }
      return const Spinner();
    }

    final borderRadius = getItemBorderRadius(index, _songsList.length);

    return SongBar(
      _songsList[index],
      true,
      onRemove:
          isRemovable
              ? () => {
                if (removeSongFromPlaylist(
                  _playlist,
                  _songsList[index],
                  removeOneAtIndex: index,
                ))
                  {_updateSongsListOnRemove(index)},
              }
              : null,
      onPlay:
          () => {
            audioHandler.playPlaylistSong(
              playlist: activePlaylist != _playlist ? _playlist : null,
              songIndex: index,
            ),
          },
      isSongOffline: playlistOfflineStatus,
      borderRadius: borderRadius,
    );
  }
}
