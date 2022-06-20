import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/helper/version.dart';
import 'package:musify/services/audio_handler.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/rootPage.dart';
import 'package:package_info_plus/package_info_plus.dart';

GetIt getIt = GetIt.instance;

main() async {
  await Hive.initFlutter();
  await FlutterDownloader.initialize(
    debug:
        true, // optional: set to false to disable printing logs to console (default: true)
    ignoreSsl:
        true // option: set to false to disable working with http links (default: false)
    ,
  );
  FlutterDownloader.registerCallback(TestClass.callback);
  accent = await getData("settings", "accentColor") != null
      ? Color(await getData("settings", "accentColor") as int)
      : const Color(0xFFFF9E80);
  userPlaylists = await getData("user", "playlists") ?? [];
  userLikedSongsList = await getData("user", "likedSongs") ?? [];
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  version = packageInfo.version;
  await enableBooster();
  initialisation();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      home: Musify(),
    );
  }
}

Future<void> initialisation() async {
  final AudioHandler audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'me.musify',
      androidNotificationChannelName: 'Musify',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/musify',
      androidShowNotificationBadge: true,
    ),
  );
  getIt.registerSingleton<AudioHandler>(audioHandler);
}

class TestClass {
  static void callback(String id, DownloadTaskStatus status, int progress) {}
}
