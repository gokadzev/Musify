import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';

class SongBar extends StatefulWidget {
  final dynamic song;
  const SongBar({Key? key, required this.song}) : super(key: key);

  @override
  State<SongBar> createState() => _SongBarState();
}

class _SongBarState extends State<SongBar> {
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
          playSong((widget.song));
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
                ((widget.song)['title'])
                    .toString()
                    .split("(")[0]
                    .replaceAll("&quot;", "\"")
                    .replaceAll("&amp;", "&"),
                style: TextStyle(color: accent),
              ),
              subtitle: Text(
                widget.song['more_info']["singers"],
                style: TextStyle(color: accentLight),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    color: accent,
                    icon: isSongAlreadyLiked((widget.song)['ytid'])
                        ? Icon(MdiIcons.star)
                        : Icon(MdiIcons.starOutline),
                    onPressed: () => {
                          setState(() {
                            isSongAlreadyLiked((widget.song)['ytid'])
                                ? removeUserLikedSong((widget.song)['ytid'])
                                : addUserLikedSong((widget.song)['ytid']);
                          })
                        }),
                IconButton(
                  color: accent,
                  icon: Icon(MdiIcons.downloadOutline),
                  onPressed: () => downloadSong((widget.song)),
                ),
              ]),
            )
          ],
        ),
      ),
    );
  }
}
