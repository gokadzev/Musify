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

import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/widgets/marquee.dart';
import 'package:musify/widgets/song_artwork.dart';
import 'package:rxdart/rxdart.dart';

typedef _PlayerSnapshot = ({PlaybackState playback, List<MediaItem> queue});

final Stream<_PlayerSnapshot> _snapshotStream = Rx.combineLatest2(
  audioHandler.playbackStateStream,
  audioHandler.queue.distinct(),
  (PlaybackState playback, List<MediaItem> queue) =>
      (playback: playback, queue: queue),
).asBroadcastStream();

final Stream<PositionData> _positionStream = audioHandler.positionDataStream
    .throttleTime(const Duration(milliseconds: 120), trailing: true)
    .asBroadcastStream();

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static const double playerHeight = 72;
  static const double _borderRadius = 20;
  static const double _artworkSize = 52;
  static const double _artworkRadius = 14;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, mediaSnapshot) {
          final metadata = mediaSnapshot.data;
          if (metadata == null) return const SizedBox.shrink();

          return StreamBuilder<_PlayerSnapshot>(
            stream: _snapshotStream,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) return const SizedBox.shrink();

              final index = data.playback.queueIndex ?? 0;
              return _MiniPlayerBody(
                metadata: metadata,
                playbackState: data.playback,
                hasNext: index < data.queue.length - 1,
              );
            },
          );
        },
      ),
    );
  }
}

class _MiniPlayerBody extends StatefulWidget {
  const _MiniPlayerBody({
    required this.metadata,
    required this.playbackState,
    required this.hasNext,
  });

  final MediaItem metadata;
  final PlaybackState playbackState;
  final bool hasNext;

  @override
  State<_MiniPlayerBody> createState() => _MiniPlayerBodyState();
}

class _MiniPlayerBodyState extends State<_MiniPlayerBody> {
  static const double _swipeUpVelocity = -300;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _openNowPlaying() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const NowPlayingPage(),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: child,
        ),
      ),
    );
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if ((details.primaryVelocity ?? 0) < _swipeUpVelocity) _openNowPlaying();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metadata = widget.metadata;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _openNowPlaying,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          height: MiniPlayer.playerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(MiniPlayer._borderRadius),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              _Artwork(metadata: metadata),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: _Metadata(
                    key: ValueKey(metadata.id),
                    title: metadata.title,
                    artist: metadata.artist,
                  ),
                ),
              ),
              _Controls(
                playbackState: widget.playbackState,
                fallbackDuration: metadata.duration,
                hasNext: widget.hasNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.metadata});

  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Hero(
        tag: 'now_playing_artwork',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MiniPlayer._artworkRadius),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow
                    .withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SongArtworkWidget(
            metadata: metadata,
            size: MiniPlayer._artworkSize,
            errorWidgetIconSize: 24,
            borderRadius: MiniPlayer._artworkRadius,
          ),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.title, required this.artist, super.key});

  final String title;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasArtist = artist != null && artist!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarqueeWidget(
            manualScrollEnabled: false,
            animationDuration: const Duration(seconds: 8),
            backDuration: const Duration(seconds: 2),
            pauseDuration: const Duration(seconds: 2),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.secondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          if (hasArtist) ...[
            const SizedBox(height: 2),
            Text(
              artist!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.playbackState,
    required this.fallbackDuration,
    required this.hasNext,
  });

  final PlaybackState playbackState;
  final Duration? fallbackDuration;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayButton(
          playbackState: playbackState,
          fallbackDuration: fallbackDuration,
        ),
        if (hasNext) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: audioHandler.skipToNext,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: const Icon(FluentIcons.next_24_filled, size: 22),
          ),
        ],
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playbackState,
    required this.fallbackDuration,
  });

  static const double _size = 48;

  final PlaybackState playbackState;
  final Duration? fallbackDuration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final processingState = playbackState.processingState;
    final isPlaying = playbackState.playing;
    final isLoading =
        processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering;
    final isCompleted = processingState == AudioProcessingState.completed;

    final IconData icon;
    final VoidCallback onPressed;
    if (isCompleted) {
      icon = FluentIcons.arrow_counterclockwise_24_filled;
      onPressed = audioHandler.playAgain;
    } else if (isPlaying) {
      icon = FluentIcons.pause_16_filled;
      onPressed = audioHandler.pause;
    } else {
      icon = FluentIcons.play_16_filled;
      onPressed = audioHandler.play;
    }

    return SizedBox.square(
      dimension: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: StreamBuilder<PositionData>(
              stream: _positionStream,
              builder: (context, snapshot) {
                return CustomPaint(
                  size: const Size.square(_size),
                  painter: _WavyProgressPainter(
                    progress: _progressOf(snapshot.data),
                    trackColor: colorScheme.surfaceContainerHighest,
                    progressColor: colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          else
            IconButton(
              onPressed: onPressed,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              icon: Icon(icon, color: colorScheme.primary, size: 22),
            ),
        ],
      ),
    );
  }

  double _progressOf(PositionData? data) {
    if (data == null) return 0;
    final total = data.duration > Duration.zero
        ? data.duration
        : (fallbackDuration ?? Duration.zero);
    if (total == Duration.zero) return 0;
    return (data.position.inMilliseconds / total.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }
}

class _WavyProgressPainter extends CustomPainter {
  const _WavyProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  static const double _strokeWidth = 3;
  static const double _waveAmplitude = 1.5;
  static const double _waveFrequency = 12;
  static const double _startAngle = -math.pi / 2;

  final double progress;
  final Color trackColor;
  final Color progressColor;

  Path _arc(Size size, double sweep) {
    final center = size.center(Offset.zero);
    final baseRadius = (size.width - _strokeWidth) / 2;
    final steps = (sweep.abs() * 180 / math.pi).round().clamp(4, 720);
    final path = Path();

    for (var i = 0; i <= steps; i++) {
      final angle = _startAngle + sweep * i / steps;
      final r = baseRadius + _waveAmplitude * math.sin(_waveFrequency * angle);
      final point = center + Offset.fromDirection(angle, r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  Paint _paint(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = _strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_arc(size, 2 * math.pi), _paint(trackColor));
    if (progress > 0) {
      canvas.drawPath(
        _arc(size, 2 * math.pi * progress),
        _paint(progressColor),
      );
    }
  }

  @override
  bool shouldRepaint(_WavyProgressPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
