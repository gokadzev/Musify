import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/style/app_themes.dart';

class NullArtworkWidget extends StatelessWidget {
  const NullArtworkWidget({
    this.icon = FluentIcons.music_note_1_24_regular,
    required this.iconSize,
    super.key,
  });

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colorScheme.secondary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: iconSize,
            color: colorScheme.surface,
          ),
        ],
      ),
    );
  }
}
