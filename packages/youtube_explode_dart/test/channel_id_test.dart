import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  group('These are valid channel ids', () {
    for (final val in {
      [ChannelId('UCEnBXANsKmyj2r9xVyKoDiQ'), 'UCEnBXANsKmyj2r9xVyKoDiQ'],
      [ChannelId('UCqKbtOLx4NCBh5KKMSmbX0g'), 'UCqKbtOLx4NCBh5KKMSmbX0g'],
    }) {
      test('ChannelID - ${val[0]}', () {
        expect((val[0] as ChannelId).value, val[1]);
      });
    }
  });
  group('These are valid channel urls', () {
    for (final val in {
      [
        ChannelId('youtube.com/channel/UC3xnGqlcL3y-GXz5N3wiTJQ'),
        'UC3xnGqlcL3y-GXz5N3wiTJQ',
      ],
      [
        ChannelId('youtube.com/channel/UCkQO3QsgTpNTsOw6ujimT5Q'),
        'UCkQO3QsgTpNTsOw6ujimT5Q',
      ],
      [
        ChannelId('youtube.com/channel/UCQtjJDOYluum87LA4sI6xcg'),
        'UCQtjJDOYluum87LA4sI6xcg',
      ]
    }) {
      test('ChannelURL - ${val[0]}', () {
        expect((val[0] as ChannelId).value, val[1]);
      });
    }
  });

  group('These are not valid channel ids', () {
    for (final val in {
      '',
      'UC3xnGqlcL3y-GXz5N3wiTJ',
      'UC3xnGqlcL y-GXz5N3wiTJQ',
    }) {
      test('ChannelID - $val', () {
        expect(() => ChannelId(val), throwsArgumentError);
      });
    }
  });

  group('These are not valid channel urls', () {
    for (final val in {
      'youtube.com/?channel=UCUC3xnGqlcL3y-GXz5N3wiTJQ',
      'youtube.com/channel/asd',
      'youtube.com/',
    }) {
      test('ChannelURL - $val', () {
        expect(() => ChannelId(val), throwsArgumentError);
      });
    }
  });
}
