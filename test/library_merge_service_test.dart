import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/library_merge_service.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_merge.dart';
import 'package:musify/services/settings_manager.dart';

import 'local_sync/fixtures.dart';

void main() {
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('musify_sync_store');
    Hive.init(directory.path);
    for (final name in ['user', 'userNoBackup', 'settings', 'cache']) {
      await Hive.openBox(name);
    }
  });
  setUp(() async {
    LibraryMergeService.fault = null;
    listeningStatsService.reload();
    userLikedRadioStations.value = [];
    for (final name in ['user', 'userNoBackup', 'settings', 'cache']) {
      await Hive.box(name).clear();
    }
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'export includes selected data and omits settings and downloads',
    () async {
      await Hive.box('user').put('likedSongs', [
        {...song('a'), 'audioPath': '/private/music.mp3'},
      ]);
      await Hive.box('settings').put('language', 'pt');
      await Hive.box('userNoBackup').put('offlineSongs', [song('download')]);
      final exported = await LibraryMergeService.exportLibrary(
        categories: {SyncCategory.favourites},
      );
      final text = canonicalSync(exported);
      expect(exported['schemaVersion'], syncSchemaVersion);
      expect(text, contains('"ytid":"a"'));
      expect(text, isNot(contains('/private/')));
      expect(text, isNot(contains('download')));
      expect(text, isNot(contains('language')));
    },
  );

  test('writes made by a merge are told apart from later user edits', () async {
    final box = Hive.box('user');
    await box.put('likedSongs', [song('local')]);
    await LibraryMergeService.exportLibrary();
    final remote = SyncDocument()
      ..capture(
        {
          'likedSongs': [song('remote')],
        },
        null,
        'other',
      );
    await LibraryMergeService.mergeLibrary(payload(remote));
    expect(box.get('likedSongs'), hasLength(2));
    expect(
      LibraryMergeService.isMergeWrite('likedSongs', box.get('likedSongs')),
      isTrue,
    );
    // Returning to the merged value later is a user edit.
    expect(
      LibraryMergeService.isMergeWrite('likedSongs', box.get('likedSongs')),
      isFalse,
    );
  });

  test(
    'merge persists favourites, playlists, radio, history and recap',
    () async {
      await Hive.box('user').put('likedSongs', [song('local')]);
      final incoming = payload(
        document({
          'likedSongs': [song('remote')],
          'playlists': ['PL1'],
          'likedRadioStations': ['radio'],
          'searchHistory': ['query'],
          'wrappedListeningStats': recap(300),
        }),
      );
      final changed = (await LibraryMergeService.mergeLibrary(incoming))
          .changed;
      expect(changed, isNotEmpty);
      expect(
        (Hive.box('user').get('likedSongs') as List)
            .map((e) => e['ytid'])
            .toSet(),
        {'local', 'remote'},
      );
      expect(Hive.box('user').get('playlists'), ['PL1']);
      expect(Hive.box('user').get('likedRadioStations'), ['radio']);
      expect(Hive.box('user').get('searchHistory'), ['query']);
      expect(
        Hive.box('user')
            .get('wrappedListeningStats')['currentMonth']['totalSeconds'],
        18000,
      );
      expect(
        (await LibraryMergeService.mergeLibrary(incoming)).changed,
        isEmpty,
      );
    },
  );

  test('excluded categories cannot be written by an incoming peer', () async {
    await Hive.box('user').put('likedSongs', [song('keep')]);
    final incoming = payload(
      document({
        'likedSongs': [song('remote')],
      }),
      categories: {SyncCategory.favourites},
    );
    await expectLater(
      LibraryMergeService.mergeLibrary(
        incoming,
        categories: {SyncCategory.recap},
      ),
      throwsFormatException,
    );
    expect((Hive.box('user').get('likedSongs') as List).single['ytid'], 'keep');
  });

  test('invalid schema is rejected before the first write', () async {
    await Hive.box('user').put('likedSongs', [song('keep')]);
    await expectLater(
      LibraryMergeService.mergeLibrary({
        'schemaVersion': 999,
        'likedSongs': [song('bad')],
      }),
      throwsFormatException,
    );
    expect((Hive.box('user').get('likedSongs') as List).single['ytid'], 'keep');
  });

  for (final stage in ['prepared', 'written', 'metadata']) {
    test('failure at $stage rolls back the complete application', () async {
      await Hive.box('user').put('likedSongs', [song('keep')]);
      await LibraryMergeService.exportLibrary();
      final before = canonicalSync(Hive.box('user').toMap());
      final stateBefore = canonicalSync(
        Hive.box('userNoBackup').get('localSyncDocumentV2'),
      );
      LibraryMergeService.fault = (current) async {
        if (current == stage) throw StateError('Injected storage failure');
      };
      await expectLater(
        LibraryMergeService.mergeLibrary(
          payload(
            document({
              'likedSongs': [song('new')],
              'playlists': ['new-playlist'],
            }),
          ),
        ),
        throwsStateError,
      );
      expect(canonicalSync(Hive.box('user').toMap()), before);
      expect(
        canonicalSync(Hive.box('userNoBackup').get('localSyncDocumentV2')),
        stateBefore,
      );
      expect(
        Hive.box('userNoBackup').containsKey('localSyncPendingMergeV2'),
        false,
      );
    });
  }

  test('an edit made while preparing a merge is retained', () async {
    await Hive.box('user').put('likedSongs', [song('a')]);
    await LibraryMergeService.exportLibrary();
    var edited = false;
    LibraryMergeService.fault = (stage) async {
      if (stage == 'prepared' && !edited) {
        edited = true;
        await Hive.box('user')
            .put('likedSongs', [song('a'), song('during-sync')]);
      }
    };
    await LibraryMergeService.mergeLibrary(
      payload(
        document({
          'likedSongs': [song('remote')],
        }),
      ),
    );
    expect(
      (Hive.box('user').get('likedSongs') as List)
          .map((e) => e['ytid'])
          .toSet(),
      {'a', 'during-sync', 'remote'},
    );
  });

  test('rollback preserves a newer user edit after the sync write', () async {
    await Hive.box('user').put('likedSongs', [song('before')]);
    await LibraryMergeService.exportLibrary();
    LibraryMergeService.fault = (stage) async {
      if (stage == 'written') {
        await Hive.box('user').put('likedSongs', [song('newer-user-edit')]);
        throw StateError('Injected failure after user edit');
      }
    };
    await expectLater(
      LibraryMergeService.mergeLibrary(
        payload(
          document({
            'likedSongs': [song('remote')],
          }),
        ),
      ),
      throwsStateError,
    );
    expect(
      (Hive.box('user').get('likedSongs') as List).single['ytid'],
      'newer-user-edit',
    );
  });
  test(
    'persisted multi-megabyte playlist artwork exports repeatedly without loss',
    () async {
      final image =
          'data:image/jpeg;base64,${List.filled(3700000, 'A').join()}';
      await Hive.box('user').put('customPlaylists', [
        {
          ...playlist('large-cover', ['a']),
          'image': image,
        },
      ]);
      final first = await LibraryMergeService.exportLibrary();
      final second = await LibraryMergeService.exportLibrary();
      expect(canonicalSync(second), canonicalSync(first));
      expect(Hive.box('user').get('customPlaylists')[0]['image'], image);
      expect(
        () => validateSyncJson('x' * (1024 * 1024 + 1)),
        throwsFormatException,
      );
      expect(
        () => validateSyncJson(
          'data:image/png;base64,${'A' * maxSyncImageCharacters}',
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'cleared recap stays cleared when listening resumes before the next sync',
    () async {
      wrappedEnabled.value = true;
      await Hive.box('user').put('wrappedListeningStats', recap(300));
      listeningStatsService.reload();
      final oldPeer = await LibraryMergeService.exportLibrary(
        categories: {SyncCategory.recap},
      );
      await listeningStatsService.clearStats();
      listeningStatsService.recordListeningTime(const Duration(minutes: 1));
      await listeningStatsService.flush();
      await LibraryMergeService.exportLibrary(categories: {SyncCategory.recap});
      await LibraryMergeService.mergeLibrary(
        oldPeer,
        categories: {SyncCategory.recap},
      );
      final month = Hive.box('user')
          .get('wrappedListeningStats')['currentMonth'];
      expect(
        month['totalSeconds'],
        60,
        reason: 'An offline peer must not resurrect the 300-minute recap that was explicitly cleared.',
      );
    },
  );
  test(
    'editing radio favourites after sync preserves imported favourites',
    () async {
      await LibraryMergeService.mergeLibrary(
        payload(
          document({
            'likedRadioStations': ['remote'],
          }),
        ),
      );
      expect(Hive.box('user').get('likedRadioStations'), ['remote']);
      await addRadioStationToLiked('local');
      expect((Hive.box('user').get('likedRadioStations') as List).toSet(), {
        'remote',
        'local',
      });
    },
  );
  test('a recap cleared before the first sync stays cleared after importing an old peer', () async {
    wrappedEnabled.value = true;
    final previous = payload(
      document({'wrappedListeningStats': recap(300)}),
      categories: {SyncCategory.recap},
    );
    await Hive.box('user').put('wrappedListeningStats', recap(300));
    await listeningStatsService.clearStats();
    listeningStatsService.recordListeningTime(const Duration(minutes: 1));
    await LibraryMergeService.exportLibrary(categories: {SyncCategory.recap});
    await LibraryMergeService.mergeLibrary(
      previous,
      categories: {SyncCategory.recap},
    );
    expect(
      Hive.box('user')
          .get('wrappedListeningStats')['currentMonth']['totalSeconds'],
      60,
    );
  });
}
