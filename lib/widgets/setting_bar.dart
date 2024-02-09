import 'package:flutter/material.dart';
import 'package:musify/extensions/colorScheme.dart';

class SettingBar extends StatelessWidget {
  SettingBar(this.tileName, this.tileIcon, this.onTap, {super.key});

  final VoidCallback onTap;
  final String tileName;
  final IconData tileIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: ListTile(
          leading: Icon(tileIcon, color: context.colorScheme.primary),
          title: Text(
            tileName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
