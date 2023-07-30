import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_themes.dart';

class SongBar extends StatelessWidget {
  SongBar(this.song, this.clearPlaylist, {super.key});

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
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
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
        splashColor: colorScheme.primary.withOpacity(0.4),
        hoverColor: colorScheme.primary.withOpacity(0.4),
        focusColor: colorScheme.primary.withOpacity(0.4),
        highlightColor: colorScheme.primary.withOpacity(0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CachedNetworkImage(
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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      song['title']
                          .toString()
                          .split('(')[0]
                          .replaceAll('&quot;', '"')
                          .replaceAll('&amp;', '&'),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      song['artist'].toString(),
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
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
                      icon: Icon(likeStatusToIconMapper[value]),
                    );
                  },
                ),
                IconButton(
                  color: colorScheme.primary,
                  icon: const Icon(FluentIcons.arrow_download_24_regular),
                  onPressed: () => prefferedDownloadMode.value == 'normal'
                      ? downloadSong(context, song)
                      : downloadSongFaster(context, song),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
