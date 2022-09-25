import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/style/appTheme.dart';

class SongBar extends StatelessWidget {
  SongBar(this.song, this.moveBackAfterPlay, {super.key});

  late final dynamic song;
  late final bool moveBackAfterPlay;
  late final songLikeStatus =
      ValueNotifier<bool>(isSongAlreadyLiked(song['ytid']));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          playSong(song);
          if (activePlaylist.isNotEmpty) {
            activePlaylist = [];
            id = 0;
          }
          if (moveBackAfterPlay) {
            Navigator.pushReplacementNamed(context, '/');
          }
        },
        splashColor: accent.withOpacity(0.4),
        hoverColor: accent.withOpacity(0.4),
        focusColor: accent.withOpacity(0.4),
        highlightColor: accent.withOpacity(0.4),
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
                        color: accent,
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
                        color: accent,
                        icon: const Icon(MdiIcons.star),
                        onPressed: () => {
                          removeUserLikedSong(song['ytid']),
                          songLikeStatus.value = false
                        },
                      );
                    } else {
                      return IconButton(
                        color: accent,
                        icon: const Icon(MdiIcons.starOutline),
                        onPressed: () => {
                          addUserLikedSong(song['ytid']),
                          songLikeStatus.value = true
                        },
                      );
                    }
                  },
                ),
                IconButton(
                  color: accent,
                  icon: const Icon(MdiIcons.downloadOutline),
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
