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

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/async_loader.dart';
import 'package:musify/widgets/song_artwork.dart';

class NowPlayingArtwork extends StatelessWidget {
  const NowPlayingArtwork({
    super.key,
    required this.size,
    required this.metadata,
    required this.lyricsController,
  });
  final Size size;
  final MediaItem metadata;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isLandscape = screenWidth > screenHeight;
    final isDesktop = screenWidth > 800;
    final imageSize = isDesktop
        ? screenHeight * 0.38
        : isLandscape
        ? screenHeight * 0.45
        : screenWidth < 360
        ? screenWidth * 0.75
        : screenWidth < 600
        ? screenWidth * 0.80
        : screenWidth * 0.65;

    const borderRadius = 24.0;

    return FlipCard(
      rotateSide: RotateSide.right,
      onTapFlipping: !offlineMode.value,
      controller: lyricsController,
      frontWidget: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: SongArtworkWidget(
                metadata: metadata,
                size: imageSize,
                errorWidgetIconSize: size.width / 8,
                borderRadius: borderRadius,
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _AudioQualityBadge(metadata: metadata),
            ),
          ],
        ),
      ),
      backWidget: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: AsyncLoader<String?>(
          future: getSongLyrics(metadata.artist, metadata.title),
          emptyWidget: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FluentIcons.text_quote_24_regular,
                  size: 48,
                  color: colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n!.lyricsNotAvailable,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          errorBuilder: (ctx, error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FluentIcons.text_quote_24_regular,
                  size: 48,
                  color: colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n!.lyricsNotAvailable,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          builder: (context, lyrics) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Text(
              lyrics ?? context.l10n!.lyricsNotAvailable,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSecondaryContainer,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

typedef _AudioQualityInfo = ({int bitrateKbps, String codec});

String _normalizeCodec(String codec) => switch (codec) {
  final c when c.startsWith('opus') => 'Opus',
  final c when c.startsWith('mp4a') => 'AAC',
  final c => c,
};

/// Resolves once per song: reads the quality stored at download time for a
/// downloaded song (no network, works offline), otherwise reads the stream
/// resolved for playback. Returns null if there's nothing to show.
Future<_AudioQualityInfo?> _resolveAudioQuality(String ytid) async {
  final offlineSong = getOfflineSongByYtid(ytid);
  final offlineBitrate = offlineSong['audioBitrateKbps'] as int?;
  final offlineCodec = offlineSong['audioCodec'] as String?;
  if (offlineBitrate != null && offlineCodec != null) {
    return (bitrateKbps: offlineBitrate, codec: _normalizeCodec(offlineCodec));
  }
  if (offlineSong.isNotEmpty || offlineMode.value) return null;

  // Free for a song that is playing: the stream it picked is already resolved
  // and cached, so this reads it back instead of asking YouTube again.
  final stream = await fetchBestAudioStream(ytid);
  if (stream == null) return null;

  return (
    bitrateKbps: stream.bitrate.kiloBitsPerSecond.round(),
    codec: _normalizeCodec(stream.audioCodec),
  );
}

/// Shows the current song's audio bitrate/codec once it's resolved.
///
/// Resolves the info a single time per song (whenever [metadata]'s ytid
/// changes) instead of watching anything, since the badge is a one-shot,
/// purely cosmetic overlay. Reopening the screen resolves again, which is what
/// makes it pick up a change of the setting without listening to it — the
/// stream is cached per quality setting, so that costs nothing.
class _AudioQualityBadge extends StatefulWidget {
  const _AudioQualityBadge({required this.metadata});
  final MediaItem metadata;

  @override
  State<_AudioQualityBadge> createState() => _AudioQualityBadgeState();
}

class _AudioQualityBadgeState extends State<_AudioQualityBadge> {
  String? _resolvedYtid;
  Future<_AudioQualityInfo?>? _infoFuture;

  @override
  void initState() {
    super.initState();
    _resolveIfNeeded();
  }

  @override
  void didUpdateWidget(_AudioQualityBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveIfNeeded();
  }

  void _resolveIfNeeded() {
    final ytid = widget.metadata.extras?['ytid']?.toString();
    if (ytid == _resolvedYtid) return;
    _resolvedYtid = ytid;

    final shouldResolve =
        showAudioQualityBadge.value && ytid != null && ytid.isNotEmpty;
    _infoFuture = shouldResolve ? _resolveAudioQuality(ytid) : null;
  }

  @override
  Widget build(BuildContext context) {
    final infoFuture = _infoFuture;
    if (infoFuture == null) return const SizedBox.shrink();

    return FutureBuilder<_AudioQualityInfo?>(
      future: infoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${info.bitrateKbps} kbps • ${info.codec}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
