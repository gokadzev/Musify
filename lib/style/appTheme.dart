import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

Color accent =
    Color(Hive.box('settings').get('accentColor', defaultValue: 0xFFFFFFFF));
Color accentLight = const Color(0xFFFFFFFF);
Color bgColor = const Color(0xFF121212);
Color bgLight = const Color(0xFF151515);

final lightTheme = ThemeData(
  scaffoldBackgroundColor: Colors.white,
  canvasColor: Colors.white,
  appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
  colorSchemeSeed: accent,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  fontFamily: 'Ubuntu',
  useMaterial3: true,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
    },
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  ),
  cardTheme: CardTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 2.3,
  ),
);

final darkTheme = ThemeData(
  scaffoldBackgroundColor: bgColor,
  canvasColor: bgColor,
  appBarTheme: AppBarTheme(backgroundColor: bgColor),
  colorSchemeSeed: accent,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  fontFamily: 'Ubuntu',
  useMaterial3: true,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
    },
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  ),
  cardTheme: CardTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 2.3,
  ),
);
