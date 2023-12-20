import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/no_artwork_cube.dart';

class MiniPlayer extends StatelessWidget {
  MiniPlayer({required this.metadata});
  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    var _isHandlingSwipe = false;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NowPlayingPage(),
            ),
          );
        }
      },
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta! > 0) {
          if (!_isHandlingSwipe) {
            _isHandlingSwipe = true;
            audioHandler.skipToPrevious().whenComplete(() {
              _isHandlingSwipe = false;
            });
          }
        } else if (details.primaryDelta! < 0) {
          if (!_isHandlingSwipe) {
            _isHandlingSwipe = true;
            audioHandler.skipToNext().whenComplete(() {
              _isHandlingSwipe = false;
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 75,
        decoration: BoxDecoration(
          color: colorScheme.onSecondary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Row(
          children: <Widget>[
            _buildArtwork(),
            _buildMetadata(),
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                return _buildPlaybackIconButton(snapshot.data);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    return Padding(
      padding: const EdgeInsets.only(top: 7, bottom: 7, right: 15),
      child:
          metadata.extras?['isOffline'] != null && metadata.extras?['isOffline']
              ? SizedBox(
                  width: 55,
                  height: 55,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(metadata.artUri.toString())),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: metadata.artUri.toString(),
                  fit: BoxFit.cover,
                  width: 55,
                  height: 55,
                  errorWidget: (context, url, error) => const NullArtworkWidget(
                    iconSize: 30,
                  ),
                  imageBuilder: (context, imageProvider) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: imageProvider,
                        centerSlice: const Rect.fromLTRB(1, 1, 1, 1),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildMetadata() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MarqueeWidget(
              child: Text(
                metadata.title,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            MarqueeWidget(
              child: Text(
                metadata.artist.toString(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildPlaybackIconButton(PlaybackState? playerState) {
  final processingState = playerState?.processingState;
  final playing = playerState?.playing;

  IconData icon;
  VoidCallback? onPressed;

  if (processingState == AudioProcessingState.loading ||
      processingState == AudioProcessingState.buffering) {
    icon = FluentIcons.spinner_ios_16_filled;
    onPressed = null;
  } else if (playing != true) {
    icon = FluentIcons.play_12_filled;
    onPressed = audioHandler.play;
  } else if (processingState != AudioProcessingState.completed) {
    icon = FluentIcons.pause_12_filled;
    onPressed = audioHandler.pause;
  } else {
    icon = FluentIcons.replay_20_filled;
    onPressed = () => audioHandler.seek(Duration.zero);
  }

  return InkWell(
    onTap: onPressed,
    splashColor: Colors.transparent,
    child: Icon(
      icon,
      color: colorScheme.primary,
      size: 40,
    ),
  );
}
