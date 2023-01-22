import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/delayed_display.dart';
import 'package:musify/style/appTheme.dart';
import 'package:musify/ui/playlistPage.dart';

class PlaylistCube extends StatelessWidget {
  const PlaylistCube({
    super.key,
    required this.id,
    required this.image,
    required this.title,
  });
  final String id;
  final dynamic image;
  final String title;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return DelayedDisplay(
      delay: const Duration(milliseconds: 200),
      fadingDuration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () {
          getPlaylistInfoForWidget(id).then(
            (value) => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(playlist: value),
                ),
              )
            },
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: image != ''
              ? CachedNetworkImage(
                  width: size.width / 1.9,
                  height: size.height / 4.15,
                  imageUrl: image.toString(),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => SizedBox(
                    width: size.width / 1.9,
                    height: size.height / 4.15,
                    child: Icon(
                      MdiIcons.musicNoteOutline,
                      size: 30,
                      color: accent.primary,
                    ),
                  ),
                )
              : Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).backgroundColor,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          MdiIcons.musicNoteOutline,
                          size: 30,
                          color: accent.primary,
                        ),
                        Text(
                          title,
                          style: TextStyle(color: accent.primary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
