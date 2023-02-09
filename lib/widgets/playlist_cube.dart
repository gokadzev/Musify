import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/playlistPage.dart';
import 'package:musify/style/appTheme.dart';
import 'package:musify/widgets/delayed_display.dart';

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
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.height * 0.3,
                  imageUrl: image.toString(),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: MediaQuery.of(context).size.height * 0.3,
                    child: Icon(
                      FluentIcons.music_note_1_24_regular,
                      size: 30,
                      color: accent.primary,
                    ),
                  ),
                )
              : Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.background,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          FluentIcons.music_note_1_24_regular,
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
