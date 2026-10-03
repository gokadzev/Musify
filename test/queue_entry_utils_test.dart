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
}
