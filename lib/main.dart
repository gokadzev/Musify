import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/helper/version.dart';
import 'package:musify/services/audio_handler.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/rootPage.dart';
import 'package:musify/ui/searchPage.dart';
import 'package:package_info_plus/package_info_plus.dart';

GetIt getIt = GetIt.instance;

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static Future<void> setLocale(BuildContext context, Locale newLocale) async {
    final _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.changeLanguage(newLocale);
  }

  static Future<void> setAccentColor(
      BuildContext context, Color newAccentColor) async {
    final _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.changeAccentColor(newAccentColor);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void changeAccentColor(Color newAccentColor) {
    setState(() {
      accent = newAccentColor;
    });
  }

  @override
  void initState() {
    super.initState();
    final String lang =
        Hive.box('settings').get('language', defaultValue: 'English') as String;
    prefferedFileExtension.value = Hive.box('settings')
        .get('audioFileType', defaultValue: 'mp3') as String;
    accent = Hive.box('settings').get('accentColor') != null
        ? Color(Hive.box('settings').get('accentColor') as int)
        : const Color(0xFF8C9EFF);
    userPlaylists = Hive.box('user').get('playlists') ?? [];
    userLikedSongsList = Hive.box('user').get('likedSongs') ?? [];
    searchHistory = Hive.box('user').get('searchHistory') ?? [];
    final Map<String, String> codes = {
      'English': 'en',
      'Georgian': 'ka',
      'Chinese': 'zh',
      'Dutch': 'nl',
      'German': 'de',
      'Indonesian': 'id',
      'Italian': 'it',
      'Polish': 'pl',
      'Portuguese': 'pt',
      'Spanish': 'es',
      'Turkish': 'tr',
      'Ukrainian': 'uk',
    };
    _locale = Locale(codes[lang]!);
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: accent,
        scaffoldBackgroundColor: bgColor,
        canvasColor: bgColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.ubuntuTextTheme(Theme.of(context).textTheme),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ka', ''),
        Locale('zh', ''),
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
        Locale('ur', '')
      ],
      locale: _locale,
      home: Musify(),
    );
  }
}

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('user');
  await FlutterDownloader.initialize(
    debug:
        true, // optional: set to false to disable printing logs to console (default: true)
    ignoreSsl:
        true // option: set to false to disable working with http links (default: false)
    ,
  );
  FlutterDownloader.registerCallback(TestClass.callback);
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  version = packageInfo.version;
  await enableBooster();
  await initialisation();
  runApp(const MyApp());
}

Future<void> initialisation() async {
  final AudioHandler audioHandler = await AudioService.init(
    builder: MyAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'me.musify',
      androidNotificationChannelName: 'Musify',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
      androidShowNotificationBadge: true,
    ),
  );
  getIt.registerSingleton<AudioHandler>(audioHandler);
}

class TestClass {
  static void callback(String id, DownloadTaskStatus status, int progress) {}
}
