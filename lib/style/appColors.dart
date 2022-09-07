import 'package:flutter/material.dart';
import 'package:musify/style/appTheme.dart';

Color getShade(Color color, {bool darker = false, double value = .1}) {
  assert(value >= 0 && value <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness(
    (darker ? (hsl.lightness - value) : (hsl.lightness + value))
        .clamp(0.0, 1.0),
  );

  return hslDark.toColor();
}

MaterialColor getMaterialColorFromColor(Color color) {
  final _colorShades = <int, Color>{
    50: getShade(color, value: 0.5),
    100: getShade(color, value: 0.4),
    200: getShade(color, value: 0.3),
    300: getShade(color, value: 0.2),
    400: getShade(color, value: 0.1),
    500: color,
    600: getShade(color, value: 0.1, darker: true),
    700: getShade(color, value: 0.15, darker: true),
    800: getShade(color, value: 0.2, darker: true),
    900: getShade(color, value: 0.25, darker: true),
  };
  return MaterialColor(color.value, _colorShades);
}

Color isAccentWhite() {
  return accent != getMaterialColorFromColor(const Color(0xFFFFFFFF))
      ? Colors.white
      : Colors.black;
}
