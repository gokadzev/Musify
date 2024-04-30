import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/main.dart';

Widget buildPlaybackIconButton(
  PlaybackState? playerState,
  double iconSize,
  Color iconColor,
  Color backgroundColor, {
  double elevation = 2,
  EdgeInsets padding = const EdgeInsets.all(15),
}) {
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
      icon = FluentIcons.arrow_counterclockwise_24_filled;
      onPressed = () => audioHandler.seek(Duration.zero);
      break;
    default:
      icon = playing != true
          ? FluentIcons.play_24_filled
          : FluentIcons.pause_24_filled;
      onPressed = playing != true ? audioHandler.play : audioHandler.pause;
  }

  return RawMaterialButton(
    elevation: elevation,
    onPressed: onPressed,
    fillColor: backgroundColor,
    splashColor: Colors.transparent,
    padding: padding,
    shape: const CircleBorder(),
    child: Padding(
      padding: const EdgeInsetsDirectional.all(10),
      child: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    ),
  );
}
