import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';

class Logger {
  static final _logFile = File('log.txt');

  static void log(String message) {
    final timestamp = DateTime.now().toString();
    final logMessage = '[$timestamp] $message';
    _logFile.writeAsStringSync('$logMessage\n', mode: FileMode.append);
  }

  static Future<String> exportLogs(BuildContext context) async {
    try {
      if (await _logFile.exists()) {
        await FileDownloader()
            .moveFileToSharedStorage(_logFile.path, SharedStorage.downloads);
        return '${context.l10n()!.exportLogsSuccess}.';
      } else {
        return '${context.l10n()!.exportLogsNoLogs}.';
      }
    } catch (e) {
      log('Error exporting logs: $e');
      return 'Error: $e';
    }
  }
}
