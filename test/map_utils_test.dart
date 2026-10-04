import 'dart:math';

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

  group('sampleUniqueSongs', () {
    test(
      'returns at most the requested number of unique songs across sources',
      () {
        final recommendations = sampleUniqueSongs(
          [
            [
              {'ytid': 'one'},
              {'ytid': 'two'},
              {'ytid': 'one'},
            ],
            [
              {'ytid': 'three'},
              {'ytid': 'four'},
              {'ytid': ''},
              'invalid',
            ],
          ],
          3,
          random: Random(1),
        );

        expect(recommendations, hasLength(3));
        expect(
          recommendations.map(songYtid).toSet().length,
          recommendations.length,
        );
        expect(
          recommendations
              .map(songYtid)
              .every((ytid) => {'one', 'two', 'three', 'four'}.contains(ytid)),
          isTrue,
        );
      },
    );

    test('returns an empty sample for nonpositive limits', () {
      expect(sampleUniqueSongs([[]], 0), isEmpty);
      expect(sampleUniqueSongs([[]], -1), isEmpty);
    });
  });
}
