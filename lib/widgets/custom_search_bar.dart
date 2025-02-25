/*
 *     Copyright (C) 2025 Valeri Gokadze
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
import 'package:musify/widgets/spinner.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 3),
      child: SearchBar(
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        hintText: widget.labelText,
        onSubmitted: (String value) {
          widget.onSubmitted(value);
          widget.focusNode.unfocus();
        },
        onChanged:
            widget.onChanged != null
                ? (value) async {
                  widget.onChanged!(value);

                  setState(() {});
                }
                : null,
        textInputAction: TextInputAction.search,
        controller: widget.controller,
        focusNode: widget.focusNode,
        trailing: [
          if (widget.loadingProgressNotifier != null)
            ValueListenableBuilder<bool>(
              valueListenable: widget.loadingProgressNotifier!,
              builder: (_, value, __) {
                if (value) {
                  return IconButton(
                    icon: const SizedBox(
                      height: 18,
                      width: 18,
                      child: Spinner(),
                    ),
                    onPressed: () {
                      widget.onSubmitted(widget.controller.text);
                      widget.focusNode.unfocus();
                    },
                  );
                } else {
                  return IconButton(
                    icon: const Icon(FluentIcons.search_20_regular),
                    onPressed: () {
                      widget.onSubmitted(widget.controller.text);
                      widget.focusNode.unfocus();
                    },
                  );
                }
              },
            )
          else
            IconButton(
              icon: const Icon(FluentIcons.search_20_regular),
              onPressed: () {
                widget.onSubmitted(widget.controller.text);
                widget.focusNode.unfocus();
              },
            ),
        ],
      ),
    );
  }
}
