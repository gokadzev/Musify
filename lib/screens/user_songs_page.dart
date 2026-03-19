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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/song_filtering.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/playlist_page/empty_playlist_state.dart';
import 'package:musify/widgets/playlist_page/playlist_header.dart';
import 'package:musify/widgets/playlist_page/search_bar_section.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/sort_chips.dart';

enum OfflineSortType { default_, title, artist, dateAdded }

class UserSongsPage extends StatefulWidget {
  const UserSongsPage({super.key, required this.page});

  final String page;

  @override
  State<UserSongsPage> createState() => _UserSongsPageState();
}

class _UserSongsPageState extends State<UserSongsPage> {
  bool _isEditEnabled = false;
  List<dynamic> _originalOfflineSongsList = [];
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  List _getFilteredList(List songsList) {
    return filterSongsByQuery(songsList, _searchQueryNotifier.value);
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    if (widget.page == 'offline') {
      _originalOfflineSongsList = List<dynamic>.from(userOfflineSongs);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = getTitle(widget.page, context);
    final icon = getIcon(widget.page);
    final songsList = getSongsList(widget.page);
    final length = getLength(widget.page);
    final isLikedSongs = title == context.l10n!.likedSongs;
    final isOfflineSongs = title == context.l10n!.offlineSongs;

    return Scaffold(
      appBar: AppBar(
        title: offlineMode.value ? Text(title) : null,
        actions: [
          if (isLikedSongs && songsList.isNotEmpty)
            IconButton(
              onPressed: _toggleEditMode,
              icon: Icon(
                FluentIcons.re_order_24_filled,
                color: _isEditEnabled
                    ? Theme.of(context).colorScheme.inversePrimary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: _buildCustomScrollView(
        title,
        icon,
        songsList,
        length,
        isOfflineSongs,
      ),
    );
  }

  void _toggleEditMode() {
    setState(() => _isEditEnabled = !_isEditEnabled);
  }

  OfflineSortType _getCurrentOfflineSortType() {
    return OfflineSortType.values.firstWhere(
      (e) => e.name == offlineSortSetting,
      orElse: () => OfflineSortType.default_,
    );
  }

  Widget _buildCustomScrollView(
    String title,
    IconData icon,
    List songsList,
    ValueNotifier<int> length,
    bool isOfflineSongs,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderSection(
            title,
            icon,
            songsList.length,
            isOfflineSongs,
          ),
        ),
        buildSongList(title, songsList, length),
      ],
    );
  }

  String getTitle(String page, BuildContext context) {
    return switch (page) {
      'liked' => context.l10n!.likedSongs,
      'offline' => context.l10n!.offlineSongs,
      'recents' => context.l10n!.recentlyPlayed,
      _ => context.l10n!.playlist,
    };
  }

  IconData getIcon(String page) {
    return switch (page) {
      'liked' => FluentIcons.heart_24_regular,
      'offline' => FluentIcons.cloud_off_24_regular,
      'recents' => FluentIcons.history_24_regular,
      _ => FluentIcons.heart_24_regular,
    };
  }

  List getSongsList(String page) {
    return switch (page) {
      'liked' => userLikedSongsList,
      'offline' => userOfflineSongs,
      'recents' => userRecentlyPlayed,
      _ => userLikedSongsList,
    };
  }

  ValueNotifier<int> getLength(String page) {
    return switch (page) {
      'liked' => currentLikedSongsLength,
      'offline' => currentOfflineSongsLength,
      'recents' => currentRecentlyPlayedLength,
      _ => currentLikedSongsLength,
    };
  }

  Widget _buildHeaderSection(
    String title,
    IconData icon,
    int songsLength,
    bool isOfflineSongs,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRecentlyPlayed = title == context.l10n!.recentlyPlayed;

    return Column(
      children: [
        PlaylistHeader(_buildPlaylistImage(title, icon), title, songsLength),
        if (songsLength > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(FluentIcons.play_24_filled),
                    label: Text(context.l10n!.play),
                    onPressed: () {
                      final songsList = getSongsList(widget.page);
                      final playlist = {
                        'ytid': '',
                        'title': title,
                        'source': 'user-created',
                        'list': songsList,
                      };
                      audioHandler.playPlaylistSong(
                        playlist: playlist,
                        songIndex: 0,
                      );
                    },
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
                      final songs = getSongsList(widget.page);
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
          if (isRecentlyPlayed) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildClearRecentsButton(colorScheme.primary)],
            ),
          ],
        ],
        if (isOfflineSongs && songsLength > 1) ...[
          const SizedBox(height: 20),
          SortChips<OfflineSortType>(
            currentSortType: _getCurrentOfflineSortType(),
            sortTypes: OfflineSortType.values,
            sortTypeToString: _getSortTypeDisplayText,
            onSelected: (type) {
              setState(() {
                addOrUpdateData('settings', 'offlineSortType', type.name);
                offlineSortSetting = type.name;
              });
              _sortOfflineSongs(type);
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

  Widget _buildPlaylistImage(String title, IconData icon) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth > MediaQuery.sizeOf(context).height;
    return PlaylistCube(
      {'title': title},
      size: isLandscape ? 250 : screenWidth / commonPlaylistArtworkDivision,
      cubeIcon: icon,
    );
  }

  Widget _buildClearRecentsButton(Color primaryColor) {
    return IconButton.filledTonal(
      icon: Icon(FluentIcons.delete_24_regular, color: primaryColor),
      iconSize: 24,
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ConfirmationDialog(
              confirmationMessage: context.l10n!.clearRecentlyPlayedQuestion,
              submitMessage: context.l10n!.clear,
              isDangerous: true,
              onCancel: () => Navigator.pop(context),
              onSubmit: () {
                Navigator.pop(context);
                userRecentlyPlayed.clear();
                currentRecentlyPlayedLength.value = 0;
                addOrUpdateData('user', 'recentlyPlayedSongs', []);
                showToast(context, context.l10n!.recentlyPlayedMsg);
              },
            );
          },
        );
      },
    );
  }

  Widget buildSongList(
    String title,
    List songsList,
    ValueNotifier<int> currentSongsLength,
  ) {
    final isLikedSongs = title == context.l10n!.likedSongs;
    final isRecentlyPlayed = title == context.l10n!.recentlyPlayed;
    final isOfflineSongs = title == context.l10n!.offlineSongs;

    return ValueListenableBuilder(
      valueListenable: currentSongsLength,
      builder: (_, value, __) {
        return ValueListenableBuilder<String>(
          valueListenable: _searchQueryNotifier,
          builder: (_, searchQuery, __) {
            final isSearching = searchQuery.isNotEmpty;
            final displayList = _getFilteredList(songsList);
            final playlist = {
              'ytid': '',
              'title': title,
              'source': 'user-created',
              'list': displayList,
            };

            if (displayList.isEmpty) {
              final emptyIcon = isLikedSongs
                  ? FluentIcons.heart_24_regular
                  : FluentIcons.music_note_1_24_regular;
              return EmptyPlaylistState(
                icon: emptyIcon,
                message: context.l10n!.playlistEmpty,
              );
            }

            if (isLikedSongs && !isSearching) {
              return SliverReorderableList(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final song = displayList[index];
                  final borderRadius = getItemBorderRadius(
                    index,
                    displayList.length,
                  );
                  return ReorderableDragStartListener(
                    enabled: _isEditEnabled,
                    key: listItemKey('liked_song', index, song),
                    index: index,
                    child: _buildSongBar(
                      song,
                      index,
                      borderRadius,
                      playlist,
                      isRecentSong: isRecentlyPlayed,
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    moveLikedSong(oldIndex, newIndex);
                  });
                },
              );
            } else {
              return SliverList(
                key: isOfflineSongs && !isSearching
                    ? ValueKey(_getCurrentOfflineSortType())
                    : null,
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = displayList[index];
                  final borderRadius = getItemBorderRadius(
                    index,
                    displayList.length,
                  );
                  return RepaintBoundary(
                    key: listItemKey('offline_song', index, song),
                    child: _buildSongBar(
                      song,
                      index,
                      borderRadius,
                      playlist,
                      isRecentSong: isRecentlyPlayed,
                    ),
                  );
                }, childCount: displayList.length),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSongBar(
    Map song,
    int index,
    BorderRadius borderRadius,
    Map playlist, {
    bool isRecentSong = false,
  }) {
    final isLikedSongs = playlist['title'] == context.l10n!.likedSongs;

    return SongBar(
      key: listItemKey('user_song', index, song),
      song,
      true,
      onPlay: () {
        final currentQueue = audioHandler.currentQueue;
        final isSameQueue =
            currentQueue.length == playlist['list'].length &&
            index < currentQueue.length &&
            currentQueue[index] == song;

        if (isSameQueue) {
          audioHandler.skipToSong(index);
        } else {
          audioHandler.playPlaylistSong(playlist: playlist, songIndex: index);
        }
      },
      borderRadius: borderRadius,
      isRecentSong: isRecentSong,
      isFromLikedSongs: isLikedSongs,
    );
  }

  String _getSortTypeDisplayText(OfflineSortType type) {
    return switch (type) {
      OfflineSortType.default_ => context.l10n!.default_,
      OfflineSortType.title => context.l10n!.name,
      OfflineSortType.artist => context.l10n!.artist,
      OfflineSortType.dateAdded => context.l10n!.dateAdded,
    };
  }

  void _sortOfflineSongs(OfflineSortType type) {
    switch (type) {
      case OfflineSortType.default_:
        userOfflineSongs
          ..clear()
          ..addAll(_originalOfflineSongsList);
        return;
      case OfflineSortType.title:
        userOfflineSongs.sort((a, b) {
          final titleA = (a['title'] ?? '').toString().toLowerCase();
          final titleB = (b['title'] ?? '').toString().toLowerCase();
          return titleA.compareTo(titleB);
        });
        break;
      case OfflineSortType.artist:
        userOfflineSongs.sort((a, b) {
          final artistA = (a['artist'] ?? '').toString().toLowerCase();
          final artistB = (b['artist'] ?? '').toString().toLowerCase();
          return artistA.compareTo(artistB);
        });
        break;
      case OfflineSortType.dateAdded:
        userOfflineSongs.sort((a, b) {
          final dateA = a['dateAdded'] as int? ?? 0;
          final dateB = b['dateAdded'] as int? ?? 0;
          return dateB.compareTo(dateA);
        });
        break;
    }
  }
}
