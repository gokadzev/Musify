import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/colorScheme.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/no_artwork_cube.dart';
import 'package:musify/widgets/playback_icon_button.dart';

class MiniPlayer extends StatelessWidget {
  MiniPlayer({super.key, required this.metadata});
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
        padding: const EdgeInsets.symmetric(horizontal: 18),
        height: 75,
        decoration: BoxDecoration(
          color: context.colorScheme.onSecondary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Row(
          children: <Widget>[
            _buildArtwork(),
            _buildMetadata(context.colorScheme.primary),
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                return buildPlaybackIconButton(
                  snapshot.data,
                  45,
                  context.colorScheme.primary,
                );
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
      child: metadata.artUri?.scheme == 'file'
          ? SizedBox(
              width: 55,
              height: 55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(metadata.extras?['artWorkPath'])),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: metadata.artUri.toString(),
                fit: BoxFit.cover,
                width: 55,
                height: 55,
                errorWidget: (context, url, error) => NullArtworkWidget(
                  iconSize: 30,
                  backgroundColor: context.colorScheme.secondary,
                  iconColor: context.colorScheme.surface,
                ),
              ),
            ),
    );
  }

  Widget _buildMetadata(Color fontColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MarqueeWidget(
              manualScrollEnabled: false,
              child: Text(
                metadata.title,
                style: TextStyle(
                  color: fontColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            MarqueeWidget(
              manualScrollEnabled: false,
              child: Text(
                metadata.artist.toString(),
                style: TextStyle(
                  color: fontColor,
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
