/*
 *     Copyright (C) 2026 Valeri Gokadze
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
    this.iconSize,
    this.title,
    this.borderRadius = 12,
  });

  final IconData icon;
  final double? iconSize;
  final double size;
  final String? title;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate icon size based on container size if not provided
    final calculatedIconSize = iconSize ?? (size * 0.3);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: calculatedIconSize,
              color: colorScheme.onSurfaceVariant,
            ),
            if (title != null) ...[
              SizedBox(height: size * 0.04),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.08),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: (size * 0.06).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
