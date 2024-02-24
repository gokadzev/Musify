import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musify/services/settings_manager.dart';

ThemeMode themeMode = getThemeMode(themeModeSetting);
Brightness brightness = getBrightnessFromThemeMode(themeMode);

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

ThemeData getAppDarkTheme(ColorScheme colorScheme) {
  final base = ThemeData.dark();

  return ThemeData(
    colorScheme: colorScheme,
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 20, 14),
      // suffixIconColor: colorScheme.onSurface,
    ),
    hintColor: Colors.white,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

ThemeData getAppLightTheme(ColorScheme colorScheme) {
  final base = ThemeData.light();
  return ThemeData(
    colorScheme: colorScheme,
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 20, 14),
    ),
    hintColor: colorScheme.primary.withOpacity(0.7),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
