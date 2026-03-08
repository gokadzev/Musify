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
import 'package:musify/main.dart';

class ShufflePlayButton extends StatelessWidget {
  const ShufflePlayButton({super.key, required this.songs});

  final List songs;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return IconButton.filledTonal(
      icon: Icon(FluentIcons.arrow_shuffle_24_filled, color: primaryColor),
      iconSize: 24,
      tooltip: 'Shuffle play',
      onPressed: () async {
        if (songs.isEmpty) return;
        final shuffledSongs = List<Map>.from(songs.whereType<Map>());
        if (shuffledSongs.isEmpty) return;
        shuffledSongs.shuffle();
        await audioHandler.addPlaylistToQueue(
          shuffledSongs,
          replace: true,
          startIndex: 0,
        );
      },
    );
  }
}
