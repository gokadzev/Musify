import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_merge.dart';

import 'fixtures.dart';

void main() {
  test(
    'three independent libraries converge in any order without duplicates',
    () {
      for (var seed = 0; seed < 50; seed++) {
        final random = Random(seed);
        final docs = List.generate(
          3,
          (peer) => document({
            'likedSongs': List.generate(
              8,
              (_) => song('s${random.nextInt(16)}', 'peer-$peer'),
            ),
          }),
        );
        final left = copyDocument(docs[0])
          ..join(docs[1])
          ..join(docs[2]);
        final right = copyDocument(docs[2])
          ..join(docs[0])
          ..join(docs[1]);
        expect(canonicalSync(left.records), canonicalSync(right.records));
        final before = canonicalSync(left.records);
        left.join(copyDocument(left));
        expect(canonicalSync(left.records), before);
        expect(
          canonicalSync(left.materialize()),
          canonicalSync(right.materialize()),
        );
      }
    },
  );

  test('offline peer cannot resurrect a removed favourite', () {
    final original = {
      'likedSongs': [song('a'), song('b')],
    };
    final a = document(original), b = document(original);
    final baseline = a.materialize();
    final edited = {
      ...baseline,
      'likedSongs': [song('b')],
    };
    a
      ..capture(edited, baseline, 'device-a')
      ..join(b);
    b.join(a);
    for (final doc in [a, b]) {
      expect((doc.materialize()['likedSongs'] as List).map((e) => e['ytid']), [
        'b',
      ]);
    }
  });

  test('concurrent addition and removal inside a playlist are preserved', () {
    final initial = {
      'customPlaylists': [
        playlist('mix', ['a', 'b']),
      ],
    };
    final a = document(initial), b = document(initial);
    final base = a.materialize();
    a.capture(
      {
        ...base,
        'customPlaylists': [
          playlist('mix', ['b']),
        ],
      },
      base,
      'a',
    );
    b.capture(
      {
        ...base,
        'customPlaylists': [
          playlist('mix', ['a', 'b', 'c']),
        ],
      },
      base,
      'b',
    );
    a.join(b);
    b.join(a);
    for (final doc in [a, b]) {
      final tracks = doc.materialize()['customPlaylists'][0]['list'] as List;
      expect(tracks.map((e) => e['ytid']).toSet(), {'b', 'c'});
    }
  });

  test('same-name playlists keep their identities and valid pins', () {
    final a = document({
      'customPlaylists': [
        playlist('pA', ['a']),
      ],
      'pinnedPlaylistIds': ['pA'],
    });
    final b = document({
      'customPlaylists': [
        playlist('pB', ['b']),
      ],
      'pinnedPlaylistIds': ['pB'],
    });
    a.join(b);
    b.join(a);
    for (final doc in [a, b]) {
      final library = doc.materialize();
      expect(
        (library['customPlaylists'] as List).map((e) => e['ytid']).toSet(),
        {'pA', 'pB'},
      );
      expect((library['pinnedPlaylistIds'] as List).toSet(), {'pA', 'pB'});
    }
    expect(canonicalSync(a.materialize()), canonicalSync(b.materialize()));
  });

  test('full pin lists converge to the same five usable pins', () {
    final a = document({
      'playlists': List.generate(5, (i) => 'a$i'),
      'pinnedPlaylistIds': List.generate(5, (i) => 'a$i'),
    });
    final b = document({
      'playlists': List.generate(5, (i) => 'b$i'),
      'pinnedPlaylistIds': List.generate(5, (i) => 'b$i'),
    });
    a.join(b);
    b.join(a);
    expect(a.materialize()['pinnedPlaylistIds'], hasLength(5));
    expect(
      a.materialize()['pinnedPlaylistIds'],
      b.materialize()['pinnedPlaylistIds'],
    );
  });

  test('recap copies missing history and chooses 300 over 200 without summing', () {
    final a = document({
      'wrappedListeningStats': recap(200, history: {'2025-01': month(100)}),
    });
    final b = document({
      'wrappedListeningStats': recap(300, history: {'2025-02': month(150)}),
    });
    a.join(b);
    b.join(a);
    for (final doc in [a, b]) {
      final data = doc.materialize()['wrappedListeningStats'];
      expect(data['currentMonth']['totalSeconds'], 18000);
      expect((data['history'] as Map).keys.toSet(), {'2025-01', '2025-02'});
    }
    a.join(b);
    expect(
      a.materialize()['wrappedListeningStats']['currentMonth']['totalSeconds'],
      18000,
    );
  });

  test('equal-time recap conflicts have a stable complete-month winner', () {
    final a = document({'wrappedListeningStats': recap(300)});
    final b = document({'wrappedListeningStats': recap(300, id: 'b')});
    a.join(b);
    b.join(a);
    expect(canonicalSync(a.materialize()), canonicalSync(b.materialize()));
    expect(
      a.materialize()['wrappedListeningStats']['currentMonth']['songs'],
      hasLength(1),
    );
  });

  test(
    'selection excludes private categories from the serialized document',
    () {
      final doc = document({
        'likedSongs': [song('private')],
        'playlists': ['shared'],
        'wrappedListeningStats': recap(300),
      });
      final filtered = doc.select({SyncCategory.playlists});
      expect(canonicalSync(filtered.toMap()), isNot(contains('private')));
      expect(canonicalSync(filtered.toMap()), isNot(contains('totalSeconds')));
      expect(filtered.materialize()['playlists'], ['shared']);
    },
  );

  test('clearing recap propagates and new listening starts from zero', () {
    final a = document({'wrappedListeningStats': recap(300)});
    final b = copyDocument(a);
    final base = a.materialize();
    final cleared = {...recap(0), 'syncResetId': 'reset-a'};
    a
      ..capture({...base, 'wrappedListeningStats': cleared}, base, 'a')
      ..join(b);
    b.join(a);
    for (final doc in [a, b]) {
      expect(
        doc.materialize()['wrappedListeningStats']['currentMonth']['totalSeconds'],
        0,
      );
    }
    final resetBase = b.materialize();
    b.capture(
      {
        ...resetBase,
        'wrappedListeningStats': {...recap(10), 'syncResetId': 'reset-a'},
      },
      resetBase,
      'b',
    );
    a.join(b);
    b.join(a);
    expect(canonicalSync(a.materialize()), canonicalSync(b.materialize()));
    expect(
      a.materialize()['wrappedListeningStats']['currentMonth']['totalSeconds'],
      600,
    );
  });

  test('unknown schema and malformed playlist data are rejected', () {
    expect(
      () => SyncDocument.fromMap({'version': 999, 'clock': 0, 'records': {}}),
      throwsFormatException,
    );
    expect(
      () => document({
        'customPlaylists': [
          {'ytid': 'p', 'list': 'invalid'},
        ],
      }),
      throwsFormatException,
    );
    final raw = document({
      'likedSongs': [song('a')],
    }).toMap();
    (raw['records'] as Map).values.first['value'] = {'ytid': 'different'};
    expect(() => SyncDocument.fromMap(raw), throwsFormatException);
  });
  test('a history edit and removal converge independently of merge order', () {
    final a = document({
      'wrappedListeningStats': recap(0, history: {'2026-09': month(300)}),
    });
    final b = document({'wrappedListeningStats': recap(0)});
    final c = copyDocument(a);
    b.capture(
      {
        'wrappedListeningStats': recap(0, history: {'2026-09': month(200)}),
      },
      b.materialize(),
      'b',
    );
    c.capture({'wrappedListeningStats': recap(0)}, c.materialize(), 'a');
    final left = copyDocument(a)
      ..join(c)
      ..join(b);
    final right = copyDocument(b)
      ..join(a)
      ..join(c);
    expect(
      canonicalSync(left.materialize()),
      canonicalSync(right.materialize()),
    );
  });
  test('recap removal wins concurrent edits and an intentional re-add starts fresh', () {
    final a = document({'wrappedListeningStats': recap(300)});
    final b = copyDocument(a);
    final base = a.materialize();
    a.capture(
      {
        'wrappedListeningStats': recap(300, history: {'2026-09': month(300)}),
      },
      base,
      'a',
    );
    final original = a.materialize();
    b.join(a);
    a.capture({'wrappedListeningStats': recap(300)}, original, 'a');
    b.capture(
      {
        'wrappedListeningStats': recap(300, history: {'2026-09': month(400)}),
      },
      original,
      'b',
    );
    a.join(b);
    b.join(a);
    expect(a.materialize()['wrappedListeningStats']['history'], isEmpty);
    final removed = a.materialize();
    a
      ..capture(
        {
          'wrappedListeningStats': recap(300, history: {'2026-09': month(10)}),
        },
        removed,
        'a',
      )
      ..join(b);
    b.join(a);
    expect(
      a.materialize()['wrappedListeningStats']['history']['2026-09']['totalSeconds'],
      600,
    );
    expect(canonicalSync(a.records), canonicalSync(b.records));
  });

  test(
    'recent-played aggregation and removals converge under every grouping',
    () {
      for (var seed = 0; seed < 50; seed++) {
        final random = Random(seed);
        final initial = {
          'recentlyPlayedSongs': [
            {
              ...song('a'),
              'lastPlayed': '2026-10-01T10:00:00Z',
              'listeningCount': 100,
            },
          ],
        };
        final a = document(initial),
            b = document(initial),
            c = document(initial);
        final baseline = a.materialize();
        b.capture(
          {
            ...baseline,
            'recentlyPlayedSongs': [
              {
                ...song('a', 'title-$seed'),
                'lastPlayed': '2026-10-02T10:00:00Z',
                'listeningCount': random.nextInt(99),
              },
            ],
          },
          baseline,
          'b',
        );
        if (seed.isEven) {
          c.capture({...baseline, 'recentlyPlayedSongs': []}, baseline, 'c');
        } else {
          c.capture(
            {
              ...baseline,
              'recentlyPlayedSongs': [
                {
                  ...song('a', 'other-$seed'),
                  'lastPlayed': '2026-10-02T10:00:00Z',
                  'listeningCount': random.nextInt(200),
                },
              ],
            },
            baseline,
            'c',
          );
        }
        expectConverges([a, b, c]);
      }
    },
  );

  test(
    'version-2 local metadata migrates without reviving a deleted month',
    () {
      const key = '["recapMonth","","2026-09"]';
      final live = SyncDocument.fromMap({
        'version': 2,
        'clock': 0,
        'records': {
          key: {
            'clock': 0,
            'device': '',
            'deleted': false,
            'value': month(300),
          },
        },
      });
      final removed = SyncDocument.fromMap({
        'version': 2,
        'clock': 1,
        'records': {
          key: {'clock': 1, 'device': 'a', 'deleted': true, 'value': null},
        },
      });
      live.join(removed);
      expect(live.toMap()['version'], syncSchemaVersion);
      expect(live.materialize()['wrappedListeningStats']['history'], isEmpty);
    },
  );
  test(
    'recap merge is associative for concurrent months, removals and resets',
    () {
      for (var seed = 0; seed < 50; seed++) {
        final random = Random(seed);
        final a = document({
          'wrappedListeningStats': recap(
            random.nextInt(500),
            history: {'2026-09': month(random.nextInt(500))},
          ),
        });
        final b = document({
          'wrappedListeningStats': recap(
            random.nextInt(500),
            history: {'2026-09': month(random.nextInt(500))},
          ),
        });
        final c = copyDocument(a);
        final before = c.materialize();
        c.capture(
          {
            'wrappedListeningStats': {
              ...recap(random.nextInt(100)),
              if (seed.isOdd) 'syncResetId': 'clear-$seed',
            },
          },
          before,
          'c',
        );
        expectConverges([a, b, c]);
      }
    },
  );
}

void expectConverges(List<SyncDocument> documents) {
  final [a, b, c] = documents;
  final expected = copyDocument(a)
    ..join(b)
    ..join(c);
  for (final order in [
    [a, b, c],
    [a, c, b],
    [b, a, c],
    [b, c, a],
    [c, a, b],
    [c, b, a],
  ]) {
    final sequential = copyDocument(order[0])
      ..join(order[1])
      ..join(order[2]);
    final tail = copyDocument(order[1])..join(order[2]);
    final grouped = copyDocument(order[0])..join(tail);
    for (final document in [sequential, grouped]) {
      expect(canonicalSync(document.records), canonicalSync(expected.records));
      document.join(document);
      expect(canonicalSync(document.records), canonicalSync(expected.records));
    }
  }
}
