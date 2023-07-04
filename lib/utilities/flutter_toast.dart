import 'package:flutter/material.dart';
import 'package:musify/style/app_themes.dart';

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colorScheme.primary,

      content: Text(
        text,
        maxLines: null,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      duration: const Duration(seconds: 3), // Adjust the duration as needed
    ),
  );
}
