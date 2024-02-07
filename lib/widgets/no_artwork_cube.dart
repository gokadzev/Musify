import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class NullArtworkWidget extends StatelessWidget {
  const NullArtworkWidget({
    this.icon = FluentIcons.music_note_1_24_regular,
    this.size = 220,
    required this.iconSize,
    required this.backgroundColor,
    required this.iconColor,
    this.title,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
