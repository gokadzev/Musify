import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musify/style/appTheme.dart';

void showToast(String text) {
  Fluttertoast.showToast(
    backgroundColor: accent,
    textColor: accent != const Color(0xFFFFFFFF) ? Colors.white : Colors.black,
    msg: text,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    fontSize: 14,
  );
}
