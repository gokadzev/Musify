import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/style/app_themes.dart';

Widget buildPlaybackIconButton(PlaybackState? playerState, double size) {
  final processingState = playerState?.processingState;
  final playing = playerState?.playing;

  IconData icon;
  VoidCallback? onPressed;

  if (processingState == AudioProcessingState.loading ||
      processingState == AudioProcessingState.buffering) {
    icon = FluentIcons.spinner_ios_16_filled;
    onPressed = null;
  } else if (playing != true) {
    icon = FluentIcons.play_circle_24_filled;
    onPressed = audioHandler.play;
  } else if (processingState != AudioProcessingState.completed) {
    icon = FluentIcons.pause_circle_24_filled;
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
      size: size,
    ),
  );
}
