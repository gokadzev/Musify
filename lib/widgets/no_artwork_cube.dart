/*
 *     Copyright (C) 2025 Valeri Gokadze
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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class NullArtworkWidget extends StatelessWidget {
  const NullArtworkWidget({
    super.key,
    this.icon = FluentIcons.music_note_1_24_regular,
    this.size = 220,
    this.iconSize = 64,
    this.title,
  });

  final IconData icon;
  final double iconSize;
  final double size;
  final String? title;

  static const double paddingValue = 10;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: colorScheme.secondary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: iconSize, color: colorScheme.onSecondary),
            if (title != null)
              Padding(
                padding: const EdgeInsets.all(paddingValue),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSecondary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
