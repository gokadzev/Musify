import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/style/appTheme.dart';

void showToast(String text) {
  Fluttertoast.showToast(
    backgroundColor: getMaterialColorFromColor(accent),
    textColor: accent != getMaterialColorFromColor(const Color(0xFFFFFFFF))
        ? Colors.white
        : Colors.black,
    msg: text,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    fontSize: 14,
  );
}
