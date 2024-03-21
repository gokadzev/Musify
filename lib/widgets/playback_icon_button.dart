import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/main.dart';

Widget buildPlaybackIconButton(
  PlaybackState? playerState,
  double iconSize,
  Color iconColor,
) {
  final processingState = playerState?.processingState;
  final playing = playerState?.playing;

  IconData icon;
  VoidCallback? onPressed;

  switch (processingState) {
    case AudioProcessingState.buffering || AudioProcessingState.loading:
      icon = FluentIcons.spinner_ios_16_filled;
      onPressed = null;
      break;
    case AudioProcessingState.completed:
      icon = FluentIcons.replay_20_filled;
      onPressed = () => audioHandler.seek(Duration.zero);
      break;
    default:
      icon = playing != true
          ? FluentIcons.play_circle_24_filled
          : FluentIcons.pause_circle_24_filled;
      onPressed = playing != true ? audioHandler.play : audioHandler.pause;
  }

  return InkWell(
    onTap: onPressed,
    splashColor: Colors.transparent,
    child: Icon(
      icon,
      color: iconColor,
      size: iconSize,
    ),
  );
}
