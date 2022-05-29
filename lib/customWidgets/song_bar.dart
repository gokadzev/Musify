import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';

class SongBar extends StatelessWidget {
  final dynamic song;

  const SongBar({required this.song});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () {
          playSong(song);
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
                child: Icon(
                  MdiIcons.musicNoteOutline,
                  size: 30,
                  color: accent,
                ),
              ),
              title: Text(
                (song['title'])
                    .toString()
                    .split("(")[0]
                    .replaceAll("&quot;", "\"")
                    .replaceAll("&amp;", "&"),
                style: TextStyle(color: accent),
              ),
              subtitle: Text(
                song['more_info']["singers"],
                style: TextStyle(color: accentLight),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  color: accent,
                  icon: isSongAlreadyLiked(song['ytid'])
                      ? Icon(MdiIcons.star)
                      : Icon(MdiIcons.starOutline),
                  onPressed: () => isSongAlreadyLiked(song['ytid'])
                      ? removeUserLikedSong(song['ytid'])
                      : addUserLikedSong(song['ytid']),
                ),
                IconButton(
                  color: accent,
                  icon: Icon(MdiIcons.downloadOutline),
                  onPressed: () => downloadSong(song),
                ),
              ]),
            )
          ],
        ),
      ),
    );
  }
}
