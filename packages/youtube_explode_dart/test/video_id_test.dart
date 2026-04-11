import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'data.dart';

void main() {
  group('These are valid video ids', () {
    for (final val in VideoIdData.values) {
      test('VideoID - $val', () {
        expect(VideoId(val.id).value, val.id);
      });
    }
  });
  group('These are valid video urls', () {
    for (final val in {
      ['youtube.com/watch?v=yIVRs6YSbOM', 'yIVRs6YSbOM'],
      ['youtu.be/yIVRs6YSbOM', 'yIVRs6YSbOM'],
      ['youtube.com/embed/yIVRs6YSbOM', 'yIVRs6YSbOM'],
      ['youtube.com/live/yIVRs6YSbOM', 'yIVRs6YSbOM'],
    }) {
      test('Video - $val', () {
        expect(VideoId(val[0]).value, val[1]);
      });
    }
  });
  group('These are not valid video ids', () {
    for (final val in {'', 'pI2I2zqzeK', 'pI2I2z zeKg'}) {
      test('VideoID - $val', () {
        expect(() => VideoId(val), throwsArgumentError);
      });
    }
  });
  group('These are not valid video urls', () {
    for (final val in {
      'youtube.com/xxx?v=pI2I2zqzeKg',
      'youtu.be/watch?v=xxx',
      'youtube.com/embed',
      'youtube.com/live'
    }) {
      test('VideoURL - $val', () {
        expect(() => VideoId(val), throwsArgumentError);
      });
    }
  });
}
