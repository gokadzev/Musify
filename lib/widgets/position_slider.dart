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

PositionData _positionData = PositionData(
  Duration.zero,
  Duration.zero,
  Duration.zero,
);

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
    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream,
      builder: (context, snapshot) {
        if (snapshot.data != null && snapshot.data!.position.inSeconds > 0) {
          _positionData = snapshot.data!;
        }

        final maxDuration = _positionData.duration.inSeconds > 0
            ? _positionData.duration.inSeconds.toDouble()
            : 1.0;

        final currentValue = _isDragging
            ? _dragValue
            : _positionData.position.inSeconds.toDouble();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Slider(
              value: currentValue.clamp(0.0, maxDuration),
              onChanged: (value) {
                setState(() {
                  _isDragging = true;
                  _dragValue = value;
                });
              },
              onChangeEnd: (value) {
                audioHandler.seek(Duration(seconds: value.toInt()));
                setState(() {
                  _isDragging = false;
                });
              },
              max: maxDuration,
              semanticFormatterCallback: (value) =>
                  formatDuration(value.toInt()),
            ),
            _buildPositionRow(context, _positionData),
          ],
        );
      },
    );
  }

  static const _textStyle = TextStyle(fontSize: 15);

  Widget _buildPositionRow(BuildContext context, PositionData positionData) {
    final positionText = formatDuration(
      _isDragging ? _dragValue.toInt() : positionData.position.inSeconds,
    );
    final durationText = formatDuration(positionData.duration.inSeconds);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(positionText, style: _textStyle),
          Text(durationText, style: _textStyle),
        ],
      ),
    );
  }
}
