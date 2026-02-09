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
import 'package:musify/extensions/l10n.dart';

class RenameSongDialog extends StatefulWidget {
  const RenameSongDialog({
    super.key,
    required this.currentTitle,
    required this.currentArtist,
    required this.onRename,
  });

  final String currentTitle;
  final String currentArtist;
  final Function(String newTitle, String newArtist) onRename;

  @override
  State<RenameSongDialog> createState() => _RenameSongDialogState();
}

class _RenameSongDialogState extends State<RenameSongDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _artistController = TextEditingController(text: widget.currentArtist);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  void _handleRename() {
    final newTitle = _titleController.text.trim();
    final newArtist = _artistController.text.trim();

    if (newTitle.isEmpty || newArtist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n!.fieldsNotEmpty),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onRename(newTitle, newArtist);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        context.l10n!.renameSong,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.l10n!.name,
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: context.l10n!.artist,
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(context.l10n!.cancel),
        ),
        FilledButton(
          onPressed: _handleRename,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(context.l10n!.confirm),
        ),
      ],
    );
  }
}
