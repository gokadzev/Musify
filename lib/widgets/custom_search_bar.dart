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

class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({
    super.key,
    required this.onSubmitted,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    this.onChanged,
    this.loadingProgressNotifier,
  });
  final Function(String) onSubmitted;
  final ValueNotifier<bool>? loadingProgressNotifier;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final Function(String)? onChanged;

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: SearchBar(
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
        hintText: widget.labelText,
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
        onSubmitted: (String value) {
          widget.onSubmitted(value);
          widget.focusNode.unfocus();
        },
        onChanged: widget.onChanged != null
            ? (value) async {
                widget.onChanged!(value);
                setState(() {});
              }
            : null,
        textInputAction: TextInputAction.search,
        controller: widget.controller,
        focusNode: widget.focusNode,
        trailing: [
          if (widget.controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                FluentIcons.dismiss_24_regular,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                widget.controller.clear();
                widget.onChanged?.call('');
                setState(() {});
              },
            ),
          if (widget.loadingProgressNotifier != null)
            ValueListenableBuilder<bool>(
              valueListenable: widget.loadingProgressNotifier!,
              builder: (_, value, __) {
                if (value) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }
}
