import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  group('These are valid usernames', () {
    for (final val in {
      'TheTyrrr',
      'KannibalenRecords',
      'JClayton1994',
      'The_Tyrrr',
      'A1B2C3-',
      '=0123456789ABCDEF',
    }) {
      test('Username - $val', () {
        expect(Username(val).value, val);
      });
    }
  });
  group('These are valid username urls', () {
    for (final val in {
      ['youtube.com/user/ProZD', 'ProZD'],
      ['youtube.com/user/TheTyrrr', 'TheTyrrr'],
      ['youtube.com/user/P_roZD', 'P_roZD'],
    }) {
      test('UsernameURL - $val', () {
        expect(Username(val[0]).value, val[1]);
      });
    }
  });
  group('These are invalid usernames', () {
    for (final val in {
      '0123456789ABCDEFGHIJK',
    }) {
      test('Username - $val', () {
        expect(() => Username(val), throwsArgumentError);
      });
    }
  });

  group('These are not valid username urls', () {
    for (final val in {
      'example.com/user/ProZD',
    }) {
      test('UsernameURL - $val', () {
        expect(() => Username(val), throwsArgumentError);
      });
    }
  });
}
