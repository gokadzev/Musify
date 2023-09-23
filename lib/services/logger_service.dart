import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify/extensions/l10n.dart';

class Logger {
  String _logs = '';
  int _logCount = 0;

  void log(String message) {
    final timestamp = DateTime.now().toString();
    final logMessage = '[$timestamp] $message';
    _logs += '$logMessage\n';
    _logCount++;
  }

  Future<String> copyLogs(BuildContext context) async {
    try {
      if (_logs != '') {
        await Clipboard.setData(ClipboardData(text: _logs));
        return '${context.l10n()!.copyLogsSuccess}.';
      } else {
        return '${context.l10n()!.copyLogsNoLogs}.';
      }
    } catch (e) {
      log('Error copying logs: $e');
      return 'Error: $e';
    }
  }

  int getLogCount() {
    return _logCount;
  }
}
