import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/style/app_themes.dart';

class ArtistCube extends StatelessWidget {
  const ArtistCube({
    super.key,
    required this.artist,
  });

  final String artist;

  @override
  Widget build(BuildContext context) {
    final calculatedSize = context.screenSize.height * 0.25;
    return ClipRRect(
      borderRadius: BorderRadius.circular(150),
      child: Container(
        height: calculatedSize,
        width: calculatedSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: colorScheme.secondary,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                FluentIcons.person_24_regular,
                size: 30,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  artist,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
