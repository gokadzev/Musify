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
        TextButton(
          onPressed: onCancel,
          child: Text(context.l10n!.cancel),
        ),
        TextButton(
          onPressed: onSubmit,
          child: Text(context.l10n!.remove),
        ),
      ],
    );
  }
}
