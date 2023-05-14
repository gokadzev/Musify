import 'package:flutter/material.dart';
import 'package:musify/style/app_themes.dart';

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colorScheme.primary,

      content: Text(
        text,
        maxLines: null,
        style: TextStyle(
          color: colorScheme.primary != const Color(0xFFFFFFFF)
              ? Colors.white
              : Colors.black,
        ),
      ),
      duration: const Duration(seconds: 3), // Adjust the duration as needed
    ),
  );
}
