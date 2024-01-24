import 'package:flutter/material.dart';
import 'package:musify/extensions/colorScheme.dart';

class SettingSwitchBar extends StatelessWidget {
  SettingSwitchBar(
    this.tileName,
    this.tileIcon,
    this.value,
    this.onChanged, {
    super.key,
  });

  final Function(bool) onChanged;
  final bool value;
  final String tileName;
  final IconData tileIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: SwitchListTile(
          inactiveThumbColor: context.colorScheme.background,
          secondary: Icon(tileIcon, color: context.colorScheme.primary),
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
