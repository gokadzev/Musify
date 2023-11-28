import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/style/app_themes.dart';

class MiniPlayer extends StatelessWidget {
  MiniPlayer({required this.metadata});
  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildExpandButton(context),
          _buildArtwork(),
          _buildMetadata(),
          const Spacer(),
          StreamBuilder<PlaybackState>(
            stream: audioHandler.playbackState,
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildPlaybackIconButton(snapshot.data),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      icon: Icon(
        FluentIcons.arrow_up_24_filled,
        size: 22,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NowPlayingPage(),
          ),
        );
      },
    );
  }

  Widget _buildArtwork() {
    return Padding(
      padding: const EdgeInsets.only(top: 7, bottom: 7, right: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: metadata.artUri.toString(),
          fit: BoxFit.cover,
          width: 55,
          height: 55,
          errorWidget: (context, url, error) => _buildNullArtworkWidget(),
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          _truncateText(metadata.title, 15),
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          _truncateText(metadata.artist.toString(), 15),
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  String _truncateText(String text, int maxLength) {
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;
  }
}

Widget _buildNullArtworkWidget() => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: colorScheme.secondary,
        ),
        child: const Center(
          child: Icon(
            FluentIcons.music_note_1_24_regular,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );

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

  return IconButton(
    icon: Icon(icon, color: colorScheme.primary),
    iconSize: 45,
    onPressed: onPressed,
    splashColor: Colors.transparent,
  );
}
