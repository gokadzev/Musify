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
import 'package:musify/utilities/common_variables.dart';

typedef SortTypeToStringConverter<T> = String Function(T type);
typedef OnSortTypeSelected<T> = void Function(T type);

class SortButton<T extends Enum> extends StatelessWidget {
  const SortButton({
    required this.currentSortType,
    required this.sortTypes,
    required this.sortTypeToString,
    required this.onSelected,
    super.key,
  });

  final T currentSortType;
  final List<T> sortTypes;
  final SortTypeToStringConverter<T> sortTypeToString;
  final OnSortTypeSelected<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      offset: const Offset(0, 40),
      borderRadius: commonBarRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.filter_16_filled,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              sortTypeToString(currentSortType),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return sortTypes.map((type) {
          return PopupMenuItem<T>(
            value: type,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sortTypeToString(type),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: type == currentSortType
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (type == currentSortType)
                  Icon(
                    Icons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (type) {
        if (type == currentSortType) return;
        onSelected(type);
      },
    );
  }
}
