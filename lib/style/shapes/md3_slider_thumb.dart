import 'package:flutter/material.dart';

class Material3SliderThumb extends SliderComponentShape {
  const Material3SliderThumb({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 1.0,
    this.pressedElevation = 6.0,
    this.thumbWidth = 5.0,
    this.thumbHeight = 23.5,
    this.borderWidth = 1,
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
    canvas.drawRRect(
      borderRRect,
      Paint()..color = borderColor,
    );

    canvas.drawRRect(
      thumbRRect,
      Paint()..color = color,
    );
  }
}
