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

import 'package:flutter/material.dart';

typedef SortTypeToStringConverter<T> = String Function(T type);
typedef OnSortTypeSelected<T> = void Function(T type);

class SortChips<T extends Enum> extends StatelessWidget {
  const SortChips({
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: sortTypes.map((type) {
          final isSelected = currentSortType == type;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(sortTypeToString(type)),
              onSelected: (_) {
                if (currentSortType == type) return;
                onSelected(type);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
