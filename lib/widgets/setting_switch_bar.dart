import 'package:flutter/material.dart';
import 'package:musify/style/app_themes.dart';

class SettingSwitchBar extends StatelessWidget {
  SettingSwitchBar(this.tileName, this.tileIcon, this.value, this.onChanged);

  final Function(bool) onChanged;
  final bool value;
  final String tileName;
  final IconData tileIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
      child: Card(
        child: SwitchListTile(
          inactiveThumbColor: colorScheme.background,
          secondary: Icon(tileIcon, color: colorScheme.primary),
          title: Text(
            tileName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
