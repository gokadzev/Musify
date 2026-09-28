import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/app_utils.dart';

/// A song YouTube refuses to hand over — anything marked as made for children,
/// among others — used to take the whole session down with it: the queue index
/// is rolled back on failure, so the retry asked for "the next song" and got
/// the one that had just failed, three times over, until playback stopped.
void main() {
  test('recovery steps past the song that failed, not back onto it', () {
    expect(queuePositionAfterFailure(0, 5), 1);
    expect(queuePositionAfterFailure(3, 5), 4);
  });

  test('a failure on the last song leaves nothing to resume at', () {
    expect(queuePositionAfterFailure(4, 5), isNull);
  });

  test('the only song of a queue failing leaves nothing to resume at', () {
    expect(queuePositionAfterFailure(0, 1), isNull);
  });

  test('an empty queue and a nonsense index give nothing back', () {
    expect(queuePositionAfterFailure(0, 0), isNull);
    expect(queuePositionAfterFailure(-1, 5), isNull);
  });

  test('a failure past the end of the queue gives nothing back', () {
    expect(queuePositionAfterFailure(9, 5), isNull);
  });
}
