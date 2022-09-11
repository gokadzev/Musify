import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:musify/style/appColors.dart';

MaterialColor accent = getMaterialColorFromColor(
  Color(Hive.box('settings').get('accentColor', defaultValue: 0xFFF08080)),
);

ThemeData getAppDarkTheme() {
  return ThemeData(
    scaffoldBackgroundColor: const Color(0xFF121212),
    canvasColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212)),
    bottomAppBarColor: const Color(0xFF151515),
    splashColor: getMaterialColorFromColor(accent).shade400,
    primarySwatch: getMaterialColorFromColor(accent),
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
      color: const Color(0xFF151515),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2.3,
    ),
    listTileTheme: const ListTileThemeData(textColor: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
    hintColor: Colors.white,
    textTheme: const TextTheme(
      bodyText2: TextStyle(color: Colors.white),
    ),
  );
}

ThemeData getAppLightTheme() {
  return ThemeData(
    scaffoldBackgroundColor: Colors.white,
    canvasColor: Colors.white,
    primarySwatch: getMaterialColorFromColor(accent),
    bottomAppBarColor: getMaterialColorFromColor(accent).shade200,
    splashColor: getMaterialColorFromColor(accent).shade400,
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
    listTileTheme: ListTileThemeData(
      selectedColor: accent.withOpacity(0.4),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF151515)),
    hintColor: const Color(0xFF151515),
  );
}
