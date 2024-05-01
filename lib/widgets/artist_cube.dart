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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class ArtistCube extends StatelessWidget {
  const ArtistCube(
    this.artist, {
    super.key,
    this.borderRadius = 150,
    this.borderRadiusInner = 10,
    this.iconSize = 30,
  });

  final String artist;
  final double borderRadius;
  final double borderRadiusInner;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final calculatedSize = MediaQuery.of(context).size.height * 0.25;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: calculatedSize,
      width: calculatedSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: colorScheme.secondary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            FluentIcons.mic_sparkle_24_regular,
            size: iconSize,
            color: colorScheme.onPrimary,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              artist,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
