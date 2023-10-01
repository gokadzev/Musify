import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

final kBorderRadius = BorderRadius.circular(15);
const kContentPadding =
    EdgeInsets.only(left: 18, right: 20, top: 14, bottom: 14);

const darkModeBGColor = Color(0xFF121212);

Color primaryColor =
    Color(Hive.box('settings').get('accentColor', defaultValue: 0xFFC4A092));

ColorScheme colorScheme = ColorScheme.fromSeed(
  seedColor: primaryColor,
  primary: primaryColor,
).harmonized();

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
        fillColor: colorScheme.background.withAlpha(50),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: kBorderRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: kBorderRadius,
        ),
        contentPadding: kContentPadding,
      ),
    );

ThemeData getAppDarkTheme() {
  final base = ThemeData.dark();

  return commonProperties().copyWith(
    scaffoldBackgroundColor: darkModeBGColor,
    canvasColor: darkModeBGColor,
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: darkModeBGColor,
      iconTheme: IconThemeData(color: colorScheme.primary),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),
      elevation: 0,
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: darkModeBGColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: const Color(0xFF151515),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2.3,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      textColor: colorScheme.primary,
    ),
    switchTheme: base.switchTheme.copyWith(
      trackColor: MaterialStateProperty.all(colorScheme.primary),
    ),
    iconTheme: base.iconTheme.copyWith(
      color: Colors.white,
    ),
    hintColor: Colors.white,
    bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
      color: const Color(0xFF151515),
    ),
  );
}

ThemeData getAppLightTheme() {
  final base = ThemeData.light();
  return commonProperties().copyWith(
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
    bottomSheetTheme:
        base.bottomSheetTheme.copyWith(backgroundColor: colorScheme.surface),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: colorScheme.surface,
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
    cardTheme: base.cardTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2.3,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      selectedColor: colorScheme.primary.withOpacity(0.4),
      textColor: colorScheme.primary,
    ),
    switchTheme: base.switchTheme.copyWith(
      trackColor: MaterialStateProperty.all(colorScheme.primary),
    ),
    iconTheme: base.iconTheme.copyWith(color: colorScheme.primary),
    hintColor: colorScheme.primary.withOpacity(0.7),
    bottomAppBarTheme:
        base.bottomAppBarTheme.copyWith(color: colorScheme.surface),
  );
}

// Components

AppBarTheme mAppBarTheme() => AppBarTheme(
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),
      elevation: 0,
    );

final mCardTheme = CardTheme(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  ),
  elevation: 2.3,
);

final mInputDecorationTheme = InputDecorationTheme(
  filled: true,
  isDense: true,
  border: OutlineInputBorder(
    borderRadius: kBorderRadius,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: kBorderRadius,
  ),
  contentPadding: kContentPadding,
);

// builders

ThemeData buildLightTheme(ColorScheme lightColorScheme) {
  return getAppLightTheme().copyWith(
    scaffoldBackgroundColor: lightColorScheme.surface,
    colorScheme: lightColorScheme,
    canvasColor: lightColorScheme.surface,
    cardTheme: mCardTheme,
    bottomAppBarTheme: BottomAppBarTheme(color: lightColorScheme.surface),
    appBarTheme: mAppBarTheme().copyWith(
      backgroundColor: lightColorScheme.surface,
    ),
    inputDecorationTheme: mInputDecorationTheme,
  );
}

ThemeData buildDarkTheme(ColorScheme darkColorScheme) {
  return getAppDarkTheme().copyWith(
    scaffoldBackgroundColor: darkColorScheme.surface,
    colorScheme: darkColorScheme,
    canvasColor: darkColorScheme.surface,
    cardTheme: mCardTheme,
    bottomAppBarTheme: BottomAppBarTheme(color: darkColorScheme.surface),
    appBarTheme: mAppBarTheme().copyWith(
      backgroundColor: darkColorScheme.surface,
    ),
    inputDecorationTheme: mInputDecorationTheme,
  );
}
