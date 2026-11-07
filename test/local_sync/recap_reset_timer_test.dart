import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/local_sync_service.dart';
import 'package:musify/services/settings_manager.dart';

class CapturedTimer implements Timer {
  bool active = true;
  @override
  bool get isActive => active;
  @override
  int get tick => 0;
  @override
  void cancel() {
    active = false;
  }
}

void main() {
  test('clearing recap schedules an automatic sync', () async {
    final dir = await Directory.systemTemp.createTemp('sync_recap_timer');
    Hive.init(dir.path);
    for (final n in ['user', 'userNoBackup', 'settings', 'cache']) {
      await Hive.openBox(n);
    }
    final service = LocalSyncService.forTesting();
    final scheduled = <CapturedTimer>[];
    await runZoned(
      () async {
        await service.initialise();
        await Hive.box('settings').putAll({
          'localSyncEnabled': true,
          'localSyncAutomatic': true,
          'localSyncCategories': ['recap', 'favourites'],
        });
        reloadSettingsFromStorage();
        await service.savePairedDevice(
          const PairedSyncDevice(deviceId: 'b', name: 'b', secret: 'secret'),
        );
        await listeningStatsService.clearStats();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(scheduled.length, 1);
        await Hive.box('user').put('likedSongs', [
          {'ytid': 'a', 'title': 'a'},
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(scheduled.length, 2);
        await service.dispose();
      },
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, f) {
          if (duration == const Duration(seconds: 30)) {
            final timer = CapturedTimer();
            scheduled.add(timer);
            return timer;
          }
          return parent.createTimer(zone, duration, f);
        },
      ),
    );
    await Hive.close();
    await dir.delete(recursive: true);
  });
}
