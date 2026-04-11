import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  group('These are valid playlist ids', () {
    for (final val in {
      'PL601B2E69B03FAB9D',
      'PLI5YfMzCfRtZ8eV576YoY3vIYrHjyVm_e',
      'PLWwAypAcFRgKFlxtLbn_u14zddtDJj3mk',
      'OLAK5uy_mtOdjCW76nDvf5yOzgcAVMYpJ5gcW5uKU',
      'RD1hu8-y6fKg0',
      'RDMMU-ty-2B02VY',
      'RDCLAK5uy_lf8okgl2ygD075nhnJVjlfhwp8NsUgEbs',
      'ULl6WWX-BgIiE',
      'UUTMt7iMWa7jy0fNXIktwyLA',
      'FLEnBXANsKmyj2r9xVyKoDiQ',
    }) {
      test('PlaylistID - $val', () {
        final playlist = PlaylistId(val);
        expect(playlist.value, val);
      });
    }
  });

  group('These are valid playlist urls', () {
    for (final val in {
      [
        PlaylistId(
          'youtube.com/playlist?list=PLOU2XLYxmsIJGErt5rrCqaSGTMyyqNt2H',
        ),
        'PLOU2XLYxmsIJGErt5rrCqaSGTMyyqNt2H',
      ],
      [
        PlaylistId(
          'youtube.com/watch?v=b8m9zhNAgKs&list=PL9tY0BWXOZFuFEG_GtOBZ8-8wbkH-NVAr',
        ),
        'PL9tY0BWXOZFuFEG_GtOBZ8-8wbkH-NVAr',
      ],
      [
        PlaylistId(
          'youtu.be/b8m9zhNAgKs/?list=PL9tY0BWXOZFuFEG_GtOBZ8-8wbkH-NVAr',
        ),
        'PL9tY0BWXOZFuFEG_GtOBZ8-8wbkH-NVAr',
      ],
      [
        PlaylistId(
          'youtube.com/embed/b8m9zhNAgKs/?list=PL9tY0BWXOZFuFEG_GtOBZ8-8wbkH-NVAr',
        ),
        'PL9tY0BWXOZFuFEG_GtOBZ8-8wbkH-NVAr',
      ],
      [
        PlaylistId(
          'youtube.com/watch?v=x2ZRoWQ0grU&list=RDEMNJhLy4rECJ_fG8NL-joqsg',
        ),
        'RDEMNJhLy4rECJ_fG8NL-joqsg',
      ],
      [
        PlaylistId(
          'youtube.com/watch?v=b8m9zhNAgKs&list=PL9tY0BWXOZFuFEG_GtOBZ8-8wbkH-NVAr',
        ),
        'PL9tY0BWXOZFuFEG_GtOBZ8-8wbkH-NVAr',
      ],
    }) {
      test('PlaylistID - ${val[0]}', () {
        expect((val[0] as PlaylistId).value, val[1]);
      });
    }
  });

  group('These are not valid playlist ids', () {
    for (final val in {
      'PLm_3vnTS-pvmZFuF L1Pyhqf8kTTYVKjW',
      'PLm_3vnTS-pvmZFuF3L=Pyhqf8kTTYVKjW',
    }) {
      test('PlaylistID - $val', () {
        expect(() => PlaylistId(val), throwsArgumentError);
      });
    }
  });

  group('These are not valid playlist urls', () {
    for (final val in {
      'youtube.com/',
    }) {
      test('PlaylistURL - $val', () {
        expect(() => PlaylistId(val), throwsArgumentError);
      });
    }
  });
}
