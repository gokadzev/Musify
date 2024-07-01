/*
 *     Copyright (C) 2024 Valeri Gokadze
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

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/widgets/no_artwork_cube.dart';

class SongBar extends StatelessWidget {
  SongBar(
    this.song,
    this.clearPlaylist, {
    this.backgroundColor,
    this.showMusicDuration = false,
    this.onPlay,
    this.onRemove,
    super.key,
  });

  final dynamic song;
  final bool clearPlaylist;
  final Color? backgroundColor;
  final VoidCallback? onRemove;
  final VoidCallback? onPlay;
  final bool showMusicDuration;

  static const likeStatusToIconMapper = {
    true: FluentIcons.heart_24_filled,
    false: FluentIcons.heart_24_regular,
  };

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: GestureDetector(
        onTap: onPlay ??
            () {
              audioHandler.playSong(song);
              if (activePlaylist.isNotEmpty && clearPlaylist) {
                activePlaylist = {
                  'ytid': '',
                  'title': 'No Playlist',
                  'image': '',
                  'list': [],
                };
                activeSongId = 0;
              }
            },
        child: Card(
          elevation: 1.5,
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildAlbumArt(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song['title'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        song['artist'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(context, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    const size = 60.0;
    const radius = 12.0;

    final bool isOffline = song['isOffline'] ?? false;
    final String? artworkPath = song['artworkPath'];
    if (isOffline && artworkPath != null) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(artworkPath),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        key: Key(song['ytid'].toString()),
        width: size,
        height: size,
        imageUrl: song['lowResImage'].toString(),
        imageBuilder: (context, imageProvider) => SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image(
              image: imageProvider,
              centerSlice: const Rect.fromLTRB(1, 1, 1, 1),
            ),
          ),
        ),
        errorWidget: (context, url, error) => const NullArtworkWidget(
          iconSize: 30,
        ),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    final songLikeStatus =
        ValueNotifier<bool>(isSongAlreadyLiked(song['ytid']));
    final songOfflineStatus =
        ValueNotifier<bool>(isSongAlreadyOffline(song['ytid']));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!offlineMode.value)
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: songLikeStatus,
                builder: (_, value, __) {
                  return IconButton(
                    color: primaryColor,
                    icon: Icon(likeStatusToIconMapper[value]),
                    onPressed: () {
                      songLikeStatus.value = !songLikeStatus.value;
                      updateSongLikeStatus(
                        song['ytid'],
                        songLikeStatus.value,
                      );
                      final likedSongsLength = currentLikedSongsLength.value;
                      currentLikedSongsLength.value =
                          value ? likedSongsLength + 1 : likedSongsLength - 1;
                    },
                  );
                },
              ),
              if (onRemove != null)
                IconButton(
                  color: primaryColor,
                  icon: const Icon(FluentIcons.delete_24_filled),
                  onPressed: () => onRemove!(),
                )
              else
                IconButton(
                  color: primaryColor,
                  icon: const Icon(FluentIcons.add_24_regular),
                  onPressed: () => showAddToPlaylistDialog(context, song),
                ),
            ],
          ),
        ValueListenableBuilder<bool>(
          valueListenable: songOfflineStatus,
          builder: (_, value, __) {
            return IconButton(
              color: primaryColor,
              icon: Icon(
                value
                    ? FluentIcons.cellular_off_24_regular
                    : FluentIcons.cellular_data_1_24_regular,
              ),
              onPressed: () {
                if (value) {
                  removeSongFromOffline(song['ytid']);
                } else {
                  makeSongOffline(song);
                }

                songOfflineStatus.value = !songOfflineStatus.value;
              },
            );
          },
        ),
        if (showMusicDuration && song['duration'] != null)
          Text('(${formatDuration(song['duration'])})'),
      ],
    );
  }
}

void showAddToPlaylistDialog(BuildContext context, dynamic song) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: const Icon(FluentIcons.text_bullet_list_add_24_filled),
        title: Text(context.l10n!.addToPlaylist),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: userCustomPlaylists.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: userCustomPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = userCustomPlaylists[index];
                    return Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      elevation: 0,
                      child: ListTile(
                        title: Text(playlist['title']),
                        onTap: () {
                          addSongInCustomPlaylist(playlist['title'], song);
                          showToast(context, context.l10n!.songAdded);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                )
              : Text(
                  context.l10n!.noCustomPlaylists,
                  textAlign: TextAlign.center,
                ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.l10n!.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
