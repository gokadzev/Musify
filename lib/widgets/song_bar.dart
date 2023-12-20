import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';

class SongBar extends StatelessWidget {
  SongBar(
    this.song,
    this.clearPlaylist, {
    this.showMusicDuration = false,
    this.isFromPlaylist = false,
    this.updateOnRemove,
    this.passingPlaylist,
    this.songIndexInPlaylist,
    super.key,
  });

  final dynamic song;
  final bool clearPlaylist;
  final Function? updateOnRemove;
  final dynamic passingPlaylist;
  final int? songIndexInPlaylist;
  final bool showMusicDuration;
  final bool isFromPlaylist;

  static const likeStatusToIconMapper = {
    true: FluentIcons.star_24_filled,
    false: FluentIcons.star_24_regular,
  };

  late final songLikeStatus =
      ValueNotifier<bool>(isSongAlreadyLiked(song['ytid']));
  late final songOfflineStatus =
      ValueNotifier<bool>(isSongAlreadyOffline(song['ytid']));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () {
          audioHandler.playSong(song);
          if (activePlaylist.isNotEmpty && clearPlaylist) {
            activePlaylist = {
              'ytid': '',
              'title': 'No Playlist',
              'header_desc': '',
              'image': '',
              'list': [],
            };
            id = 0;
          }
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (song['isOffline'] != null &&
                    song['isOffline'] == true &&
                    song['artworkPath'] != null)
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image:
                              FileImage(File(song['lowResImage'].toString())),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else
                  CachedNetworkImage(
                    key: Key(song['ytid'].toString()),
                    width: 60,
                    height: 60,
                    imageUrl: song['lowResImage'].toString(),
                    imageBuilder: (context, imageProvider) => DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: imageProvider,
                          centerSlice: const Rect.fromLTRB(1, 1, 1, 1),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song['title'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        song['artist'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: songLikeStatus,
                      builder: (_, value, __) {
                        return IconButton(
                          color: Theme.of(context).colorScheme.primary,
                          icon: Icon(likeStatusToIconMapper[value]),
                          onPressed: () {
                            songLikeStatus.value = !songLikeStatus.value;
                            updateSongLikeStatus(
                              song['ytid'],
                              songLikeStatus.value,
                            );
                            final likedSongsLength =
                                currentLikedSongsLength.value;
                            currentLikedSongsLength.value = value
                                ? likedSongsLength + 1
                                : likedSongsLength - 1;
                          },
                        );
                      },
                    ),
                    IconButton(
                      color: Theme.of(context).colorScheme.primary,
                      icon: isFromPlaylist
                          ? const Icon(FluentIcons.delete_24_filled)
                          : const Icon(FluentIcons.add_24_regular),
                      onPressed: () => isFromPlaylist
                          ? _removeFromPlaylist(context, song)
                          : _showAddToPlaylistDialog(context, song),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: songOfflineStatus,
                      builder: (_, value, __) {
                        return IconButton(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, dynamic song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n!.addToPlaylist),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final playlist in userCustomPlaylists)
                Card(
                  color: colorScheme.secondary,
                  child: ListTile(
                    title: Text(playlist['title']),
                    onTap: () {
                      addSongInCustomPlaylist(playlist['title'], song);
                      showToast(context, context.l10n!.songAdded);
                      Navigator.pop(context);
                    },
                    textColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _removeFromPlaylist(BuildContext context, dynamic song) {
    if (passingPlaylist == null) {
      return;
    }
    removeSongFromPlaylist(
      passingPlaylist,
      song,
      removeOneAtIndex: songIndexInPlaylist,
    );
    if (updateOnRemove != null) updateOnRemove!();
  }
}
