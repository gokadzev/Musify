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
import 'package:musify/extensions/l10n.dart';

class PlaylistSearchBar extends StatefulWidget {
  const PlaylistSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onCleared,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  State<PlaylistSearchBar> createState() => _PlaylistSearchBarState();
}

class _PlaylistSearchBarState extends State<PlaylistSearchBar> {
  final _controller = SearchController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: SearchBar(
        controller: _controller,
        hintText: context.l10n!.search,
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        backgroundColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHigh,
        ),
        overlayColor: WidgetStateProperty.all(
          colorScheme.primary.withValues(alpha: 0.08),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16),
        ),
        hintStyle: WidgetStateProperty.all(
          TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        leading: Icon(
          FluentIcons.search_24_regular,
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
        trailing: [
          if (widget.query.isNotEmpty)
            IconButton(
              icon: Icon(
                FluentIcons.dismiss_24_regular,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                _controller.clear();
                widget.onCleared();
              },
            ),
        ],
        onChanged: widget.onChanged,
      ),
    );
  }
}
