import 'package:flutter/material.dart';
import 'package:Musify/style/appColors.dart';
import 'package:Musify/ui/homePage.dart';

main() async {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "DMSans",
        accentColor: accent,
        primaryColor: accent,
        canvasColor: Colors.transparent,
      ),
      home: Musify(),
    ),
  );
}
