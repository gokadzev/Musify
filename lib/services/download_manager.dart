import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> checkNecessaryPermissions(BuildContext context) async {
  await Permission.audio.request();
  await Permission.notification.request();
  try {
    await Permission.storage.request();
  } catch (e) {
    logger.log('Error while requesting permissions: $e');
    showToast(
      context,
      '${context.l10n!.errorWhileRequestingPerms} + $e',
    );
  }
}
