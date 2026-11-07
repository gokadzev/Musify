import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/local_sync/sync_merge.dart';

import 'fixtures.dart';

Map<String, dynamic> _cell(
  Object? value, {
  int clock = 1,
  bool deleted = false,
}) => {'clock': clock, 'device': 'd', 'deleted': deleted, 'value': value};

Map<String, dynamic> _rawDocument(
  Map<String, Object?> records, {
  int clock = 1,
}) => {'version': 3, 'clock': clock, 'records': records};

String _key(String kind, String parent, String id) =>
    jsonEncode([kind, parent, id]);

void main() {
  const hostile = [
    '../../x',
    '..',
    'a/b',
    '/etc/passwd',
    r'a\b',
    r'..\..\x',
    'a..b',
    'tab\there',
    'line\nbreak',
    'nul\u0000',
    'del\u007f',
  ];
  final tooLong = 'x' * 129;

  group('ids', () {
    test('ids from YouTube, local files and playlists are accepted', () {
      for (final id in [
        'dQw4w9WgXcQ',
        '-_abcDEF012',
        'local:0123abcd',
        'file:12',
        'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx',
        'OLAK5uy_mYtvEi2dTgR6y1ubZrcxzP4pDp8Ot7MbU',
        'UCuAXFkgsw1L7xaCfnd5JJOw',
        'r_cap_london',
        'x' * 128,
      ]) {
        final doc = SyncDocument.fromMap(
          _rawDocument({
            _key('likedSongs', '', id): _cell({'ytid': id, 'title': 't'}),
            _key('likedSongsOrder', '', ''): _cell([id]),
            _key('playlists', '', id): _cell(true),
          }),
        );
        expect(doc.records, hasLength(3), reason: id);
      }
    });

    test('an id that could leave its folder is refused wherever it sits', () {
      for (final id in [...hostile, tooLong]) {
        final reason = 'id ${jsonEncode(id)}';
        Map<String, dynamic> one(
          String kind,
          String parent,
          String key,
          Object? value,
        ) => _rawDocument({_key(kind, parent, key): _cell(value)});
        final bad = [
          one('likedSongs', '', id, {'ytid': id}),
          one('playlistSong', 'list', id, {'ytid': id}),
          one('playlistSong', id, 'song', {'ytid': 'song'}),
          one('playlistSongOrder', id, '', ['song']),
          one('likedSongsOrder', '', '', [id]),
          one('playlists', '', id, true),
          one('pinnedPlaylistIds', '', id, true),
          one('likedRadioStations', '', id, true),
          one('customPlaylists', '', id, {'ytid': id, 'title': 't'}),
          one('playlistFolders', '', id, {'id': id, 'title': 't'}),
        ];
        for (final doc in bad) {
          expect(
            () => SyncDocument.fromMap(doc),
            throwsA(isA<FormatException>()),
            reason: '$reason in ${doc['records']}',
          );
        }
        // Gone or not, a record that names such a path is not accepted.
        expect(
          () => SyncDocument.fromMap(
            _rawDocument({
              _key('likedSongs', '', id): _cell(null, deleted: true),
            }),
          ),
          throwsA(isA<FormatException>()),
          reason: '$reason deleted',
        );
      }
    });

    test('what a person searches for is free text', () {
      for (final text in [
        'AC/DC',
        'a..b',
        r'C:\music',
        'tab\there',
        'x' * 500,
      ]) {
        final doc = SyncDocument.fromMap(
          _rawDocument({
            _key('searchHistory', '', text): _cell(true),
            _key('searchHistoryOrder', '', ''): _cell([text]),
          }),
        );
        expect(doc.records, hasLength(2), reason: text);
      }
    });

    test('a library with such an id still syncs the rest', () {
      final doc = document({
        'likedSongs': [
          song('good'),
          song('../../escape'),
          song('also/bad'),
          {'title': 'no id'},
        ],
        'customPlaylists': [
          playlist('mine', ['fine', '../song', 'ok']),
        ],
        'searchHistory': ['AC/DC'],
      });
      final keys = doc.records.keys.toList();
      expect(keys.any((k) => k.contains('good')), true);
      expect(
        keys.any((k) => k.contains('escape') || k.contains('also')),
        false,
      );
      expect(keys.any((k) => k.contains('fine')), true);
      expect(keys.any((k) => k.contains('ok')), true);
      expect(keys.any((k) => k.contains('../song')), false);
      expect(keys.any((k) => k.contains('AC/DC')), true);
      // And what it exports is what it accepts back.
      expect(SyncDocument.fromMap(doc.toMap()).records, hasLength(keys.length));
    });

    test('a custom playlist or folder with such an id stops the capture', () {
      expect(
        () => document({
          'customPlaylists': [
            playlist('../x', ['a']),
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => document({
          'playlistFolders': [
            {'id': 'a/b', 'title': 'f', 'playlists': []},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('clock', () {
    const limit = 1 << 53;

    test('a clock up to 2^53 is accepted', () {
      final doc = SyncDocument.fromMap(
        _rawDocument({
          _key('likedSongs', '', 'a'): _cell({'ytid': 'a'}, clock: limit),
        }, clock: limit),
      );
      expect(doc.clock, limit);
    });

    test('a larger clock is refused, in the document and in a record', () {
      for (final huge in [limit + 1, 1 << 62, 9223372036854775807]) {
        expect(
          () => SyncDocument.fromMap(_rawDocument({}, clock: huge)),
          throwsA(isA<FormatException>()),
          reason: 'document $huge',
        );
        expect(
          () => SyncDocument.fromMap(
            _rawDocument({
              _key('likedSongs', '', 'a'): _cell({'ytid': 'a'}, clock: huge),
            }),
          ),
          throwsA(isA<FormatException>()),
          reason: 'record $huge',
        );
      }
    });

    test('an ordinary clock is untouched by a merge with a hostile one', () {
      final mine = document({
        'likedSongs': [song('a')],
      });
      final hostileMap = mine.toMap();
      hostileMap['clock'] = 1 << 62;
      expect(() => SyncDocument.fromMap(hostileMap), throwsFormatException);
      expect(mine.clock, lessThan(100));
    });
  });
}
