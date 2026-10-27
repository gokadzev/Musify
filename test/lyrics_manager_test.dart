/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:musify/services/lyrics/lrc_parser.dart';
import 'package:musify/services/lyrics/lyrics_query.dart';
import 'package:musify/services/lyrics_manager.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('parseLrc', () {
    test('parses timestamps, fractions and sorts lines', () {
      final lines = parseLrc('[ar:Someone]\n[00:12.5]second\n[00:01.00]first');
      expect(lines.length, 2);
      expect(lines[0].text, 'first');
      expect(lines[0].start, const Duration(seconds: 1));
      expect(lines[1].start, const Duration(seconds: 12, milliseconds: 500));
    });

    test('supports multiple timestamps, word tags and offset', () {
      final lines = parseLrc(
        '[offset:500]\n[00:10.00][00:20.00]<00:10.00>hel<00:10.50>lo',
      );
      expect(lines.length, 2);
      expect(lines[0].text, 'hello');
      expect(lines[0].start, const Duration(seconds: 9, milliseconds: 500));
      expect(lines[1].start, const Duration(seconds: 19, milliseconds: 500));
    });

    test('ignores plain text and clamps negative times', () {
      expect(parseLrc('just text\nno tags'), isEmpty);
      expect(parseLrc('[offset:5000]\n[00:01.00]x').first.start, Duration.zero);
    });
  });

  group('Lyrics', () {
    test('lineIndexAt finds the active line', () {
      final lyrics = Lyrics(
        source: 't',
        synced: parseLrc('[00:05.00]a\n[00:10.00]b\n[00:15.00]c'),
      );
      expect(lyrics.lineIndexAt(const Duration(seconds: 1)), -1);
      expect(lyrics.lineIndexAt(const Duration(seconds: 5)), 0);
      expect(lyrics.lineIndexAt(const Duration(seconds: 12)), 1);
      expect(lyrics.lineIndexAt(const Duration(minutes: 5)), 2);
    });

    test('text falls back to synced lines', () {
      final lyrics = Lyrics(source: 't', synced: parseLrc('[00:01.00]a'));
      expect(lyrics.text, 'a');
      expect(lyrics.isSynced, isTrue);
    });
  });

  group('lyrics_query', () {
    test('cleanTitle removes YouTube decorations', () {
      expect(cleanTitle('Blinding Lights (Official Video)'), 'Blinding Lights');
      expect(cleanTitle('Song [Lyrics] feat. Someone'), 'Song');
      expect(cleanTitle('Song - Remastered 2011'), 'Song');
      expect(cleanTitle('Song Lyrics'), 'Song');
      expect(cleanTitle('Song | Official Audio'), 'Song');
      expect(cleanTitle('Song (Acoustic)'), 'Song (Acoustic)');
      expect(cleanTitle('Lyrics'), 'Lyrics');
    });

    test('cleanArtist keeps the primary artist', () {
      expect(cleanArtist('The Weeknd - Topic'), 'The Weeknd');
      expect(cleanArtist('Adele, Someone'), 'Adele');
      expect(cleanArtist('AdeleVEVO'), 'Adele');
      expect(cleanArtist('Simon & Garfunkel'), 'Simon & Garfunkel');
    });

    test('slugs fold accents and reject non-Latin text', () {
      expect(lyricsSlug('Beyoncé  Knowles'), 'beyonce-knowles');
      expect(lyricsSlug("Don't Stop!"), 'dont-stop');
      expect(lyricsSlug('فيروز'), '');
      expect(lyricsManiaSlug(' Hello World '), 'hello_world');
    });

    test('buildSearchVariants handles "Artist - Song" and swapped titles', () {
      final variants = buildSearchVariants(
        const TrackInfo(title: 'Queen - Bohemian Rhapsody', artist: 'Queen'),
      );
      expect(variants.first.artist, 'Queen');
      expect(variants.first.title, 'Bohemian Rhapsody');
      expect(
        variants.any(
          (v) => v.artist == 'Bohemian Rhapsody' && v.title == 'Queen',
        ),
        isTrue,
      );
      expect(variants.length, 3); // duplicates are removed
      expect(
        buildSearchVariants(const TrackInfo(title: 'Song', artist: 'Artist'))
            .length,
        1,
      );
    });
  });

  group('selectBestLrclibMatch', () {
    const track = TrackInfo(
      title: 'Song',
      artist: 'Artist',
      duration: Duration(seconds: 200),
    );

    test('prefers matching duration over a different version', () {
      final best = selectBestLrclibMatch([
        {
          'trackName': 'Song',
          'artistName': 'Artist',
          'duration': 260,
          'plainLyrics': 'live',
        },
        {
          'trackName': 'Song',
          'artistName': 'Artist',
          'duration': 201,
          'plainLyrics': 'studio',
        },
      ], track);
      expect(best!['plainLyrics'], 'studio');
    });

    test('rejects unrelated and instrumental results', () {
      expect(
        selectBestLrclibMatch([
          {
            'trackName': 'Other',
            'artistName': 'Artist',
            'duration': 200,
            'plainLyrics': 'x',
          },
          {
            'trackName': 'Song',
            'artistName': 'Artist',
            'instrumental': true,
            'plainLyrics': 'x',
          },
        ], track),
        isNull,
      );
    });
  });

  group('LyricsManager', () {
    setUp(LyricsManager.clearCache);

    test('returns synced LRCLIB lyrics when available', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'lrclib.net');
        return _json([
          {
            'trackName': 'Song',
            'artistName': 'Artist',
            'duration': 200,
            'plainLyrics': 'plain',
            'syncedLyrics': '[00:01.00]hello\n[00:05.00]world',
          },
        ]);
      });
      final result = await LyricsManager(client: client).fetchLyricsResult(
        const TrackInfo(
          title: 'Song (Official Video)',
          artist: 'Artist - Topic',
          duration: Duration(seconds: 200),
        ),
      );
      expect(result!.isSynced, isTrue);
      expect(result.source, 'lrclib.net');
      expect(result.synced!.length, 2);
    });

    test('falls back to lyrics.ovh and keeps fetchLyrics format', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'api.lyrics.ovh') {
          return _json({'lyrics': 'la la la'});
        }
        return _json([]);
      });
      final text = await LyricsManager(client: client)
          .fetchLyrics('Artist', 'Song');
      expect(text, 'la la la\n\n© lyrics.ovh');
    });

    test('caches results, including misses', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return _json([], 404);
      });
      final manager = LyricsManager(client: client);
      expect(await manager.fetchLyrics('Artist', 'Song'), isNull);
      final firstRunCalls = calls;
      expect(await manager.fetchLyrics('Artist', 'Song'), isNull);
      expect(calls, firstRunCalls);
    });

    test('does not request slug based sites for non-Latin titles', () async {
      final hosts = <String>{};
      final client = MockClient((request) async {
        hosts.add(request.url.host);
        return _json([], 404);
      });
      await LyricsManager(client: client).fetchLyrics('فيروز', 'كيفك');
      expect(hosts.contains('www.paroles.net'), isFalse);
      expect(hosts.contains('www.lyricsmania.com'), isFalse);
      expect(hosts.contains('lrclib.net'), isTrue);
    });

    test('returns null for empty input', () async {
      expect(await LyricsManager().fetchLyrics('', 'x'), isNull);
    });
  });
}
