import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/queue_entry_utils.dart';

void main() {
  group('indexAfterQueueReorder', () {
    test('moves the selected entry to its new index', () {
      expect(indexAfterQueueReorder(2, 2, 5), 5);
    });

    test('adjusts indexes shifted by the move', () {
      expect(indexAfterQueueReorder(3, 1, 4), 2);
      expect(indexAfterQueueReorder(2, 4, 1), 3);
    });

    test('leaves unaffected indexes unchanged', () {
      expect(indexAfterQueueReorder(-1, 2, 4), -1);
      expect(indexAfterQueueReorder(5, 1, 3), 5);
    });
  });

  group('appendedQueueIndexForSourceIndex', () {
    test('accounts for existing queue entries', () {
      expect(
        appendedQueueIndexForSourceIndex(
          [
            {'ytid': 'first'},
            {'ytid': 'selected'},
          ],
          1,
          4,
        ),
        5,
      );
    });

    test('accounts for invalid songs skipped during append', () {
      expect(
        appendedQueueIndexForSourceIndex(
          [
            {'title': 'invalid'},
            {'ytid': 'selected'},
          ],
          1,
          4,
        ),
        4,
      );
      expect(
        appendedQueueIndexForSourceIndex(
          [
            {'ytid': 'first'},
            {'title': 'invalid'},
            {'ytid': 'selected'},
          ],
          2,
          4,
        ),
        5,
      );
    });

    test('returns null for an invalid source index or invalid target song', () {
      expect(appendedQueueIndexForSourceIndex([], 0, 3), isNull);
      expect(
        appendedQueueIndexForSourceIndex(
          [
            {'title': 'invalid'},
          ],
          0,
          3,
        ),
        isNull,
      );
    });
  });

  group('shuffleQueueOrder', () {
    test('keeps current first and manual songs immediately after it', () {
      final queueEntryIds = QueueEntryIdManager();
      final currentSong = {'ytid': 'current'};
      final firstSong = {'ytid': 'first'};
      final manualSong = {'ytid': 'manual'};
      final lastSong = {'ytid': 'last'};
      final manualSongId = queueEntryIds.ensureId(manualSong);

      final result = shuffleQueueOrder(
        songs: [firstSong, currentSong, manualSong, lastSong],
        currentSong: currentSong,
        unplayedManualSongs: [manualSong],
        manualSongIds: {manualSongId},
        queueEntryIds: queueEntryIds,
      );

      expect(result.currentIndex, 0);
      expect(result.songs[0], same(currentSong));
      expect(result.songs[1], same(manualSong));
      expect(result.songs.skip(2).map((song) => song['ytid']).toSet(), {
        'first',
        'last',
      });
      expect(result.songs, hasLength(4));
    });
  });

  group('restoreQueueOrder', () {
    test(
      'restores original order and reinserts manual songs after current',
      () {
        final queueEntryIds = QueueEntryIdManager();
        final currentSong = {'ytid': 'current'};
        final manualSong = {'ytid': 'manual'};
        final manualSongId = queueEntryIds.ensureId(manualSong);

        final result = restoreQueueOrder(
          originalSongs: [
            {'ytid': 'first'},
            currentSong,
            manualSong,
            {'ytid': 'last'},
          ],
          currentSong: currentSong,
          unplayedManualSongs: [manualSong],
          manualSongIds: {manualSongId},
          queueEntryIds: queueEntryIds,
        );

        expect(result.currentIndex, 1);
        expect(result.songs.map((song) => song['ytid']), [
          'first',
          'current',
          'manual',
          'last',
        ]);
      },
    );

    test('restores a missing current song at the front', () {
      final queueEntryIds = QueueEntryIdManager();
      final currentSong = {'ytid': 'current'};

      final result = restoreQueueOrder(
        originalSongs: [
          {'ytid': 'first'},
          {'ytid': 'last'},
        ],
        currentSong: currentSong,
        unplayedManualSongs: const [],
        manualSongIds: const {},
        queueEntryIds: queueEntryIds,
      );

      expect(result.currentIndex, 0);
      expect(result.songs.map((song) => song['ytid']), [
        'current',
        'first',
        'last',
      ]);
    });
  });
}
