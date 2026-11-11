import 'package:flutter_test/flutter_test.dart';
import 'package:musify/models/song_chapter.dart';
import 'package:musify/utilities/chapter_parser.dart';

void main() {
  const hour = Duration(hours: 1);

  group('parseChapters', () {
    test('reads a plain tracklist', () {
      final chapters = parseChapters('''
Comptines pour les petits

00:00 Une souris verte
02:14 Ainsi font font font
04:51 Petit escargot
''', duration: const Duration(minutes: 7));

      expect(chapters.map((chapter) => chapter.title), [
        'Une souris verte',
        'Ainsi font font font',
        'Petit escargot',
      ]);
      expect(chapters.first.start, Duration.zero);
      expect(chapters[1].start, const Duration(minutes: 2, seconds: 14));
      expect(chapters.last.end, const Duration(minutes: 7));
    });

    test('reads hours, and a timestamp written after the title', () {
      final chapters = parseChapters('''
Une souris verte - 0:00
Ainsi font font font - 34:20
Petit escargot - 1:02:33
''', duration: hour + const Duration(minutes: 10));

      expect(chapters.map((chapter) => chapter.title), [
        'Une souris verte',
        'Ainsi font font font',
        'Petit escargot',
      ]);
      expect(
        chapters.last.start,
        hour + const Duration(minutes: 2, seconds: 33),
      );
    });

    test('drops the numbering uploaders put in front of titles', () {
      final chapters = parseChapters('''
1. Une souris verte 00:00
2. Ainsi font font font 02:14
3. Petit escargot 04:51
''');

      expect(chapters.map((chapter) => chapter.title), [
        'Une souris verte',
        'Ainsi font font font',
        'Petit escargot',
      ]);
    });

    test('chains each chapter to the start of the next one', () {
      final chapters = parseChapters('''
00:00 Une souris verte
02:14 Ainsi font font font
04:51 Petit escargot
''', duration: const Duration(minutes: 7));

      expect(chapters.first.end, chapters[1].start);
      expect(chapters[1].end, chapters.last.start);
      expect(chapters.first.contains(const Duration(minutes: 1)), isTrue);
      expect(chapters.first.contains(const Duration(minutes: 3)), isFalse);
    });

    test('ignores a tracklist that does not open the video', () {
      final chapters = parseChapters('''
Written and sung at 03:00
Mixed at 06:00
Mastered at 09:00
''', duration: const Duration(minutes: 12));

      expect(chapters, isEmpty);
    });

    test('ignores a lone timestamp and bare timestamps', () {
      expect(parseChapters('Live from 00:00 to 59:00'), isEmpty);
      expect(parseChapters('00:00\n02:14\n04:51\n07:02'), isEmpty);
      expect(parseChapters(null), isEmpty);
      expect(parseChapters(''), isEmpty);
    });

    test('skips entries out of order, repeated, or past the end', () {
      final chapters = parseChapters('''
00:00 Une souris verte
02:14 Ainsi font font font
02:16 Ainsi font font font (reprise)
01:00 Ignorée
04:51 Petit escargot
09:30 Bonus
''', duration: const Duration(minutes: 7));

      expect(chapters.map((chapter) => chapter.title), [
        'Une souris verte',
        'Ainsi font font font',
        'Petit escargot',
      ]);
    });

    test('keeps a timestamp out of a longer run of digits', () {
      expect(
        parseChapters('''
00:00 Une souris verte
Remixed 12:34:56:78
02:14 Ainsi font font font
04:51 Petit escargot
''', duration: const Duration(minutes: 7)).length,
        3,
      );
    });

    test('leaves the last chapter open when the length is unknown', () {
      final chapters = parseChapters('''
00:00 Une souris verte
02:14 Ainsi font font font
04:51 Petit escargot
''');

      expect(chapters.last.contains(const Duration(minutes: 30)), isTrue);
    });
  });

  group('SongChapters.indexAt', () {
    final chapters = SongChapters(
      songId: 'abc',
      chapters: parseChapters('''
00:00 Une souris verte
02:14 Ainsi font font font
04:51 Petit escargot
''', duration: const Duration(minutes: 7)),
    );

    test('finds the chapter playing at a position', () {
      expect(chapters.indexAt(Duration.zero), 0);
      expect(chapters.indexAt(const Duration(minutes: 2, seconds: 13)), 0);
      expect(chapters.indexAt(const Duration(minutes: 2, seconds: 14)), 1);
      expect(chapters.indexAt(const Duration(minutes: 6)), 2);
    });

    test('reports no chapter when there are none', () {
      expect(const SongChapters.none('abc').indexAt(Duration.zero), -1);
    });
  });
}
