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

import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    this.confirmationMessage,
    required this.submitMessage,
    required this.onCancel,
    required this.onSubmit,
  });
  final String? confirmationMessage;
  final String submitMessage;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n!.confirmation),
      content: confirmationMessage != null ? Text(confirmationMessage!) : null,
      actions: <Widget>[
        TextButton(onPressed: onCancel, child: Text(context.l10n!.cancel)),
        TextButton(onPressed: onSubmit, child: Text(context.l10n!.remove)),
      ],
    );
  }
}
