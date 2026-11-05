import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_merge.dart';

import 'fixtures.dart';

void main() {
  test('an empty new peer does not replace an existing favourites order', () {
    final a = document({
      'likedSongs': [song('b'), song('a')],
    });
    final b = document({'likedSongs': <Map>[]});
    a.join(b);
    expect((a.materialize()['likedSongs'] as List).map((e) => e['ytid']), [
      'b',
      'a',
    ]);
  });
  test('nested downloaded playlist paths are not serialized', () {
    final a = document({
      'likedPlaylists': [
        {
          'ytid': 'PL1',
          'list': [
            {
              'ytid': 'a',
              'audioPath': '/private/audio',
              'nested': {'artworkPath': '/private/art'},
            },
          ],
        },
      ],
    });
    expect(canonicalSync(a.toMap()), isNot(contains('/private/')));
  });
  test('pins to separately resolved playlists survive a merge', () {
    final a = document({
      'pinnedPlaylistIds': ['offline'],
    });
    expect(a.materialize()['pinnedPlaylistIds'], ['offline']);
  });
  test('old stored records and older peers cannot send local paths', () {
    final documentWithOldData = document({
      'likedPlaylists': [
        {
          'ytid': 'PL1',
          'list': [
            {'ytid': 'a'},
          ],
        },
      ],
    });
    final cell = documentWithOldData.records.values.firstWhere(
      (cell) => cell['value'] is Map && cell['value']['ytid'] == 'PL1',
    ) as Map;
    ((cell['value']['list'] as List).first as Map)['audioPath'] =
        '/private/audio';
    expect(
      canonicalSync(documentWithOldData.toMap()),
      isNot(contains('/private/')),
    );
    final oldWire = {
      'version': syncSchemaVersion,
      'clock': documentWithOldData.clock,
      'records': documentWithOldData.records,
    };
    final received = SyncDocument.fromMap(oldWire);
    expect(canonicalSync(received.materialize()), isNot(contains('/private/')));
  });
  test('an old empty order cannot overwrite an initial nonempty order', () {
    final ordered = document({
      'likedSongs': [song('b'), song('a')],
    });
    final oldEmpty = document({'likedSongs': <Map>[]});
    final orderKey = ordered.records.keys.firstWhere(
      (key) => key.contains('likedSongsOrder'),
    );
    oldEmpty.records[orderKey] = {
      'clock': 0,
      'device': '',
      'deleted': false,
      'value': <String>[],
    };
    ordered.join(oldEmpty);
    expect(
      (ordered.materialize()['likedSongs'] as List).map((e) => e['ytid']),
      ['b', 'a'],
    );
  });
  test(
    'missing baseline does not invent a reset or discard peer recap history',
    () {
      final old = {...recap(200), 'syncResetId': 'same-reset'};
      final high = {
        ...recap(300),
        'syncResetId': 'same-reset',
        'history': {'2025-01': month(100)},
      };
      final local = document({'wrappedListeningStats': old});
      final remote = document({'wrappedListeningStats': high});
      local
        ..capture({'wrappedListeningStats': old}, null, 'local')
        ..join(remote);
      final result = local.materialize()['wrappedListeningStats'];
      expect(result['currentMonth']['totalSeconds'], 18000);
      expect(result['history'], contains('2025-01'));
    },
  );
  test('clearing recent history also clears items hidden past the limit', () {
    List<Map<String, dynamic>> entries(int from) => List.generate(
      100,
      (i) => {
        ...song('s${i + from}'),
        'lastPlayed': DateTime(2026)
            .add(Duration(minutes: i + from))
            .toIso8601String(),
        'listeningCount': 1,
      },
    );
    final a = document({'recentlyPlayedSongs': entries(0)});
    final b = document({'recentlyPlayedSongs': entries(100)});
    a.join(b);
    final before = a.materialize();
    expect(before['recentlyPlayedSongs'], hasLength(100));
    a.capture({...before, 'recentlyPlayedSongs': []}, before, 'a');
    expect(a.materialize()['recentlyPlayedSongs'], isEmpty);
    b.join(a);
    expect(b.materialize()['recentlyPlayedSongs'], isEmpty);
  });
  test('a YouTube playlist moved into a deleted folder returns to YouTube playlists', () {
    final initial = {
      'playlists': ['PL'],
      'playlistFolders': [
        {'id': 'folder', 'title': 'Folder', 'playlists': <Map>[]},
      ],
    };
    final a = document(initial), b = document(initial);
    final base = a.materialize();
    a.capture({...base, 'playlistFolders': []}, base, 'a');
    final nested = {
      'ytid': 'PL',
      'title': 'YouTube',
      'source': 'user-youtube',
      'list': <Map>[],
    };
    b.capture(
      {
        ...base,
        'playlists': [],
        'playlistFolders': [
          {
            'id': 'folder',
            'title': 'Folder',
            'playlists': [nested],
          },
        ],
      },
      base,
      'b',
    );
    a.join(b);
    final result = a.materialize();
    expect(result['playlists'], contains('PL'));
    expect(result['customPlaylists'], isEmpty);
    expect(result['playlistFolders'], isEmpty);
    a.capture({...result, 'playlists': []}, result, 'a');
    expect(a.materialize()['playlists'], isEmpty);
    a.join(b);
    expect(a.materialize()['playlists'], isEmpty);
  });
}
