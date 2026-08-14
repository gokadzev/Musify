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
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';

/// The top of a playlist, album or artist page: artwork, title and the chips
/// describing what is being shown.
class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader(
    this.image,
    this.title, {
    super.key,
    this.songsLength,
    this.isAlbum,
    this.isArtist = false,
    this.showImage = true,
    this.showTitle = true,
    this.monthlyListeners,
    this.description,
  });

  final Widget image;
  final String title;

  /// Left null by the artist page, which does not hold the song list itself.
  final int? songsLength;
  final bool? isAlbum;
  final bool isArtist;
  final bool showImage;
  final bool showTitle;

  /// Monthly listeners of an artist, already shortened, e.g. `447M`.
  final String? monthlyListeners;

  /// Artist biography, collapsed until tapped.
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          if (showImage) ...[
            if (isArtist)
              ClipOval(child: image)
            else
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
          ],
          if (showTitle) ...[
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.secondary,
                letterSpacing: 0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isArtist)
                _Chip(
                  icon: FluentIcons.person_16_regular,
                  label: context.l10n!.artist,
                  color: colorScheme.primaryContainer,
                  onColor: colorScheme.onPrimaryContainer,
                  theme: theme,
                )
              else if (isAlbum != null)
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
              if (songsLength != null)
                _Chip(
                  icon: FluentIcons.text_bullet_list_24_filled,
                  label: '$songsLength ${context.l10n!.songs}',
                  color: colorScheme.secondaryContainer,
                  onColor: colorScheme.onSecondaryContainer,
                  theme: theme,
                ),
              if (monthlyListeners != null)
                _Chip(
                  icon: FluentIcons.headphones_20_filled,
                  label: '$monthlyListeners ${context.l10n!.monthlyListeners}',
                  color: colorScheme.secondaryContainer,
                  onColor: colorScheme.onSecondaryContainer,
                  theme: theme,
                ),
            ],
          ),
          if (description != null && description!.trim().isNotEmpty)
            _Description(description!.trim()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// The artist biography, three lines until it is tapped.
class _Description extends StatefulWidget {
  const _Description(this.text);

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Text(
          widget.text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
        ),
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
