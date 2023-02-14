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
          secondary: Icon(tileIcon, color: accent.primary),
          title: Text(
            tileName,
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
