import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/helper/version.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/locator.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/rootPage.dart';
import 'package:package_info_plus/package_info_plus.dart';

main() async {
  await Hive.initFlutter();
  await FlutterDownloader.initialize(
      debug:
          true, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          true // option: set to false to disable working with http links (default: false)
      );
  FlutterDownloader.registerCallback(TestClass.callback);
  accent = await getData("settings", "accentColor") != null
      ? Color(await getData("settings", "accentColor"))
      : Color(0xFFFF9E80);
  userPlaylists = await getData("user", "playlists") != null
      ? await getData("user", "playlists")
      : [];
  userLikedSongsList = await getData("user", "likedSongs") != null
      ? await getData("user", "likedSongs")
      : [];
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  version = packageInfo.version;
  await enableBooster();
  setupServiceLocator();
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

class TestClass {
  static void callback(String id, DownloadTaskStatus status, int progress) {}
}
