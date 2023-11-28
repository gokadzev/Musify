import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

Color primaryColor =
    Color(Hive.box('settings').get('accentColor', defaultValue: 0xff91cef4));

ColorScheme colorScheme = ColorScheme.fromSeed(
  seedColor: primaryColor,
  primary: primaryColor,
  brightness: brightness,
).harmonized();

ThemeMode themeMode = ThemeMode.dark;
Brightness brightness = Brightness.dark;

Brightness getBrightnessFromThemeMode(
  ThemeMode themeMode,
) {
  final themeBrightnessMapping = {
    ThemeMode.light: Brightness.light,
    ThemeMode.dark: Brightness.dark,
    ThemeMode.system:
        SchedulerBinding.instance.platformDispatcher.platformBrightness,
  };

  return themeBrightnessMapping[themeMode] ?? Brightness.dark;
}

ThemeMode getThemeMode(String themeModeString) {
  switch (themeModeString) {
    case 'system':
      return ThemeMode.system;
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

ThemeData commonProperties() => ThemeData(
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        contentPadding: const EdgeInsets.fromLTRB(18, 14, 20, 14),
      ),
    );

ThemeData getAppDarkTheme() {
  final base = ThemeData.dark();

  return commonProperties().copyWith(
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
    appBarTheme: base.appBarTheme.copyWith(
      iconTheme: IconThemeData(color: colorScheme.primary),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
      elevation: 0,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      selectedColor: colorScheme.primary.withOpacity(0.4),
      textColor: colorScheme.primary,
    ),
    hintColor: Colors.white,
  );
}

ThemeData getAppLightTheme() {
  final base = ThemeData.light();
  return commonProperties().copyWith(
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
    bottomSheetTheme:
        base.bottomSheetTheme.copyWith(backgroundColor: colorScheme.surface),
    appBarTheme: base.appBarTheme.copyWith(
      iconTheme: IconThemeData(color: colorScheme.primary),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
      elevation: 0,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      selectedColor: colorScheme.primary.withOpacity(0.4),
      textColor: colorScheme.primary,
    ),
    hintColor: colorScheme.primary.withOpacity(0.7),
  );
}
