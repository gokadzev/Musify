import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class NullArtworkWidget extends StatelessWidget {
  const NullArtworkWidget({
    this.icon = FluentIcons.music_note_1_24_regular,
    this.size = 220,
    required this.iconSize,
    this.title,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final double size;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
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
            color: colorScheme.onPrimary,
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
