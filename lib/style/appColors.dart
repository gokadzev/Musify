import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

Color accent =
    Color(Hive.box('settings').get('accentColor', defaultValue: 0xFFFFFFFF));
Color accentLight = const Color(0xFFFFFFFF);
Color bgColor = const Color(0xFF121212);
Color bgLight = const Color(0xFF151515);
