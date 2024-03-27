import 'package:flutter/material.dart';

class SettingSwitchBar extends StatelessWidget {
  const SettingSwitchBar({
    super.key,
    required this.tileName,
    required this.tileIcon,
    required this.value,
    required this.onChanged,
  });

  final ValueChanged<bool> onChanged;
  final bool value;
  final String tileName;
  final IconData tileIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: SwitchListTile(
          secondary: Icon(tileIcon),
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
