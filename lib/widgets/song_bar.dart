import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/services/settings_manager.dart';

class SongBar extends StatelessWidget {
  SongBar(this.song, this.clearPlaylist);

  final dynamic song;
  final bool clearPlaylist;

  static const likeStatusToIconMapper = {
    true: FluentIcons.star_24_filled,
    false: FluentIcons.star_24_regular,
  };

  late final songLikeStatus =
      ValueNotifier<bool>(isSongAlreadyLiked(song['ytid']));

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        playSong(song);
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
      leading: CachedNetworkImage(
        key: Key(
          song['ytid'].toString(),
        ),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            overflow: TextOverflow.ellipsis,
            song['title']
                .toString()
                .split('(')[0]
                .replaceAll('&quot;', '"')
                .replaceAll('&amp;', '&'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            overflow: TextOverflow.ellipsis,
            song['artist'].toString(),
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
      trailing: Row(
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
                  final likedSongsLength = currentLikedSongsLength.value;
                  currentLikedSongsLength.value =
                      value ? likedSongsLength + 1 : likedSongsLength - 1;
                },
              );
            },
          ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            icon: const Icon(FluentIcons.arrow_download_24_regular),
            onPressed: () => prefferedDownloadMode.value == 'normal'
                ? downloadSong(context, song)
                : downloadSongFaster(context, song),
          ),
        ],
      ),
    );
  }
}
