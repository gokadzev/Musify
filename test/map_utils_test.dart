import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/map_utils.dart';

void main() {
  group('songYtid', () {
    test('normalizes IDs and rejects missing or empty IDs', () {
      expect(songYtid({'ytid': 123}), '123');
      expect(songYtid({'ytid': ''}), isNull);
      expect(songYtid({}), isNull);
    });
  });

  group('findSongByYtid', () {
    test('finds map entries by normalized ID and skips non-map entries', () {
      final song = {'ytid': 123, 'title': 'Example'};

      expect(
        findSongByYtid([
          null,
          {'title': 'Invalid'},
          song,
        ], '123'),
        song,
      );
    });

    test('returns null when no song matches', () {
      expect(
        findSongByYtid([
          {'ytid': 'other'},
        ], 'missing'),
        isNull,
      );
    });
  });
}
