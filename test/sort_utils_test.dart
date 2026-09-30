import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/sort_utils.dart';

void main() {
  group('sortSongsByKey', () {
    test('sorts case-insensitively without mutating the input', () {
      final songs = [
        {'ytid': '1', 'title': 'b'},
        {'ytid': '2', 'title': 'A'},
        {'ytid': '3', 'title': 'c'},
      ];

      final sorted = sortSongsByKey(songs, 'title');

      expect(sorted.map((s) => s['ytid']), ['2', '1', '3']);
      expect(songs.map((s) => s['ytid']), ['1', '2', '3']);
    });

    test('is stable for equal keys and tolerates missing keys', () {
      final songs = [
        {'ytid': '1', 'artist': 'x'},
        {'ytid': '2'},
        {'ytid': '3', 'artist': 'X'},
        {'ytid': '4', 'artist': 'x'},
      ];

      final sorted = sortSongsByKey(songs, 'artist');

      expect(sorted.map((s) => s['ytid']), ['2', '1', '3', '4']);
    });
  });

  group('sortSongsNewestFirst', () {
    test('puts the last appended song first and keeps the input intact', () {
      final songs = [
        {'ytid': '1'},
        {'ytid': '2'},
      ];

      final sorted = sortSongsNewestFirst(songs);
      songs.add({'ytid': '3'});

      expect(sorted.map((s) => s['ytid']), ['2', '1']);
      expect(sortSongsNewestFirst(songs).first['ytid'], '3');
    });
  });
}
