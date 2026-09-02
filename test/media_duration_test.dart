import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/media_duration.dart';

void main() {
  group('readMediaDuration', () {
    test('accepts the duration formats stored in song maps', () {
      expect(readMediaDuration(185), const Duration(seconds: 185));
      expect(readMediaDuration(185.5), const Duration(milliseconds: 185500));
      expect(readMediaDuration('185'), const Duration(seconds: 185));
      expect(
        readMediaDuration('03:05'),
        const Duration(minutes: 3, seconds: 5),
      );
      expect(
        readMediaDuration('01:03:05'),
        const Duration(hours: 1, minutes: 3, seconds: 5),
      );
    });

    test('treats zero, negative, and malformed values as unknown', () {
      expect(readMediaDuration(null), isNull);
      expect(readMediaDuration(0), isNull);
      expect(readMediaDuration(-1), isNull);
      expect(readMediaDuration(double.infinity), isNull);
      expect(readMediaDuration('00:00'), isNull);
      expect(readMediaDuration('unknown'), isNull);
    });
  });

  group('preferStableMediaDuration', () {
    test('does not replace a known duration with an invalid report', () {
      const known = Duration(minutes: 3);

      expect(preferStableMediaDuration(known, Duration.zero), known);
    });

    test('accepts an initial or corrected player duration', () {
      const reported = Duration(minutes: 3);

      expect(preferStableMediaDuration(null, reported), reported);
      expect(
        preferStableMediaDuration(const Duration(minutes: 4), reported),
        reported,
      );
    });

    test('preserves a known total for clipped segment reports', () {
      const known = Duration(minutes: 3);
      const segment = Duration(seconds: 40);

      expect(
        preferStableMediaDuration(known, segment, preserveLongerKnown: true),
        known,
      );
    });
  });
}
