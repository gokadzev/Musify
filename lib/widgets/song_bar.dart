import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/style/app_themes.dart';

class SongBar extends StatelessWidget {
  SongBar(this.song, this.clearPlaylist, {super.key});

  late final dynamic song;
  late final bool clearPlaylist;
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
                      (song['title'])
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
                      song['more_info']['singers'].toString(),
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
                    if (value == true) {
                      return IconButton(
                        color: colorScheme.primary,
                        icon: const Icon(FluentIcons.star_24_filled),
                        onPressed: () => {
                          updateLikeStatus(song['ytid'], false),
                          songLikeStatus.value = false
                        },
                      );
                    } else {
                      return IconButton(
                        color: colorScheme.primary,
                        icon: const Icon(FluentIcons.star_24_regular),
                        onPressed: () => {
                          updateLikeStatus(song['ytid'], true),
                          songLikeStatus.value = true
                        },
                      );
                    }
                  },
                ),
                IconButton(
                  color: colorScheme.primary,
                  icon: const Icon(FluentIcons.arrow_download_24_regular),
                  onPressed: () => downloadSong(context, song),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
