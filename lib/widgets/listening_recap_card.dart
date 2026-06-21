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

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/widgets/no_artwork_cube.dart';

const _musifyIconAsset = 'assets/icons/musify_icon.png';

class ListeningRecapCard extends StatelessWidget {
  const ListeningRecapCard({
    required this.periodLabel,
    required this.minutes,
    required this.songs,
    required this.onSongTap,
    this.onSongLongPress,
    this.featureFirstSong = false,
    this.highlightMinutes = false,
    this.outlined = false,
    super.key,
  });

  final String periodLabel;
  final int minutes;
  final List<Map<String, dynamic>> songs;
  final ValueChanged<int> onSongTap;
  final void Function(int index, Offset globalPosition)? onSongLongPress;
  final bool featureFirstSong;
  final bool highlightMinutes;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '$minutes',
                          maxLines: 1,
                          style: TextStyle(
                            color: highlightMinutes
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontSize: highlightMinutes ? 36 : 34,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l10n!.minutesListened,
                      maxLines: 2,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: highlightMinutes
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 3,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _RecapBrandHeader(periodLabel: periodLabel),
                ),
              ),
            ],
          ),
          if (songs.isNotEmpty) ...[
            SizedBox(height: featureFirstSong ? 14 : 12),
            if (featureFirstSong) ...[
              _FeaturedSongPreviewRow(
                index: 0,
                song: songs.first,
                onTap: () => onSongTap(0),
                onLongPress: onSongLongPress,
              ),
              for (var i = 1; i < songs.length; i++)
                _SongPreviewRow(
                  index: i,
                  song: songs[i],
                  onTap: () => onSongTap(i),
                  onLongPress: onSongLongPress,
                ),
            ] else
              for (var i = 0; i < songs.length; i++)
                _SongPreviewRow(
                  index: i,
                  song: songs[i],
                  onTap: () => onSongTap(i),
                  onLongPress: onSongLongPress,
                ),
          ],
        ],
      ),
    );

    return Padding(
      padding: commonBarPadding,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: outlined
            ? RoundedRectangleBorder(
                borderRadius: commonCustomBarRadius,
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
              )
            : null,
        borderRadius: outlined ? null : commonCustomBarRadius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _RecapBrandHeader extends StatelessWidget {
  const _RecapBrandHeader({required this.periodLabel});

  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallbackMaxWidth = MediaQuery.sizeOf(context).width - 64;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackMaxWidth;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ImageIcon(
                      const AssetImage(_musifyIconAsset),
                      size: 16,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Musify',
                      maxLines: 1,
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ' · $periodLabel',
                      maxLines: 1,
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecapSongArtwork extends StatelessWidget {
  const _RecapSongArtwork({
    required this.song,
    required this.size,
    required this.borderRadius,
  });

  final Map<String, dynamic> song;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cacheExtent = (size * MediaQuery.of(context).devicePixelRatio)
        .round()
        .clamp(96, 768);
    final artworkPath = _firstNonEmptyString([
      song['artworkPath'],
      song['artWorkPath'],
    ]);

    final imageUrl = _firstNonEmptyString([
      song['highResImage'],
      song['image'],
      song['lowResImage'],
    ]);

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildArtwork(artworkPath, imageUrl, cacheExtent),
      ),
    );
  }

  Widget _buildArtwork(String? artworkPath, String? imageUrl, int cacheExtent) {
    final localArtworkPath =
        _localFilePath(artworkPath) ?? _localFilePath(imageUrl);
    if (localArtworkPath != null) {
      return _buildFileArtwork(localArtworkPath, cacheExtent);
    }

    final remoteArtworkUrl =
        _remoteImageUrl(imageUrl) ?? _remoteImageUrl(artworkPath);
    if (remoteArtworkUrl != null) {
      return CachedNetworkImage(
        imageUrl: remoteArtworkUrl,
        width: size,
        height: size,
        // Only constrain the decode width: passing both width and height makes
        // ResizeImage use its default `exact` policy, which squashes the image
        // to NxN ignoring aspect ratio (~BoxFit.fill). A single dimension keeps
        // the aspect ratio so the BoxFit.cover below can frame it as a square.
        memCacheWidth: cacheExtent,
        imageBuilder: (_, imageProvider) => Image(
          image: imageProvider,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _buildFileArtwork(String artworkPath, int cacheExtent) {
    return Image.file(
      File(artworkPath),
      width: size,
      height: size,
      fit: BoxFit.cover,
      // Single decode dimension only: both width+height would force an
      // aspect-ratio-ignoring resize (ResizeImagePolicy.exact ~ BoxFit.fill)
      // that stretches non-square covers before BoxFit.cover can frame them.
      cacheWidth: cacheExtent,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => NullArtworkWidget(
    size: size,
    borderRadius: borderRadius,
    iconSize: size * 0.45,
  );

  String? _localFilePath(String? artwork) {
    if (artwork == null || artwork.isEmpty) return null;
    if (artwork.startsWith('file://')) {
      try {
        return Uri.parse(artwork).toFilePath();
      } catch (_) {
        return artwork.replaceFirst('file://', '');
      }
    }

    if (artwork.startsWith('/')) return artwork;
    return null;
  }

  String? _remoteImageUrl(String? artwork) {
    if (artwork == null || artwork.isEmpty) return null;
    return artwork.startsWith('http') ? artwork : null;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is! String) continue;
      if (value.isNotEmpty) return value;
    }

    return null;
  }
}

int _songPlayCount(Map<String, dynamic> song) {
  return int.tryParse(
        (song['playCount'] ?? song['listeningCount'] ?? '').toString(),
      ) ??
      0;
}

class _FeaturedSongPreviewRow extends StatelessWidget {
  const _FeaturedSongPreviewRow({
    required this.index,
    required this.song,
    required this.onTap,
    required this.onLongPress,
  });

  final int index;
  final Map<String, dynamic> song;
  final VoidCallback onTap;
  final void Function(int index, Offset globalPosition)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playCount = _songPlayCount(song);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: onLongPress == null
          ? null
          : (details) => onLongPress!(index, details.globalPosition),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _RecapSongArtwork(song: song, size: 58, borderRadius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song['artist']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (playCount > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Icon(
                          FluentIcons.headphones_20_filled,
                          size: 15,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$playCount',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SongPreviewRow extends StatelessWidget {
  const _SongPreviewRow({
    required this.index,
    required this.song,
    required this.onTap,
    required this.onLongPress,
  });

  final int index;
  final Map<String, dynamic> song;
  final VoidCallback onTap;
  final void Function(int index, Offset globalPosition)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playCount = _songPlayCount(song);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: onLongPress == null
          ? null
          : (details) => onLongPress!(index, details.globalPosition),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _RecapSongArtwork(song: song, size: 42, borderRadius: 8),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        song['artist']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (playCount > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Icon(
                          FluentIcons.headphones_20_filled,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$playCount',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
