import 'package:flutter/material.dart';

extension SizeExtension on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
}
