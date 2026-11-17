import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/app_utils.dart';

/// gokadzev/Musify#957: the previous button always stepped back a song, so
/// replaying the one playing meant going back and then forward again, which
/// counts songs as played that nobody asked to hear.
void main() {
  group('skipBackRestartsSong', () {
    test('a press right at the start steps back a song', () {
      expect(
        skipBackRestartsSong(
          position: Duration.zero,
          hasPrevious: true,
        ),
        isFalse,
      );
      expect(
        skipBackRestartsSong(
          position: const Duration(seconds: 4, milliseconds: 999),
          hasPrevious: true,
        ),
        isFalse,
      );
    });

    test('once into the song, back restarts it', () {
      expect(
        skipBackRestartsSong(
          position: skipBackRestartThreshold,
          hasPrevious: true,
        ),
        isTrue,
      );
      expect(
        skipBackRestartsSong(
          position: const Duration(minutes: 2),
          hasPrevious: true,
        ),
        isTrue,
      );
    });

    test('the first song of a queue restarts whenever back is pressed', () {
      expect(
        skipBackRestartsSong(
          position: Duration.zero,
          hasPrevious: false,
        ),
        isTrue,
      );
    });

    test('the threshold is adjustable', () {
      expect(
        skipBackRestartsSong(
          position: const Duration(seconds: 3),
          hasPrevious: true,
          threshold: const Duration(seconds: 2),
        ),
        isTrue,
      );
    });
  });
}
