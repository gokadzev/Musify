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
    return Card(
      color: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: () {
          playSong(song);
          activePlaylist = [];
          id = 0;
        },
        splashColor: accent,
        hoverColor: accent,
        focusColor: accent,
        highlightColor: accent,
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CachedNetworkImage(
                  width: 70,
                  height: 70,
                  imageUrl: song['lowResImage'].toString(),
                  imageBuilder: (context, imageProvider) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                overflow: TextOverflow.ellipsis,
                (song['title'])
                    .toString()
                    .split('(')[0]
                    .replaceAll('&quot;', '"')
                    .replaceAll('&amp;', '&'),
                style: TextStyle(color: accent),
              ),
              subtitle: Text(
                overflow: TextOverflow.ellipsis,
                song['more_info']['singers'].toString(),
                style: TextStyle(color: accentLight),
              ),
              trailing: Row(
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
            )
          ],
        ),
      ),
    );
  }
}
