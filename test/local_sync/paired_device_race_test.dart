import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/local_sync_service.dart';

void main() {
  late Directory dir;
  late LocalSyncService server;
  const a = PairedSyncDevice(deviceId: 'a', name: 'a', secret: 'secret-a');
  const b = PairedSyncDevice(deviceId: 'b', name: 'b', secret: 'secret-b');
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_paired_race');
    Hive.init(dir.path);
    for (final name in ['user', 'userNoBackup', 'settings', 'cache']) {
      await Hive.openBox(name);
    }
    server = LocalSyncService.forTesting();
  });
  tearDown(() async {
    await server.dispose();
    await Hive.close();
    await dir.delete(recursive: true);
  });
  test('concurrent pairings retain both devices', () async {
    await Future.wait([server.savePairedDevice(a), server.savePairedDevice(b)]);
    expect(server.pairedDevices.value.map((e) => e.deviceId).toSet(), {
      'a',
      'b',
    });
  });
  test(
    'concurrent save and forget do not resurrect the forgotten device',
    () async {
      await server.savePairedDevice(a);
      await Future.wait([server.savePairedDevice(b), server.forgetDevice('a')]);
      expect(server.pairedDevices.value.map((e) => e.deviceId).toList(), ['b']);
    },
  );
  test('a stop requested while starting closes the server', () async {
    final starting = server.startServer();
    final stopping = server.stopServer();
    await Future.wait([starting, stopping]);
    expect(server.serverPort, isNull);
    expect(server.serverRunning.value, isFalse);
  });
}
