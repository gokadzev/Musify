import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/locator.dart';
import 'package:musify/ui/rootPage.dart';
import 'package:flutter/material.dart';
import 'package:musify/style/appColors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

main() async {
  await Hive.initFlutter();
  accent = await getData("settings", "accentColor") != null
      ? Color(await getData("settings", "accentColor"))
      : Color(0xFFFF9E80);
  userPlaylists = await getData("user", "playlists") != null
      ? await getData("user", "playlists")
      : [];
  userLikedSongs = await await getData("user", "likedSongs") != null
      ? await getData("user", "likedSongs")
      : [];
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
          pageTransitionsTheme: PageTransitionsTheme(builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          })),
      home: Musify(),
    );
  }
}
