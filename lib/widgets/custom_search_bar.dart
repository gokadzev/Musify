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
import 'package:material_ui/material_ui.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    super.key,
    required this.onSubmitted,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    this.onChanged,
    this.loadingProgressNotifier,
  });

  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final ValueNotifier<bool>? loadingProgressNotifier;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;

  void _clear() {
    controller.clear();
    onChanged?.call('');
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SearchBar(
        controller: controller,
        focusNode: focusNode,
        hintText: labelText,
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        textInputAction: TextInputAction.search,
        leading: Icon(
          FluentIcons.search_24_regular,
          color: cs.onSurfaceVariant,
          size: 22,
        ),
        onChanged: onChanged,
        onSubmitted: (value) {
          onSubmitted(value);
          focusNode.unfocus();
        },
        trailing: [
          ListenableBuilder(
            listenable: Listenable.merge([controller, loadingProgressNotifier]),
            builder: (context, _) {
              final isLoading = loadingProgressNotifier?.value ?? false;
              final hasText = controller.text.isNotEmpty;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  if (hasText)
                    IconButton(
                      onPressed: _clear,
                      tooltip: MaterialLocalizations.of(context)
                          .clearButtonTooltip,
                      icon: Icon(
                        FluentIcons.dismiss_24_regular,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
