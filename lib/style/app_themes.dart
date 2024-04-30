import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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

ThemeData getAppTheme(ColorScheme colorScheme) {
  final base = colorScheme.brightness == Brightness.light
      ? ThemeData.light()
      : ThemeData.dark();

  return ThemeData(
    colorScheme: colorScheme,
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
      textColor: colorScheme.primary,
      iconColor: colorScheme.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 20, 14),
    ),
    sliderTheme: const SliderThemeData(trackHeight: 1.8),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

void setSystemUIOverlayStyle(Brightness iconsBrightness) {
  // Some people said that Colors.transparent causes some issues, so better to use it this way
  final trickyFixForTransparency = Colors.black.withOpacity(0.002);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemStatusBarContrastEnforced: true,
      systemNavigationBarColor: trickyFixForTransparency,
      systemNavigationBarDividerColor: trickyFixForTransparency,
      systemNavigationBarIconBrightness: iconsBrightness,
      statusBarIconBrightness: iconsBrightness,
    ),
  );
}
