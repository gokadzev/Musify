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

final Stream<FullPlayerState> fullPlayerStateStream = Rx.combineLatest3(
  audioHandler.playbackStateStream.distinct(),
  audioHandler.queueStream.distinct(),
  audioHandler.positionDataStream,
  (PlaybackState state, List<MediaItem> queue, PositionData pos) =>
      FullPlayerState(playbackState: state, queue: queue, position: pos),
).debounceTime(const Duration(milliseconds: 100));

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static const double _playerHeight = 75;
  static const double _progressBarHeight = 2;
  static const double _artworkSize = 55;
  static const double _artworkIconSize = 30;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final metadata = mediaSnapshot.data;
        if (metadata == null) return const SizedBox.shrink();

        return StreamBuilder<FullPlayerState>(
          stream: fullPlayerStateStream,
          builder: (context, stateSnapshot) {
            final state = stateSnapshot.data;
            if (state == null) return const SizedBox.shrink();

            return _MiniPlayerBody(
              colorScheme: colorScheme,
              metadata: metadata,
              state: state,
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
  });

  final ColorScheme colorScheme;
  final MediaItem metadata;
  final FullPlayerState state;

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

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (details.primaryDelta! < -10) _navigateToNowPlaying();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  height: MiniPlayer._playerHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _ArtworkWidget(metadata: metadata),
                      _MetadataWidget(
                        title: metadata.title,
                        artist: metadata.artist,
                        titleColor: colorScheme.primary,
                        artistColor: colorScheme.secondary,
                      ),
                      _ControlsWidget(
                        colorScheme: colorScheme,
                        playbackState: state.playbackState,
                        hasNext: audioHandler.hasNext,
                      ),
                    ],
                  ),
                ),
                _ProgressBar(
                  colorScheme: colorScheme,
                  positionData: state.position,
                  duration: metadata.duration,
                ),
              ],
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
      padding: const EdgeInsets.only(top: 7, bottom: 7, right: 15),
      child: Hero(
        tag: 'now_playing_artwork',
        child: SongArtworkWidget(
          metadata: metadata,
          size: MiniPlayer._artworkSize,
          errorWidgetIconSize: MiniPlayer._artworkIconSize,
          borderRadius: 8,
        ),
      ),
    );
  }
}

class _MetadataWidget extends StatelessWidget {
  const _MetadataWidget({
    required this.title,
    required this.artist,
    required this.titleColor,
    required this.artistColor,
  });

  final String title;
  final String? artist;
  final Color titleColor;
  final Color artistColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: MarqueeWidget(
            manualScrollEnabled: false,
            animationDuration: const Duration(seconds: 8),
            backDuration: const Duration(seconds: 2),
            pauseDuration: const Duration(seconds: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (artist != null && artist!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    artist!,
                    style: TextStyle(
                      color: artistColor,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
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
        if (hasNext)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: GestureDetector(
              onTap: audioHandler.skipToNext,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  FluentIcons.next_24_filled,
                  color: colorScheme.primary,
                  size: 25,
                ),
              ),
            ),
          ),
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
      return Container(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 35,
          height: 35,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    final iconData =
        isPlaying ? FluentIcons.pause_24_filled : FluentIcons.play_24_filled;

    return GestureDetector(
      onTap: isPlaying ? audioHandler.pause : audioHandler.play,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(iconData, color: colorScheme.primary, size: 35),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.colorScheme,
    required this.positionData,
    required this.duration,
  });

  final ColorScheme colorScheme;
  final PositionData positionData;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final totalDuration = duration ?? Duration.zero;
    final progress =
        totalDuration.inMilliseconds == 0
            ? 0.0
            : (positionData.position.inMilliseconds /
                    totalDuration.inMilliseconds)
                .clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: progress,
      minHeight: MiniPlayer._progressBarHeight,
      backgroundColor: colorScheme.surfaceContainer,
      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
    );
  }
}
