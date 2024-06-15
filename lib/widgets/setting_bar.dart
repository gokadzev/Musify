/*
 *     Copyright (C) 2024 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  CustomListTile(
    this.tileName,
    this.tileIcon, {
    this.trailing,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final String tileName;
  final IconData tileIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Card(
        child: ListTile(
          minTileHeight: 65,
          leading: Icon(tileIcon),
          title: Text(
            tileName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: trailing,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    );
  }
}
