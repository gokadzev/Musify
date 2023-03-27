import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:musify/style/app_colors.dart';

Color primaryColor =
    Color(Hive.box('settings').get('accentColor', defaultValue: 0xFFF08080));

MaterialColor primarySwatch = getPrimarySwatch(primaryColor);

ColorScheme colorScheme = ColorScheme.fromSwatch(primarySwatch: primarySwatch);

final commonProperties = ThemeData(
  colorScheme: colorScheme.harmonized(),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  fontFamily: 'Ubuntu',
  useMaterial3: true,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    },
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.background.withAlpha(50),
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    contentPadding: const EdgeInsets.only(
      left: 18,
      right: 20,
      top: 14,
      bottom: 14,
    ),
  ),
);

ThemeData getAppDarkTheme() {
  return commonProperties.copyWith(
    scaffoldBackgroundColor: const Color(0xFF121212),
    canvasColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF121212),
      iconTheme: IconThemeData(color: colorScheme.primary),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF121212),
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
    listTileTheme: ListTileThemeData(textColor: colorScheme.primary),
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.all(colorScheme.primary),
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
  return commonProperties.copyWith(
    scaffoldBackgroundColor: Colors.white,
    canvasColor: Colors.white,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: colorScheme.primary),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),
      elevation: 0,
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
      selectedColor: colorScheme.primary.withOpacity(0.4),
      textColor: colorScheme.primary,
    ),
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.all(colorScheme.primary),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF151515)),
    hintColor: const Color(0xFF151515),
    bottomAppBarTheme: const BottomAppBarTheme(color: Colors.white),
  );
}
