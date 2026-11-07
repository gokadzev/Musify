import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/library_merge_service.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/local_sync/sync_merge.dart';
import 'package:musify/services/settings_manager.dart';

import 'fixtures.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_recap_race');
    Hive.init(dir.path);
    for (final name in ['user', 'userNoBackup', 'settings', 'cache']) {
      await Hive.openBox(name);
    }
    wrappedEnabled.value = true;
    listeningStatsService.reload();
  });
  tearDown(() async {
    LibraryMergeService.fault = null;
    await Hive.close();
    await dir.delete(recursive: true);
  });
  int seconds() {
    final date = DateTime.now();
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    return listeningStatsService.monthStats(key)!['totalSeconds'] as int;
  }

  test(
    'a favourites-only merge preserves unsaved listening progress',
    () async {
      await Hive.box('user').put('likedSongs', [song('a')]);
      await LibraryMergeService.exportLibrary();
      final remote = SyncDocument()
        ..capture(
          {
            'likedSongs': [song('b')],
          },
          null,
          'remote',
        );
      LibraryMergeService.fault = (stage) async {
        if (stage == 'prepared')
          listeningStatsService.recordListeningTime(
            const Duration(seconds: 60),
          );
      };
      await LibraryMergeService.mergeLibrary(
        payload(remote, categories: {SyncCategory.favourites}),
        categories: {SyncCategory.favourites},
      );
      expect(seconds(), 60);
    },
  );
  test(
    'a recap merge retries when listening progress changes during preparation',
    () async {
      await Hive.box('user').put('likedSongs', [song('a')]);
      await LibraryMergeService.exportLibrary();
      final remote = SyncDocument()
        ..capture({'wrappedListeningStats': recap(2)}, null, 'remote');
      var once = false;
      LibraryMergeService.fault = (stage) async {
        if (stage == 'prepared' && !once) {
          once = true;
          listeningStatsService.recordListeningTime(
            const Duration(seconds: 180),
          );
        }
      };
      await LibraryMergeService.mergeLibrary(
        payload(remote, categories: {SyncCategory.recap}),
        categories: {SyncCategory.recap},
      );
      expect(seconds(), 180);
    },
  );
  test('recap merge retries when more progress arrives during flush', () async {
    await Hive.box('user').put('likedSongs', [song('a')]);
    await LibraryMergeService.exportLibrary();
    final remote = SyncDocument()
      ..capture({'wrappedListeningStats': recap(2)}, null, 'remote');
    var once = false;
    LibraryMergeService.fault = (stage) async {
      if (stage == 'recapFlushed' && !once) {
        once = true;
        listeningStatsService.recordListeningTime(const Duration(seconds: 180));
      }
    };
    await LibraryMergeService.mergeLibrary(
      payload(remote, categories: {SyncCategory.recap}),
      categories: {SyncCategory.recap},
    );
    expect(seconds(), 180);
  });
  test('failed favourites merge preserves listening progress', () async {
    await Hive.box('user').put('likedSongs', [song('a')]);
    await LibraryMergeService.exportLibrary();
    final remote = SyncDocument()
      ..capture(
        {
          'likedSongs': [song('b')],
        },
        null,
        'remote',
      );
    LibraryMergeService.fault = (stage) async {
      if (stage == 'written') {
        listeningStatsService.recordListeningTime(const Duration(seconds: 60));
        throw StateError('failure');
      }
    };
    await expectLater(
      LibraryMergeService.mergeLibrary(
        payload(remote, categories: {SyncCategory.favourites}),
        categories: {SyncCategory.favourites},
      ),
      throwsStateError,
    );
    expect(seconds(), 60);
  });
  test('failed recap merge preserves new listening progress', () async {
    await Hive.box('user').put('likedSongs', [song('a')]);
    await LibraryMergeService.exportLibrary();
    final remote = SyncDocument()
      ..capture({'wrappedListeningStats': recap(2)}, null, 'remote');
    LibraryMergeService.fault = (stage) async {
      if (stage == 'written') {
        listeningStatsService.recordListeningTime(const Duration(seconds: 60));
        throw StateError('failure');
      }
    };
    await expectLater(
      LibraryMergeService.mergeLibrary(
        payload(remote, categories: {SyncCategory.recap}),
        categories: {SyncCategory.recap},
      ),
      throwsStateError,
    );
    expect(seconds(), 180);
  });
}
