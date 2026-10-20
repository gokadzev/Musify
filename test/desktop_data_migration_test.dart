import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/startup_support.dart';

void main() {
  late Directory root;
  late Directory legacy;
  late Directory target;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('musify_migration_test');
    legacy = Directory('${root.path}/Documents')..createSync(recursive: true);
    target = Directory('${root.path}/support')..createSync(recursive: true);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('moves Hive boxes and downloads into the support directory', () async {
    File('${legacy.path}/settings.hive').writeAsStringSync('settings');
    File('${legacy.path}/settings.lock').writeAsStringSync('');
    final tracks = Directory('${legacy.path}/tracks')..createSync();
    File('${tracks.path}/song.m4a').writeAsStringSync('audio');

    final report = await migrateLegacyDesktopData(from: legacy, to: target);

    expect(report.failed, isEmpty);
    expect(report.moved, contains('settings.hive'));
    expect(report.moved, contains('settings.lock'));
    expect(File('${target.path}/settings.hive').readAsStringSync(), 'settings');
    expect(File('${target.path}/settings.lock').existsSync(), isTrue);
    expect(File('${target.path}/tracks/song.m4a').readAsStringSync(), 'audio');
    expect(File('${legacy.path}/settings.hive').existsSync(), isFalse);
    expect(Directory('${legacy.path}/tracks').existsSync(), isFalse);
  });

  test('keeps existing destination data and merges new downloads', () async {
    File('${legacy.path}/settings.hive').writeAsStringSync('legacy');
    File('${target.path}/settings.hive').writeAsStringSync('current');
    final legacyTracks = Directory('${legacy.path}/tracks')..createSync();
    File('${legacyTracks.path}/new.m4a').writeAsStringSync('new');
    final targetTracks = Directory('${target.path}/tracks')..createSync();
    File('${targetTracks.path}/old.m4a').writeAsStringSync('old');

    final report = await migrateLegacyDesktopData(from: legacy, to: target);

    expect(report.failed, isEmpty);
    expect(report.skipped, contains('settings.hive'));
    expect(File('${target.path}/settings.hive').readAsStringSync(), 'current');
    expect(File('${target.path}/tracks/old.m4a').readAsStringSync(), 'old');
    expect(File('${target.path}/tracks/new.m4a').readAsStringSync(), 'new');
  });

  test('is a no-op when there is no legacy directory', () async {
    await legacy.delete(recursive: true);

    final report = await migrateLegacyDesktopData(from: legacy, to: target);

    expect(report.moved, isEmpty);
    expect(report.skipped, isEmpty);
    expect(report.failed, isEmpty);
    expect(target.existsSync(), isTrue);
  });
}
