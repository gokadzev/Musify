import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

typedef MediaArtworkResolver = Future<Uri?> Function(Uri source);

/// Keeps slow artwork loads independent of transport controls and track changes.
class MediaArtworkState {
  MediaArtworkState({
    required this.onChanged,
    required this.onError,
    this.resolve,
  });

  final void Function() onChanged;
  final void Function(Object, StackTrace) onError;
  final MediaArtworkResolver? resolve;
  Uri? _source;
  Uri? uri;
  int _generation = 0;

  void update(Uri? source) {
    if (source == _source) return;
    _source = source;
    final generation = ++_generation;
    uri = resolve == null ? source : null;
    if (source == null || resolve == null) return;
    unawaited(
      Future<Uri?>.sync(() => resolve!(source))
          .then((result) {
            if (generation != _generation) return;
            uri = result;
            onChanged();
          })
          .catchError((Object error, StackTrace stack) {
            if (generation == _generation) onError(error, stack);
          }),
    );
  }

  void dispose() {
    _generation++;
  }
}

/// Supplies square, cropped covers to MPRIS and SMTC without stretching them.
class DesktopMediaArtwork {
  DesktopMediaArtwork({
    Future<Directory> Function()? cacheDirectory,
    Future<List<int>> Function(Uri)? read,
  }) : _directory = cacheDirectory ?? getTemporaryDirectory,
       _read = read ?? _readSource;

  final Future<Directory> Function() _directory;
  final Future<List<int>> Function(Uri) _read;
  final _pending = <Uri, Future<Uri?>>{};

  Future<Uri?> resolve(Uri source) => _pending.putIfAbsent(source, () async {
    try {
      final root = await _directory();
      final directory = await Directory('${root.path}/musify-media-artwork')
          .create(recursive: true);
      final key = sha256.convert(utf8.encode(source.toString()));
      final file = File('${directory.path}/$key.png');
      if (!await file.exists()) {
        final bytes = await _read(source).timeout(const Duration(seconds: 8));
        final png = await _square(bytes);
        await file.writeAsBytes(png, flush: true);
      }
      if (_pending.length > 64) {
        final oldest = _pending.keys.firstWhere((key) => key != source);
        _pending.remove(oldest)?.ignore();
      }
      return file.uri;
    } catch (_) {
      return null;
    }
  });

  static Future<List<int>> _readSource(Uri source) async {
    if (source.scheme == 'file') return File.fromUri(source).readAsBytes();
    if (source.scheme != 'https' && source.scheme != 'http') {
      throw ArgumentError('Unsupported artwork URI');
    }
    final client = http.Client();
    try {
      final response = await client
          .get(source)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200)
        throw HttpException('Artwork HTTP ${response.statusCode}');
      return response.bodyBytes;
    } finally {
      client.close();
    }
  }

  static Future<List<int>> _square(List<int> bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      Uint8List.fromList(bytes),
    );
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = descriptor.width > 1024 ? 1024 : descriptor.width;
    final codec = await descriptor.instantiateCodec(targetWidth: width);
    ui.Image? image;
    ui.Image? square;
    ui.Picture? picture;
    try {
      image = (await codec.getNextFrame()).image;
      final side = (image.width < image.height ? image.width : image.height)
          .toDouble();
      final source = ui.Rect.fromLTWH(
        (image.width - side) / 2,
        (image.height - side) / 2,
        side,
        side,
      );
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        image,
        source,
        const ui.Rect.fromLTWH(0, 0, 512, 512),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      picture = recorder.endRecording();
      square = await picture.toImage(512, 512);
      final png = await square.toByteData(format: ui.ImageByteFormat.png);
      return png!.buffer.asUint8List();
    } finally {
      square?.dispose();
      picture?.dispose();
      image?.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }
}
