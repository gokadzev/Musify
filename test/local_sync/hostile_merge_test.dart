import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/local_sync/sync_data.dart';

import 'fixtures.dart';
import 'service_harness.dart';

void main() {
  final h = SyncHarness();
  setUpAll(h.openStorage);
  setUp(h.start);
  tearDown(h.stop);
  tearDownAll(h.closeStorage);

  /// A document that holds [song] under the id [id], however odd.
  Map<String, dynamic> libraryWith(String id) {
    final library = payload(
      document({
        'likedSongs': [song('placeholder')],
      }),
      categories: {SyncCategory.favourites},
    );
    final records = Map<String, dynamic>.from(
      library['document']['records'] as Map,
    );
    final key = records.keys.firstWhere((k) => k.contains('placeholder'));
    final cell = Map<String, dynamic>.from(records.remove(key) as Map);
    cell['value'] = {...cell['value'] as Map, 'ytid': id};
    records[jsonEncode(['likedSongs', '', id])] = cell;
    library['document']['records'] = records;
    return library;
  }

  test('a paired device cannot plant an id that is a path', () async {
    await Hive.box('user').put('likedSongs', [song('mine')]);
    for (final id in ['../../x', 'a/b', r'a\b', 'tab\there', 'x' * 129]) {
      final result = await h.secure('merge', {
        'categories': ['favourites'],
        'library': libraryWith(id),
      });
      expect(result.status, 400, reason: jsonEncode(id));
    }
    expect((Hive.box('user').get('likedSongs') as List).single['ytid'], 'mine');
  });

  test('a paired device cannot win every conflict with a huge clock', () async {
    final library = libraryWith('fine');
    library['document']['clock'] = 1 << 62;
    final result = await h.secure('merge', {
      'categories': ['favourites'],
      'library': library,
    });
    expect(result.status, 400);
    expect(Hive.box('userNoBackup').get('localSyncDocumentV2'), isNull);
  });

  test('ids of local files and YouTube songs still sync', () async {
    final library = payload(
      document({
        'likedSongs': [song('local:0123abcd'), song('dQw4w9WgXcQ')],
      }),
      categories: {SyncCategory.favourites},
    );
    final result = await h.secure('merge', {
      'categories': ['favourites'],
      'library': library,
    });
    expect(result.status, 200);
    expect(
      (Hive.box('user').get('likedSongs') as List).map((s) => s['ytid']),
      unorderedEquals(['local:0123abcd', 'dQw4w9WgXcQ']),
    );
  });
}
