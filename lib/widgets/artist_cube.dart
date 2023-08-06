import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_themes.dart';

class ArtistCube extends StatelessWidget {
  const ArtistCube({
    super.key,
    required this.artist,
    this.borderRadius = 150.0,
    this.borderRadiusInner = 10.0,
    this.iconSize = 30.0,
  });

  final String artist;
  final double borderRadius;
  final double borderRadiusInner;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final calculatedSize = context.screenSize.height * 0.25;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: calculatedSize,
        width: calculatedSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadiusInner),
          color: colorScheme.secondary,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                color: useSystemColor.value
                    ? colorScheme.surface
                    : colorScheme.primary,
                FluentIcons.person_24_regular,
                size: iconSize,
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
