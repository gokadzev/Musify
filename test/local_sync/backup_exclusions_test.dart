import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('Android backup rules exclude the actual Hive identity files', () async {
    final root = await Directory.systemTemp.createTemp('sync_backup_rules_');
    try {
      Hive.init(root.path);
      final box = await Hive.openBox('userNoBackup');
      final filename = box.path!.split(Platform.pathSeparator).last;
      expect(filename, 'usernobackup.hive');
      final lockName = filename.replaceFirst('.hive', '.lock');
      await box.close();
      for (final entry in {
        'backup_rules.xml': 1,
        'data_extraction_rules.xml': 2,
      }.entries) {
        final xml = await File('android/app/src/main/res/xml/${entry.key}')
            .readAsString();
        for (final name in [filename, lockName]) {
          final rule = 'path="app_flutter/$name"';
          expect(rule.allMatches(xml).length, entry.value, reason: entry.key);
        }
      }
    } finally {
      await Hive.close();
      await root.delete(recursive: true);
    }
  });
}
