import 'package:flutter/material.dart';

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(context).colorScheme.primary,

      content: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      duration: const Duration(seconds: 3), // Adjust the duration as needed
    ),
  );
}

void showToastWithButton(
  BuildContext context,
  String text,
  String buttonName,
  VoidCallback onPressedToast,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(context).colorScheme.primary,

      content: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      action:
          SnackBarAction(label: buttonName, onPressed: () => onPressedToast()),
      duration: const Duration(seconds: 3), // Adjust the duration as needed
    ),
  );
}
