import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playback_icon_button.dart';
import 'package:musify/widgets/song_artwork.dart';

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
      onHorizontalDragUpdate: audioHandler.hasNext
          ? (details) {
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
            }
          : null,
      child: Container(
        padding: const EdgeInsets.only(left: 18),
        height: 75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Row(
          children: <Widget>[
            _buildArtwork(),
            _buildMetadata(Theme.of(context).colorScheme.primary),
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                return buildPlaybackIconButton(
                  snapshot.data,
                  30,
                  Theme.of(context).colorScheme.primary,
                  Colors.transparent,
                  elevation: 0,
                  padding: EdgeInsets.zero,
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
      child: SongArtworkWidget(
        metadata: metadata,
        size: 55,
        borderRadius: 12,
        errorWidgetIconSize: 30,
      ),
    );
  }

  Widget _buildMetadata(Color fontColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: MarqueeWidget(
            manualScrollEnabled: false,
            child: Text(
              metadata.artist != null
                  ? '${metadata.artist} - ${metadata.title}'
                  : metadata.title,
              style: TextStyle(
                color: fontColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
