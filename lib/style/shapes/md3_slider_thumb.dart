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

import 'package:flutter/material.dart';

class Material3SliderThumb extends SliderComponentShape {
  const Material3SliderThumb({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 1.0,
    this.pressedElevation = 6.0,
    this.thumbWidth = 6.0,
    this.thumbHeight = 24,
    this.borderWidth = 2,
    this.borderColor = Colors.white,
  });

  final double enabledThumbRadius;
  final double? disabledThumbRadius;
  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;
  final double elevation;
  final double pressedElevation;
  final double thumbWidth;
  final double thumbHeight;
  final double borderWidth;
  final Color borderColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
      isEnabled ? enabledThumbRadius : _disabledThumbRadius,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    final color = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    ).evaluate(enableAnimation)!;

    final evaluatedElevation = Tween<double>(
      begin: elevation,
      end: pressedElevation,
    ).evaluate(activationAnimation);

    final thumbRect =
        Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight);
    final thumbRRect =
        RRect.fromRectAndRadius(thumbRect, const Radius.circular(4));

    if (evaluatedElevation > 0.0) {
      canvas.drawShadow(
        Path()..addRRect(thumbRRect),
        Colors.black,
        evaluatedElevation,
        true,
      );
    }

    final borderRect = Rect.fromCenter(
      center: center,
      width: thumbWidth + borderWidth * 2,
      height: thumbHeight + borderWidth * 2,
    );
    final borderRRect =
        RRect.fromRectAndRadius(borderRect, const Radius.circular(6));
    canvas
      ..drawRRect(
        borderRRect,
        Paint()..color = borderColor,
      )
      ..drawRRect(
        thumbRRect,
        Paint()..color = color,
      );
  }
}
