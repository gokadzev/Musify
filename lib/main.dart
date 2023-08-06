import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/root_page.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/audio_service.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/logger_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

bool _interrupted = false;
ThemeMode themeMode = ThemeMode.dark;
var isFdroidBuild = false;

final appLanguages = <String, String>{
  'English': 'en',
  'Arabic': 'ar',
  'Chinese': 'zh',
  'Dutch': 'nl',
  'French': 'fr',
  'Georgian': 'ka',
  'German': 'de',
  'Greek': 'el',
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

      primaryColor = newAccentColor;

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
    final themeModeSetting = settingsBox.get('themeMode') as String?;

    if (themeModeSetting != null && themeModeSetting != themeMode.name) {
      themeMode = getThemeMode(themeModeSetting);
    }

    GoogleFonts.config.allowRuntimeFetching = false;

    ReceiveSharingIntent.getTextStream().listen(
      (String? value) async {
        if (value == null) return;

        final regex = RegExp(r'(youtube\.com|youtu\.be)');
        if (!regex.hasMatch(value)) return;

        final songId = getSongId(value);
        if (songId == null) return;

        try {
          final song = await getSongDetails(0, songId);

          await playSong(song);
        } catch (e) {
          Logger.log('Error: $e');
        }
      },
      onError: (err) {
        Logger.log('getLinkStream error: $err');
      },
    );

    LicenseRegistry.addLicense(() async* {
      final license =
          await rootBundle.loadString('assets/fonts/roboto/LICENSE.txt');
      yield LicenseEntryWithLineBreaks(['google_fonts'], license);
      final license1 =
          await rootBundle.loadString('assets/fonts/paytone/OFL.txt');
      yield LicenseEntryWithLineBreaks(['google_fonts'], license1);
    });
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
        final lightTheme = lightColorScheme != null && useSystemColor.value
            ? buildLightTheme(lightColorScheme)
            : getAppLightTheme();

        final darkTheme = darkColorScheme != null && useSystemColor.value
            ? buildDarkTheme(darkColorScheme)
            : getAppDarkTheme();

        return MaterialApp(
          themeMode: themeMode,
          darkTheme: darkTheme,
          theme: lightTheme,
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

  FileDownloader().configureNotification(
    running: const TaskNotification('Downloading', 'file: {filename}'),
    complete: const TaskNotification('Download finished', 'file: {filename}'),
    progressBar: true,
  );
}
