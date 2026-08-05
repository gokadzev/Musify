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
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/section_header.dart';

/// A titled row of artwork on the artist page: its releases, or the artists
/// suggested next to it. Releases are shown square, artists round.
class ArtistShelf extends StatelessWidget {
  const ArtistShelf({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.onTap,
    this.subtitleOf,
    this.cubeIcon = FluentIcons.cd_16_regular,
    this.circular = false,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onTap;
  final String Function(Map<String, dynamic> item)? subtitleOf;
  final IconData cubeIcon;
  final bool circular;

  static const _titleFontSize = 14.0;
  static const _subtitleFontSize = 12.0;
  static const _lineHeight = 1.3;
  static const _artworkGap = 8.0;
  static const _labelGap = 2.0;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final cubeSize = (width * 0.38).clamp(120.0, 180.0);

    return Column(
      children: [
        SectionHeader(title: title, icon: icon),
        SizedBox(
          // A horizontal list has to be given a height, and the labels below
          // the artwork are as tall as the text scale makes them.
          height: cubeSize + _labelsHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _buildCube(context, items[index], cubeSize),
          ),
        ),
      ],
    );
  }

  double _labelsHeight(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return _artworkGap +
        _labelGap +
        textScaler.scale(_titleFontSize) * _lineHeight * 2 +
        textScaler.scale(_subtitleFontSize) * _lineHeight;
  }

  Widget _buildCube(
    BuildContext context,
    Map<String, dynamic> item,
    double cubeSize,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = subtitleOf?.call(item);
    final artwork = PlaylistCube(
      item,
      size: cubeSize,
      cubeIcon: cubeIcon,
      showTypeLabel: false,
    );

    return SizedBox(
      width: cubeSize,
      child: GestureDetector(
        onTap: () => onTap(item),
        child: Column(
          crossAxisAlignment: circular
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (circular) ClipOval(child: artwork) else artwork,
            const SizedBox(height: _artworkGap),
            Text(
              item['title']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: circular ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: _titleFontSize,
                height: _lineHeight,
                color: colorScheme.onSurface,
              ),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: _labelGap),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: _subtitleFontSize,
                  height: _lineHeight,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
