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

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    this.confirmationMessage,
    required this.submitMessage,
    required this.onCancel,
    required this.onSubmit,
    this.isDangerous = false,
  });
  final String? confirmationMessage;
  final String submitMessage;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;
  final bool isDangerous;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Icon(
        isDangerous
            ? FluentIcons.warning_24_regular
            : FluentIcons.question_circle_24_regular,
        color: isDangerous ? colorScheme.error : colorScheme.primary,
        size: 32,
      ),
      title: Text(
        context.l10n!.confirmation,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: confirmationMessage != null
          ? Text(
              confirmationMessage!,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            )
          : null,
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(context.l10n!.cancel),
        ),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: isDangerous
                ? colorScheme.error
                : colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(submitMessage),
        ),
      ],
    );
  }
}
