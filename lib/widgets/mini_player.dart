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
import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/models/full_player_state.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/song_artwork.dart';
import 'package:rxdart/rxdart.dart';

final Stream<FullPlayerState> _fullPlayerStateStream = Rx.combineLatest3(
  audioHandler.playbackState.distinct(),
  audioHandler.queue.distinct(),
  audioHandler.positionDataStream,
  (PlaybackState state, List<MediaItem> queue, PositionData pos) =>
      FullPlayerState(playbackState: state, queue: queue, position: pos),
).debounceTime(const Duration(milliseconds: 100)).asBroadcastStream();

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static const double playerHeight = 72;
  static const double _horizontalMargin = 12;
  static const double _bottomMargin = 8;
  static const double _borderRadius = 20;
  static const double _artworkSize = 52;
  static const double _artworkRadius = 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final metadata = mediaSnapshot.data;
        if (metadata == null) return const SizedBox.shrink();

        return StreamBuilder<FullPlayerState>(
          stream: _fullPlayerStateStream,
          builder: (context, stateSnapshot) {
            final state = stateSnapshot.data;
            if (state == null) return const SizedBox.shrink();

            final hasNext =
                state.queue.length > 1 &&
                (state.playbackState.queueIndex ?? 0) < state.queue.length - 1;

            return _MiniPlayerBody(
              colorScheme: colorScheme,
              metadata: metadata,
              state: state,
              hasNext: hasNext,
            );
          },
        );
      },
    );
  }
}

class _MiniPlayerBody extends StatefulWidget {
  const _MiniPlayerBody({
    required this.colorScheme,
    required this.metadata,
    required this.state,
    required this.hasNext,
  });

  final ColorScheme colorScheme;
  final MediaItem metadata;
  final FullPlayerState state;
  final bool hasNext;

  @override
  State<_MiniPlayerBody> createState() => _MiniPlayerBodyState();
}

class _MiniPlayerBodyState extends State<_MiniPlayerBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  static const double _dragThresholdForNavigation = 10;

  void _handleVerticalDrag(DragUpdateDetails details) {
    if ((details.primaryDelta ?? 0) < -_dragThresholdForNavigation) {
      _navigateToNowPlaying();
    }
  }

  void _navigateToNowPlaying() {
    Navigator.of(context).push(_createSlideTransition());
  }

  PageRoute<void> _createSlideTransition() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, _) => const NowPlayingPage(),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final metadata = widget.metadata;
    final state = widget.state;

    final totalDuration = metadata.duration ?? Duration.zero;
    final progress = totalDuration.inMilliseconds == 0
        ? 0.0
        : (state.position.position.inMilliseconds /
                  totalDuration.inMilliseconds)
              .clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MiniPlayer._horizontalMargin,
              0,
              MiniPlayer._horizontalMargin,
              MiniPlayer._bottomMargin,
            ),
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              onVerticalDragUpdate: _handleVerticalDrag,
              onTap: _navigateToNowPlaying,
              child: Container(
                height: MiniPlayer.playerHeight,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(MiniPlayer._borderRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        _ArtworkWidget(metadata: metadata),
                        Expanded(
                          child: _MetadataWidget(
                            title: metadata.title,
                            artist: metadata.artist,
                            colorScheme: colorScheme,
                          ),
                        ),
                        _ControlsWidget(
                          colorScheme: colorScheme,
                          playbackState: state.playbackState,
                          hasNext: widget.hasNext,
                          progress: progress,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  const _ArtworkWidget({required this.metadata});
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
                color: Colors.black.withValues(alpha: 0.1),
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

class _MetadataWidget extends StatelessWidget {
  const _MetadataWidget({
    required this.title,
    required this.artist,
    required this.colorScheme,
  });

  final String title;
  final String? artist;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                color: colorScheme.secondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (artist != null && artist!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              artist!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlsWidget extends StatelessWidget {
  const _ControlsWidget({
    required this.colorScheme,
    required this.playbackState,
    required this.hasNext,
    required this.progress,
  });

  final ColorScheme colorScheme;
  final PlaybackState playbackState;
  final bool hasNext;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircularPlayButton(
          colorScheme: colorScheme,
          playbackState: playbackState,
          progress: progress,
        ),
        if (hasNext) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: audioHandler.skipToNext,
            icon: Icon(
              FluentIcons.next_24_filled,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}

class _CircularPlayButton extends StatelessWidget {
  const _CircularPlayButton({
    required this.colorScheme,
    required this.playbackState,
    required this.progress,
  });

  final ColorScheme colorScheme;
  final PlaybackState playbackState;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final processingState = playbackState.processingState;
    final isPlaying = playbackState.playing;
    final isLoading =
        processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering;
    final isCompleted = processingState == AudioProcessingState.completed;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(48, 48),
            painter: _CircularProgressPainter(
              progress: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              progressColor: colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          else
            IconButton(
              onPressed: isCompleted
                  ? () => audioHandler.seek(Duration.zero)
                  : (isPlaying ? audioHandler.pause : audioHandler.play),
              icon: Icon(
                isCompleted
                    ? FluentIcons.arrow_counterclockwise_24_filled
                    : (isPlaying
                          ? FluentIcons.pause_16_filled
                          : FluentIcons.play_16_filled),
                color: colorScheme.primary,
                size: 22,
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
