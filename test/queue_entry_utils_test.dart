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
}
