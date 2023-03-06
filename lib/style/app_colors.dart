import 'package:flutter/material.dart';
import 'package:musify/style/app_themes.dart';

final availableColors = <Color>[
  const Color(0xFF9ACD32),
  const Color(0xFF00FA9A),
  const Color(0xFFF08080),
  const Color(0xFF6495ED),
  const Color(0xFFFFAFCC),
  const Color(0xFFC8B6FF),
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.pink,
  Colors.teal,
  Colors.lime,
  Colors.indigo,
  Colors.cyan,
  Colors.brown,
  Colors.amber,
  Colors.deepOrange,
  Colors.deepPurple,
];

MaterialColor getPrimarySwatch(Color color) {
  return MaterialColor(color.value, {
    50: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.1,
    ),
    100: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.2,
    ),
    200: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.3,
    ),
    300: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.4,
    ),
    400: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.5,
    ),
    500: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.6,
    ),
    600: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.7,
    ),
    700: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.8,
    ),
    800: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      0.9,
    ),
    900: Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      1,
    ),
  });
}

Color isAccentWhite() {
  return colorScheme.primary != const Color(0xFFFFFFFF)
      ? Colors.white
      : Colors.black;
}
