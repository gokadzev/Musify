import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class NullArtworkWidget extends StatelessWidget {
  const NullArtworkWidget({
    this.icon = FluentIcons.music_note_1_24_regular,
    required this.iconSize,
    required this.backgroundColor,
    required this.iconColor,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: backgroundColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ],
      ),
    );
  }
}
