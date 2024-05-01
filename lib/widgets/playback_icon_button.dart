/*
 *     Copyright (C) 2024 Valeri Gokadze
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
