import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/style/app_themes.dart';
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
    final calculatedSize = MediaQuery.of(context).size.height * 0.3;
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
                  height: calculatedSize,
                  width: calculatedSize,
                  imageUrl: image.toString(),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => SizedBox(
                    height: calculatedSize,
                    width: calculatedSize,
                    child: Icon(
                      FluentIcons.music_note_1_24_regular,
                      size: 30,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              : Container(
                  height: calculatedSize,
                  width: calculatedSize,
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
                          color: colorScheme.primary,
                        ),
                        Text(
                          title,
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
