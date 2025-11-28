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

  static const double _playerHeight = 64;
  static const double _artworkSize = 48;
  static const double _artworkIconSize = 24;
  static const double _borderRadius = 16;

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
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onVerticalDragUpdate: _handleVerticalDrag,
            onTap: _navigateToNowPlaying,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(MiniPlayer._borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: MiniPlayer._playerHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                      child: Row(
                        children: [
                          _ArtworkWidget(
                            metadata: metadata,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(width: 12),
                          _MetadataWidget(
                            title: metadata.title,
                            artist: metadata.artist,
                            colorScheme: colorScheme,
                          ),
                          _ControlsWidget(
                            colorScheme: colorScheme,
                            playbackState: state.playbackState,
                            hasNext: widget.hasNext,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ProgressBar(colorScheme: colorScheme, progress: progress),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  const _ArtworkWidget({required this.metadata, required this.colorScheme});
  final MediaItem metadata;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'now_playing_artwork',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SongArtworkWidget(
          metadata: metadata,
          size: MiniPlayer._artworkSize,
          errorWidgetIconSize: MiniPlayer._artworkIconSize,
          borderRadius: 12,
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
    return Expanded(
      child: MarqueeWidget(
        manualScrollEnabled: false,
        animationDuration: const Duration(seconds: 8),
        backDuration: const Duration(seconds: 2),
        pauseDuration: const Duration(seconds: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

class _ControlsWidget extends StatelessWidget {
  const _ControlsWidget({
    required this.colorScheme,
    required this.playbackState,
    required this.hasNext,
  });

  final ColorScheme colorScheme;
  final PlaybackState playbackState;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayPauseButton(
          colorScheme: colorScheme,
          playbackState: playbackState,
        ),
        if (hasNext) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: audioHandler.skipToNext,
            icon: Icon(
              FluentIcons.next_24_filled,
              color: colorScheme.onSurfaceVariant,
            ),
            iconSize: 24,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.colorScheme,
    required this.playbackState,
  });

  final ColorScheme colorScheme;
  final PlaybackState playbackState;

  @override
  Widget build(BuildContext context) {
    final processingState = playbackState.processingState;
    final isPlaying = playbackState.playing;

    if (processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: isPlaying ? audioHandler.pause : audioHandler.play,
      icon: Icon(
        isPlaying ? FluentIcons.pause_24_filled : FluentIcons.play_24_filled,
        color: colorScheme.onPrimary,
      ),
      iconSize: 22,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(40, 40),
        fixedSize: const Size(40, 40),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.colorScheme, required this.progress});

  final ColorScheme colorScheme;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(MiniPlayer._borderRadius),
        bottomRight: Radius.circular(MiniPlayer._borderRadius),
      ),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 3,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }
}
