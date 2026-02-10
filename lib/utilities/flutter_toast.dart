/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

void showToast(
  BuildContext context,
  String text, {
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colorScheme.secondaryContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      elevation: 6,
      content: Row(
        children: [
          Icon(
            icon ?? FluentIcons.checkmark_circle_20_filled,
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: duration,
    ),
  );
}

void showToastWithButton(
  BuildContext context,
  String text,
  String buttonName,
  VoidCallback onPressedToast, {
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colorScheme.secondaryContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      content: Row(
        children: [
          Icon(
            icon ?? FluentIcons.info_20_filled,
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: buttonName,
        textColor: colorScheme.secondary,
        onPressed: () => onPressedToast(),
      ),
      persist: false,
      duration: duration,
    ),
  );
}
