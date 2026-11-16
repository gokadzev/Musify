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

import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/sort_utils.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: sortTypes.map((type) {
          final isSelected = currentSortType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(
                sortTypeToString(type),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              backgroundColor: colorScheme.surfaceContainerHigh,
              selectedColor: colorScheme.secondaryContainer,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

/// [SortChips] bound to the library-wide sort: it persists the pick, then
/// asks the hosting page to rebuild through [onSortChanged].
class LibrarySortChips extends StatelessWidget {
  const LibrarySortChips({required this.onSortChanged, super.key});

  final VoidCallback onSortChanged;

  @override
  Widget build(BuildContext context) {
    return SortChips<LibrarySortType>(
      currentSortType: currentLibrarySortType,
      sortTypes: LibrarySortType.values,
      sortTypeToString: (type) => switch (type) {
        LibrarySortType.default_ => context.l10n!.default_,
        LibrarySortType.nameAsc => context.l10n!.nameAscending,
        LibrarySortType.nameDesc => context.l10n!.nameDescending,
      },
      onSelected: (type) {
        addOrUpdateData<String>('settings', 'librarySortType', type.name);
        librarySortSetting = type.name;
        onSortChanged();
      },
    );
  }
}
