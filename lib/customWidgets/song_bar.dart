import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';

class SongBar extends StatelessWidget {
  SongBar(this.song);

  late final dynamic song;
  late final songLikeStatus =
      ValueNotifier<bool>(isSongAlreadyLiked(song['ytid']));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: () {
          playSong(song);
          if (activePlaylist.isNotEmpty) {
            activePlaylist = [];
            id = 0;
          }
        },
        splashColor: accent,
        hoverColor: accent,
        focusColor: accent,
        highlightColor: accent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CachedNetworkImage(
              width: 70,
              height: 70,
              imageUrl: song['lowResImage'].toString(),
              imageBuilder: (context, imageProvider) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
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
                          fontWeight: FontWeight.w700),
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
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                          fontSize: 14),
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
                  onPressed: () => downloadSong(song),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
