import 'package:flutter/material.dart';
import 'package:musify/style/appTheme.dart';

class SettingBar extends StatelessWidget {
  SettingBar(this.tileName, this.tileIcon, this.onTap);

  final Function() onTap;
  final String tileName;
  final IconData tileIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 6),
      child: Card(
        child: ListTile(
          leading: Icon(tileIcon, color: accent),
          title: Text(
            tileName,
            style: TextStyle(color: accent),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
