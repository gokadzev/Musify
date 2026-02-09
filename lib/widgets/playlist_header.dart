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

import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';

class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader(this.image, this.title, this.songsLength, {super.key});

  final Widget image;
  final String title;
  final int songsLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Center(child: image),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '$songsLength ${context.l10n!.songs}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
