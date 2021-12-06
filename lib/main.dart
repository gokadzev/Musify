import 'package:flutter/material.dart';
import 'package:Musify/style/appColors.dart';
import 'package:Musify/ui/rootPage.dart';

main() async {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "DMSans",
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: accent),
        primaryColor: accent,
        canvasColor: Colors.transparent,
      ),
      home: Musify(),
    ),
  );
}
