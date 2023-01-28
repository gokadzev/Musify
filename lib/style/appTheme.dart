import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:musify/style/appColors.dart';

ColorScheme accent = ColorScheme.fromSwatch(
  primarySwatch: getMaterialColorFromColor(
    Color(Hive.box('settings').get('accentColor', defaultValue: 0xFFF08080)),
  ),
  accentColor:
      Color(Hive.box('settings').get('accentColor', defaultValue: 0xFFF08080)),
);

ThemeData getAppDarkTheme() {
  return ThemeData(
    scaffoldBackgroundColor: const Color(0xFF121212),
    canvasColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF121212),
      iconTheme: IconThemeData(color: accent.primary),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF121212),
    ),
    colorScheme: accent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Ubuntu',
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
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
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.all(accent.primary),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    hintColor: Colors.white,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
    bottomAppBarTheme: const BottomAppBarTheme(color: Color(0xFF151515)),
  );
}

ThemeData getAppLightTheme() {
  return ThemeData(
    scaffoldBackgroundColor: Colors.white,
    canvasColor: Colors.white,
    colorScheme: accent,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: accent.primary),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Ubuntu',
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
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
      selectedColor: accent.primary.withOpacity(0.4),
    ),
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.all(accent.primary),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF151515)),
    hintColor: const Color(0xFF151515),
    bottomAppBarTheme: const BottomAppBarTheme(color: Colors.white),
  );
}
