import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/root_page.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/audio_service.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

bool _interrupted = false;
ThemeMode themeMode = ThemeMode.dark;
var isFdroidBuild = false;
var logger = Logger();

final appLanguages = <String, String>{
  'English': 'en',
  'Arabic': 'ar',
  'Chinese': 'zh',
  'Dutch': 'nl',
  'Georgian': 'ka',
  'German': 'de',
  'Indonesian': 'id',
  'Italian': 'it',
  'Polish': 'pl',
  'Portuguese': 'pt',
  'Russian': 'ru',
  'Spanish': 'es',
  'Traditional Chinese Taiwan': 'zh_TW',
  'Turkish': 'tr',
  'Ukrainian': 'uk',
  'Vietnamese': 'vi',
};

final appSupportedLocales = appLanguages.values
    .map((languageCode) => Locale.fromSubtags(languageCode: languageCode))
    .toList();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static Future<void> updateAppState(
    BuildContext context, {
    ThemeMode? newThemeMode,
    Locale? newLocale,
    Color? newAccentColor,
    bool? useSystemColor,
  }) async {
    final state = context.findAncestorStateOfType<_MyAppState>()!;
    if (newThemeMode != null) {
      state.changeTheme(newThemeMode);
    }
    if (newLocale != null) {
      state.changeLanguage(newLocale);
    }
    if (newAccentColor != null && useSystemColor != null) {
      state.changeAccentColor(newAccentColor, useSystemColor);
    }
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');

  void changeTheme(ThemeMode newThemeMode) {
    setState(() {
      themeMode = newThemeMode;
    });
  }

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void changeAccentColor(Color newAccentColor, bool systemColorStatus) {
    setState(() {
      if (useSystemColor.value != systemColorStatus) {
        useSystemColor.value = systemColorStatus;

        addOrUpdateData(
          'settings',
          'useSystemColor',
          systemColorStatus,
        );
      }

      colorScheme = ColorScheme.fromSeed(
        seedColor: newAccentColor,
        primary: newAccentColor,
      ).harmonized();
    });
  }

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box('settings');
    final language =
        settingsBox.get('language', defaultValue: 'English') as String;
    _locale = Locale(appLanguages[language] ?? 'en');
    final themeModeSetting =
        settingsBox.get('themeMode', defaultValue: 'system') as String;
    themeMode = themeModeSetting == 'system'
        ? ThemeMode.system
        : themeModeSetting == 'light'
            ? ThemeMode.light
            : ThemeMode.dark;

    ReceiveSharingIntent.getTextStream().listen(
      (String? value) async {
        if (value == null) return;

        final regex = RegExp(r'(youtube\.com|youtu\.be)');
        if (!regex.hasMatch(value)) return;

        final songId = getSongId(value);
        if (songId == null) return;

        try {
          final song = await getSongDetails(0, songId);
          if (song == null) return;

          await playSong(song);
        } catch (e) {
          logger.e('Error: $e');
        }
      },
      onError: (err) {
        logger.e('getLinkStream error: $err');
      },
    );
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        if (lightColorScheme != null &&
            darkColorScheme != null &&
            useSystemColor.value) {
          colorScheme =
              themeMode == ThemeMode.light ? lightColorScheme : darkColorScheme;
        }

        return MaterialApp(
          themeMode: themeMode,
          debugShowCheckedModeBanner: kDebugMode,
          darkTheme: darkColorScheme != null && useSystemColor.value
              ? getAppDarkTheme().copyWith(
                  scaffoldBackgroundColor: darkColorScheme.surface,
                  colorScheme: darkColorScheme.harmonized(),
                  canvasColor: darkColorScheme.surface,
                  cardTheme: mCardTheme,
                  bottomAppBarTheme: BottomAppBarTheme(
                    color: darkColorScheme.surface,
                  ),
                  appBarTheme: mAppBarTheme().copyWith(
                    backgroundColor: darkColorScheme.surface,
                  ),
                  inputDecorationTheme: mInputDecorationTheme,
                )
              : getAppDarkTheme(),
          theme: lightColorScheme != null && useSystemColor.value
              ? getAppLightTheme().copyWith(
                  scaffoldBackgroundColor: lightColorScheme.surface,
                  colorScheme: lightColorScheme.harmonized(),
                  canvasColor: lightColorScheme.surface,
                  cardTheme: mCardTheme,
                  bottomAppBarTheme: BottomAppBarTheme(
                    color: lightColorScheme.surface,
                  ),
                  appBarTheme: mAppBarTheme().copyWith(
                    backgroundColor: lightColorScheme.surface,
                  ),
                  inputDecorationTheme: mInputDecorationTheme,
                )
              : getAppLightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: appSupportedLocales,
          locale: _locale,
          home: Musify(),
        );
      },
    );
  }
}

void main() async {
  await initialisation();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

Future<void> initialisation() async {
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('user');
  await Hive.openBox('cache');

  await FlutterDisplayMode.setHighRefreshRate();

  audioHandler = await AudioService.init(
    builder: MyAudioHandler.new,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.gokadzev.musify',
      androidNotificationChannelName: 'Musify',
      androidNotificationIcon: 'mipmap/launcher_icon',
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: !foregroundService.value,
    ),
  );

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  session.interruptionEventStream.listen((event) {
    if (event.begin) {
      if (audioPlayer.playing) {
        audioHandler.pause();
        _interrupted = true;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.pause:
        case AudioInterruptionType.duck:
          if (!audioPlayer.playing && _interrupted) {
            audioHandler.play();
          }
          break;
        case AudioInterruptionType.unknown:
          break;
      }
      _interrupted = false;
    }
  });
  activateListeners();
  await enableBooster();

  try {
    await FlutterDownloader.initialize(
      debug: kDebugMode,
      ignoreSsl: true,
    );

    await FlutterDownloader.registerCallback(downloadCallback);
  } catch (e) {
    logger.e('error while initializing Flutter Downloader plugin $e');
  }
}

@pragma('vm:entry-point')
void downloadCallback(String id, DownloadTaskStatus status, int progress) {}
