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

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';

Future<String?> pickImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );

  if (result != null && result.files.single.bytes != null) {
    final file = result.files.single;
    String? mimeType;

    if (file.extension != null) {
      switch (file.extension!.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'bmp':
          mimeType = 'image/bmp';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'application/octet-stream';
      }
    } else {
      mimeType = 'application/octet-stream';
    }

    return 'data:$mimeType;base64,${base64Encode(file.bytes!)}';
  }

  return null;
}

Widget buildImagePreview({
  String? imageBase64,
  String? imageUrl,
  double width = 80,
  double height = 80,
}) {
  Widget? imageWidget;

  if (imageBase64 != null) {
    final base64Data = imageBase64.contains(',')
        ? imageBase64.split(',').last
        : imageBase64;

    imageWidget = Image.memory(
      base64Decode(base64Data),
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  } else if (imageUrl != null && imageUrl.isNotEmpty) {
    imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, _, __) => Icon(
        FluentIcons.image_off_20_regular,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  if (imageWidget == null) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageWidget,
    ),
  );
}

Widget buildImagePickerRow(
  BuildContext context,
  Function() onPickImage,
  bool isImagePicked,
) {
  final colorScheme = Theme.of(context).colorScheme;

  return OutlinedButton.icon(
    onPressed: onPickImage,
    style: OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary,
      side: BorderSide(
        color: isImagePicked ? colorScheme.primary : colorScheme.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    icon: Icon(
      isImagePicked
          ? FluentIcons.checkmark_circle_20_filled
          : FluentIcons.image_add_20_regular,
      size: 20,
    ),
    label: Text(
      isImagePicked
          ? context.l10n!.imagePicked
          : context.l10n!.pickImageFromDevice,
    ),
  );
}
