/*
 *     Copyright (C) 2025 Valeri Gokadze
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

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/song_artwork.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key, required this.metadata});

  final MediaItem metadata;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  static const _playerHeight = 75.0;
  static const _progressBarHeight = 2.0;
  static const _artworkSize = 55.0;
  static const _artworkIconSize = 30.0;

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller for visual feedback
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                _buildPlayerBody(colorScheme),
                _buildProgressBar(colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerBody(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      height: _playerHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _ArtworkWidget(metadata: widget.metadata),
          _MetadataWidget(
            title: widget.metadata.title,
            artist: widget.metadata.artist,
            titleColor: colorScheme.primary,
            artistColor: colorScheme.secondary,
          ),
          _ControlsWidget(colorScheme: colorScheme),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final positionData =
            snapshot.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        final duration = positionData.duration;

        final progress = (positionData.position.inSeconds / duration.inSeconds)
            .clamp(0.0, 1.0);

        return LinearProgressIndicator(
          value: progress,
          minHeight: _progressBarHeight,
          backgroundColor: colorScheme.surfaceContainer,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        );
      },
    );
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    // Only navigate on upward swipe
    if (details.primaryDelta! < -10) {
      _navigateToNowPlaying();
    }
  }

  void _navigateToNowPlaying() {
    Navigator.push(context, _createSlideTransition());
  }

  PageRoute _createSlideTransition() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, _) => const NowPlayingPage(),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0, 1);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
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
          size: _MiniPlayerState._artworkSize,
          errorWidgetIconSize: _MiniPlayerState._artworkIconSize,
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
  const _ControlsWidget({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayPauseButton(colorScheme: colorScheme),
        _NextButton(colorScheme: colorScheme),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState.distinct((previous, current) {
        // Only rebuild if relevant state changes
        return previous.playing == current.playing &&
            previous.processingState == current.processingState;
      }),
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final processingState = playbackState?.processingState;
        final isPlaying = playbackState?.playing ?? false;

        Widget iconWidget;
        VoidCallback? onPressed;

        if (processingState == AudioProcessingState.loading ||
            processingState == AudioProcessingState.buffering) {
          iconWidget = SizedBox(
            width: 35,
            height: 35,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          );
          onPressed = null;
        } else {
          final iconData =
              isPlaying
                  ? FluentIcons.pause_24_filled
                  : FluentIcons.play_24_filled;

          iconWidget = Icon(iconData, color: colorScheme.primary, size: 35);

          onPressed = isPlaying ? audioHandler.pause : audioHandler.play;
        }

        return GestureDetector(
          onTap: onPressed,
          child: Container(padding: const EdgeInsets.all(4), child: iconWidget),
        );
      },
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaItem>>(
      stream: audioHandler.queue,
      builder: (context, snapshot) {
        final hasNext = audioHandler.hasNext;

        if (!hasNext) {
          return const SizedBox.shrink();
        }

        return Padding(
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
        );
      },
    );
  }
}
