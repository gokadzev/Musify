import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/desktop_media_artwork.dart';

Future<List<int>> _stripedImage(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final side = (width < height ? width : height).toDouble();
  ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xffff0000), ui.BlendMode.src)
    ..drawRect(
      ui.Rect.fromLTWH((width - side) / 2, (height - side) / 2, side, side),
      ui.Paint()..color = const ui.Color(0xff00aa00),
    );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return png!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('musify_media_artwork');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'landscape and portrait covers are center-cropped, not stretched',
    () async {
      for (final size in [(300, 100), (100, 300)]) {
        final bytes = await _stripedImage(size.$1, size.$2);
        final cache = DesktopMediaArtwork(
          cacheDirectory: () async => directory,
          read: (_) async => bytes,
        );
        final result = await cache.resolve(
          Uri.parse('https://example.com/${size.$1}.png'),
        );
        expect(result?.scheme, 'file');
        final file = File.fromUri(result!);
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        final image = (await codec.getNextFrame()).image;
        expect(image.width, 512);
        expect(image.height, 512);
        final pixels = (await image.toByteData())!;
        for (final point in [(64, 64), (448, 448), (256, 256)]) {
          final offset = (point.$2 * image.width + point.$1) * 4;
          expect(pixels.getUint32(offset), 0x00aa00ff);
        }
        image.dispose();
        codec.dispose();
      }
    },
  );

  test(
    'concurrent requests and subsequent sessions reuse the square image',
    () async {
      var reads = 0;
      final bytes = await _stripedImage(300, 100);
      final source = Uri.parse('https://example.com/cover.png');
      final cache = DesktopMediaArtwork(
        cacheDirectory: () async => directory,
        read: (_) async {
          reads++;
          return bytes;
        },
      );
      final results = await Future.wait([
        cache.resolve(source),
        cache.resolve(source),
      ]);
      expect(results.first, results.last);
      expect(reads, 1);
      final nextSession = DesktopMediaArtwork(
        cacheDirectory: () async => directory,
        read: (_) async {
          throw StateError('Must use the cached square');
        },
      );
      expect(await nextSession.resolve(source), results.first);
    },
  );

  test('missing artwork does not fail playback metadata', () async {
    final cache = DesktopMediaArtwork(
      cacheDirectory: () async => directory,
      read: (_) async {
        throw const HttpException('404');
      },
    );
    expect(
      await cache.resolve(Uri.parse('https://example.com/missing')),
      isNull,
    );
  });

  test(
    'slow covers cannot overwrite a newer track or update after disposal',
    () async {
      final first = Completer<Uri?>();
      final second = Completer<Uri?>();
      var changed = 0;
      final state =
          MediaArtworkState(
              resolve: (source) =>
                  source.path == '/first' ? first.future : second.future,
              onChanged: () {
                changed++;
              },
              onError: (error, _) => fail('$error'),
            )
            ..update(Uri.parse('https://example.com/first'))
            ..update(Uri.parse('https://example.com/second'));
      second.complete(Uri.file('/tmp/second.png'));
      await Future<void>.delayed(Duration.zero);
      expect(state.uri, Uri.file('/tmp/second.png'));
      first.complete(Uri.file('/tmp/first.png'));
      await Future<void>.delayed(Duration.zero);
      expect(state.uri, Uri.file('/tmp/second.png'));
      expect(changed, 1);
      state
        ..update(Uri.parse('https://example.com/first'))
        ..dispose();
      await Future<void>.delayed(Duration.zero);
      expect(changed, 1);
    },
  );
}
