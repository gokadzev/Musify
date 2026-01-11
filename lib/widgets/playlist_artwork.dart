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
import 'package:musify/utilities/artwork_provider.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/widgets/no_artwork_cube.dart';

class PlaylistArtwork extends StatelessWidget {
  const PlaylistArtwork({
    super.key,
    required this.playlistArtwork,
    this.playlistTitle,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.iconSize,
    this.size = 220,
  });

  final String? playlistArtwork;
  final String? playlistTitle;
  final IconData cubeIcon;
  final double? iconSize;
  final double size;

  Widget _nullArtwork() => NullArtworkWidget(
    icon: cubeIcon,
    iconSize: iconSize ?? (size * 0.3), // Default to 30% of container size
    size: size,
    title: playlistTitle,
  );

  @override
  Widget build(BuildContext context) {
    final image = playlistArtwork;
    if (image == null) return _nullArtwork();

    try {
      final provider = ArtworkProvider.get(image);
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: commonBarRadius,
          child: Image(
            image: provider,
            height: size,
            width: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _nullArtwork(),
          ),
        ),
      );
    } catch (_) {
      return _nullArtwork();
    }
  }
}
