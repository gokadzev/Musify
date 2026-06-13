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
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/artist_service.dart';
import 'package:musify/utilities/artwork_provider.dart';

class ArtistBar extends StatelessWidget {
  const ArtistBar({
    super.key,
    required this.artist,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
  });

  final Map artist;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = normalizeArtistDisplayTitle(
      artist['title']?.toString() ?? context.l10n!.artist,
    );
    final image = normalizeArtistThumbnailUrl(artist['image']?.toString());

    return Padding(
      padding: commonBarPadding,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Row(
              children: [
                _ArtistArtwork(image: image),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n!.artist.toLowerCase(),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  FluentIcons.chevron_right_24_regular,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtistArtwork extends StatelessWidget {
  const _ArtistArtwork({required this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (image != null && image!.isNotEmpty) {
      return ClipOval(
        child: Image(
          image: ArtworkProvider.get(image!),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(colorScheme),
        ),
      );
    }

    return _fallback(colorScheme);
  }

  Widget _fallback(ColorScheme colorScheme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        FluentIcons.person_24_filled,
        size: 26,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }
}
