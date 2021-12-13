import 'package:musify/services/data_manager.dart';
import 'package:musify/services/locator.dart';
import 'package:musify/ui/rootPage.dart';
import 'package:flutter/material.dart';
import 'package:musify/style/appColors.dart';
import 'package:hive_flutter/hive_flutter.dart';

main() async {
  await Hive.initFlutter();
  accent = await getData("settings", "accentColor") != null
      ? Color(await getData("settings", "accentColor"))
      : Color(0xFFFFFFFF);
  setupServiceLocator();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: accent,
        scaffoldBackgroundColor: bgColor,
        canvasColor: bgColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Nunito',
      ),
      home: Musify(),
    ),
  );
}
