import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify/extensions/l10n.dart';

class Logger {
  String _logs = '';
  int _logCount = 0;

  void log(String errorLocation, Object? error, StackTrace? stackTrace) {
    final timestamp = DateTime.now().toString();

    // Check if error is not null, otherwise use an empty string
    final errorMessage = error != null ? '$error' : '';

    // Check if stackTrace is not null, otherwise use an empty string
    final stackTraceMessage = stackTrace != null ? '$stackTrace' : '';

    final logMessage =
        '[$timestamp] $errorLocation:$errorMessage\n$stackTraceMessage';

    debugPrint(logMessage);
    _logs += '$logMessage\n';
    _logCount++;
  }

  Future<String> copyLogs(BuildContext context) async {
    try {
      if (_logs != '') {
        await Clipboard.setData(ClipboardData(text: _logs));
        return '${context.l10n!.copyLogsSuccess}.';
      } else {
        return '${context.l10n!.copyLogsNoLogs}.';
      }
    } catch (e, stackTrace) {
      log('Error copying logs', e, stackTrace);
      return 'Error: $e';
    }
  }

  int getLogCount() {
    return _logCount;
  }
}
