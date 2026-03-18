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
import 'package:musify/extensions/l10n.dart';
import 'package:musify/widgets/playlist_artwork.dart';

class PlaylistCube extends StatelessWidget {
  const PlaylistCube(
    this.playlist, {
    super.key,
    this.playlistData,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.size = 220,
    this.borderRadius = 16,
    this.showTypeLabel = true,
  });

  final Map? playlistData;
  final Map playlist;
  final IconData cubeIcon;
  final double size;
  final double borderRadius;
  final bool showTypeLabel;

  static const double typeLabelOffset = 10;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PlaylistArtwork(
            playlistArtwork: playlist['image'],
            size: size,
            cubeIcon: cubeIcon,
          ),
          if (showTypeLabel && playlist['image'] != null)
            Positioned(
              top: typeLabelOffset,
              right: typeLabelOffset,
              child: _buildLabel(context),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAlbum = playlist['isAlbum'] == true;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        isAlbum ? context.l10n!.album : context.l10n!.playlist,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
