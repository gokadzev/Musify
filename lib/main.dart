import 'package:Musify/services/data_manager.dart';
import 'package:Musify/services/locator.dart';
import 'package:Musify/ui/rootPage.dart';
import 'package:flutter/material.dart';
import 'package:Musify/style/appColors.dart';
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
