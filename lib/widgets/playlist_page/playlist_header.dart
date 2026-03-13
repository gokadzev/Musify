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

class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader(
    this.image,
    this.title,
    this.songsLength, {
    super.key,
    this.isAlbum,
  });

  final Widget image;
  final String title;
  final int songsLength;
  final bool? isAlbum;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          ClipPath(
            clipper: const ShapeBorderClipper(
              shape: StarBorder(
                points: 8,
                pointRounding: 0.8,
                valleyRounding: 0.2,
                innerRadiusRatio: 0.6,
              ),
            ),
            child: image,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              if (isAlbum != null)
                _Chip(
                  icon: isAlbum!
                      ? FluentIcons.cd_16_regular
                      : FluentIcons.apps_list_24_regular,
                  label: isAlbum!
                      ? context.l10n!.album
                      : context.l10n!.playlist,
                  color: colorScheme.primaryContainer,
                  onColor: colorScheme.onPrimaryContainer,
                  theme: theme,
                ),
              _Chip(
                icon: FluentIcons.music_note_1_24_regular,
                label: '$songsLength ${context.l10n!.songs}',
                color: colorScheme.secondaryContainer,
                onColor: colorScheme.onSecondaryContainer,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
