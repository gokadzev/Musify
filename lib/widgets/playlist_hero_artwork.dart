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
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/widgets/playlist_cube.dart';

class PlaylistHeroArtwork extends StatelessWidget {
  const PlaylistHeroArtwork(
    this.playlist, {
    super.key,
    this.cubeIcon = FluentIcons.text_bullet_list_24_filled,
  });

  final Map playlist;
  final IconData cubeIcon;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final size = screenSize.width > screenSize.height
        ? 250.0
        : screenSize.width / commonPlaylistArtworkDivision;
    final artwork = PlaylistCube(
      playlist,
      size: size,
      cubeIcon: cubeIcon,
      showTypeLabel: false,
    );

    return ClipPath(
      clipper: const ShapeBorderClipper(
        shape: StarBorder(
          points: 8,
          pointRounding: 0.8,
          valleyRounding: 0.2,
          innerRadiusRatio: 0.6,
        ),
      ),
      child: artwork,
    );
  }
}
