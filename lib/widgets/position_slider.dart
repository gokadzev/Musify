/*
 *     Copyright (C) 2026 Valeri Gokadze
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

import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/utilities/formatter.dart';

class PositionSlider extends StatefulWidget {
  const PositionSlider({super.key});

  @override
  State<PositionSlider> createState() => _PositionSliderState();
}

class _PositionSliderState extends State<PositionSlider> {
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: StreamBuilder<PositionData>(
        stream: audioHandler.positionDataStream,
        builder: (context, snapshot) {
          final hasData = snapshot.hasData && snapshot.data != null;
          final positionData = hasData
              ? snapshot.data!
              : PositionData(Duration.zero, Duration.zero, Duration.zero);

          final maxDuration = positionData.duration.inSeconds > 0
              ? positionData.duration.inSeconds.toDouble()
              : 1.0;

          final currentValue = _isDragging
              ? _dragValue
              : positionData.position.inSeconds.toDouble();

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Slider(
                value: currentValue.clamp(0.0, maxDuration),
                onChanged: hasData
                    ? (value) {
                        setState(() {
                          _isDragging = true;
                          _dragValue = value;
                        });
                      }
                    : null,
                onChangeEnd: hasData
                    ? (value) {
                        audioHandler.seek(Duration(seconds: value.toInt()));
                        setState(() {
                          _isDragging = false;
                        });
                      }
                    : null,
                max: maxDuration,
              ),
              _buildPositionRow(context, primaryColor, positionData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPositionRow(
    BuildContext context,
    Color fontColor,
    PositionData positionData,
  ) {
    final positionText = formatDuration(positionData.position.inSeconds);
    final durationText = formatDuration(positionData.duration.inSeconds);
    final textStyle = TextStyle(fontSize: 15, color: fontColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(positionText, style: textStyle),
          Text(durationText, style: textStyle),
        ],
      ),
    );
  }
}
