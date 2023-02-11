import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:musify/screens/more_page.dart';
import 'package:musify/screens/root_page.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/style/app_colors.dart';
import 'package:musify/style/app_themes.dart';
import 'package:package_info_plus/package_info_plus.dart';

GetIt getIt = GetIt.instance;
late PackageInfo packageInfo;
bool _interrupted = false;
ThemeMode themeMode = ThemeMode.system;

final appLanguages = <String, String>{
  'English': 'en',
  'Georgian': 'ka',
  'Chinese': 'zh',
  'Traditional Chinese Taiwan': 'zh_TW',
  'Dutch': 'nl',
  'German': 'de',
  'Indonesian': 'id',
  'Italian': 'it',
  'Polish': 'pl',
  'Portuguese': 'pt',
  'Spanish': 'es',
  'Turkish': 'tr',
  'Ukrainian': 'uk',
  'Russian': 'ru',
};

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static Future<void> setThemeMode(
    BuildContext context,
    ThemeMode newThemeMode,
  ) async {
    final state = context.findAncestorStateOfType<_MyAppState>()!;
    state.changeTheme(newThemeMode);
  }

  static Future<void> setLocale(
    BuildContext context,
    Locale newLocale,
  ) async {
    final state = context.findAncestorStateOfType<_MyAppState>()!;
    state.changeLanguage(newLocale);
  }

  static Future<void> setAccentColor(
    BuildContext context,
    Color newAccentColor,
    bool systemColorStatus,
  ) async {
    final state = context.findAncestorStateOfType<_MyAppState>()!;
    state.changeAccentColor(newAccentColor, systemColorStatus);
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
      useSystemColor.value = systemColorStatus;
      accent = ColorScheme.fromSwatch(
        primarySwatch: getMaterialColorFromColor(
          newAccentColor,
        ),
        accentColor: newAccentColor,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _locale = Locale(
      appLanguages[Hive.box('settings').get('language', defaultValue: 'English')
          as String]!,
    );
    themeMode = Hive.box('settings').get('themeMode', defaultValue: 'system') ==
            'system'
        ? ThemeMode.system
        : Hive.box('settings').get('themeMode') == 'light'
            ? ThemeMode.light
            : ThemeMode.dark;
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
        if (lightColorScheme != null && useSystemColor.value == true) {
          accent = (themeMode == ThemeMode.light
              ? lightColorScheme
              : darkColorScheme)!;
        }
        return MaterialApp(
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          darkTheme: darkColorScheme != null && useSystemColor.value == true
              ? getAppDarkTheme().copyWith(
                  colorScheme: darkColorScheme,
                )
              : getAppDarkTheme(),
          theme: lightColorScheme != null && useSystemColor.value == true
              ? getAppLightTheme().copyWith(
                  colorScheme: lightColorScheme,
                )
              : getAppLightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('ka', ''),
            Locale.fromSubtags(languageCode: 'zh'),
            Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hant',
              countryCode: 'TW',
            ),
            Locale('nl', ''),
            Locale('fr', ''),
            Locale('de', ''),
            Locale('he', ''),
            Locale('hi', ''),
            Locale('hu', ''),
            Locale('id', ''),
            Locale('it', ''),
            Locale('pl', ''),
            Locale('pt', ''),
            Locale('es', ''),
            Locale('ta', ''),
            Locale('tr', ''),
            Locale('uk', ''),
            Locale('ur', ''),
            Locale('ru', '')
          ],
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
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('user');
  await Hive.openBox('cache');
  runApp(const MyApp());
}

Future<void> initialisation() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.gokadzev.musify',
    androidNotificationChannelName: 'Musify',
    androidNotificationIcon: 'mipmap/launcher_icon',
    androidShowNotificationBadge: true,
    androidStopForegroundOnPause: false,
  );

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  session.interruptionEventStream.listen((event) {
    if (event.begin) {
      if (audioPlayer.playing) {
        audioPlayer.pause();
        _interrupted = true;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.pause:
        case AudioInterruptionType.duck:
          if (!audioPlayer.playing && _interrupted) {
            audioPlayer.play();
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

  packageInfo = await PackageInfo.fromPlatform();

  try {
    await FlutterDownloader.initialize(
      debug: kDebugMode,
      ignoreSsl: true,
    );

    await FlutterDownloader.registerCallback(downloadCallback);
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }

  await checkAudioPerms();
}

@pragma('vm:entry-point')
void downloadCallback(String id, DownloadTaskStatus status, int progress) {}
