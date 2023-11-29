import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/style/app_themes.dart';

class ArtistCube extends StatelessWidget {
  const ArtistCube(
    this.artist, {
    this.borderRadius = 150,
    this.borderRadiusInner = 10,
    this.iconSize = 30,
  });

  final String artist;
  final double borderRadius;
  final double borderRadiusInner;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final calculatedSize = MediaQuery.of(context).size.height * 0.25;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: calculatedSize,
        width: calculatedSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: colorScheme.secondary,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                FluentIcons.mic_sparkle_24_regular,
                size: iconSize,
                color: colorScheme.surface,
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
