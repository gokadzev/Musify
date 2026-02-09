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

class BottomSheetBar extends StatelessWidget {
  const BottomSheetBar(
    this.title,
    this.onTap,
    this.isSelected, {
    this.borderRadius = BorderRadius.zero,
    super.key,
  });
  final String title;
  final VoidCallback onTap;
  final bool isSelected;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    FluentIcons.checkmark_24_filled,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
