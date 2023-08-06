import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

final kBorderRadius = BorderRadius.circular(15);
const kContentPadding =
    EdgeInsets.only(left: 18, right: 20, top: 14, bottom: 14);

const darkModeBGColor = Color(0xFF121212);
const lightModeBGColor = Color(0xFFE5E5E5);

Color primaryColor =
    Color(Hive.box('settings').get('accentColor', defaultValue: 0xFFE9967A));

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
      colorScheme: colorScheme.harmonized(),
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
  return commonProperties().copyWith(
    scaffoldBackgroundColor: darkModeBGColor,
    canvasColor: darkModeBGColor,
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    appBarTheme: ThemeData.dark().appBarTheme.copyWith(
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
    bottomSheetTheme: ThemeData.dark()
        .bottomSheetTheme
        .copyWith(backgroundColor: darkModeBGColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
    cardTheme: ThemeData.dark().cardTheme.copyWith(
          color: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2.3,
        ),
    listTileTheme:
        ThemeData.dark().listTileTheme.copyWith(textColor: colorScheme.primary),
    switchTheme: ThemeData.dark()
        .switchTheme
        .copyWith(trackColor: MaterialStateProperty.all(colorScheme.primary)),
    iconTheme: ThemeData.dark().iconTheme.copyWith(color: Colors.white),
    hintColor: Colors.white,
    bottomAppBarTheme: ThemeData.dark()
        .bottomAppBarTheme
        .copyWith(color: const Color(0xFF151515)),
  );
}

ThemeData getAppLightTheme() {
  return commonProperties().copyWith(
    scaffoldBackgroundColor: lightModeBGColor,
    canvasColor: lightModeBGColor,
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
    bottomSheetTheme: ThemeData.light()
        .bottomSheetTheme
        .copyWith(backgroundColor: lightModeBGColor),
    appBarTheme: ThemeData.light().appBarTheme.copyWith(
          backgroundColor: lightModeBGColor,
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
    cardTheme: ThemeData.light().cardTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2.3,
        ),
    listTileTheme: ThemeData.light().listTileTheme.copyWith(
          selectedColor: colorScheme.primary.withOpacity(0.4),
          textColor: colorScheme.primary,
        ),
    switchTheme: ThemeData.light().switchTheme.copyWith(
          trackColor: MaterialStateProperty.all(colorScheme.primary),
        ),
    iconTheme:
        ThemeData.light().iconTheme.copyWith(color: const Color(0xFF151515)),
    hintColor: const Color(0xFF151515),
    bottomAppBarTheme:
        ThemeData.light().bottomAppBarTheme.copyWith(color: lightModeBGColor),
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
    colorScheme: lightColorScheme.harmonized(),
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
    colorScheme: darkColorScheme.harmonized(),
    canvasColor: darkColorScheme.surface,
    cardTheme: mCardTheme,
    bottomAppBarTheme: BottomAppBarTheme(color: darkColorScheme.surface),
    appBarTheme: mAppBarTheme().copyWith(
      backgroundColor: darkColorScheme.surface,
    ),
    inputDecorationTheme: mInputDecorationTheme,
  );
}
