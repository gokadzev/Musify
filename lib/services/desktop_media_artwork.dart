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
  static const maxCacheEntries = 64;
  static const maxCacheBytes = 32 * 1024 * 1024;
  final _pending = <Uri, Future<Uri?>>{};
  final _recent = <String>[];
  Future<void> _maintenance = Future.value();

  Future<Uri?> resolve(Uri source) {
    final key = sha256.convert(utf8.encode(source.toString())).toString();
    _recent
      ..remove(key)
      ..add(key);
    if (_recent.length > 2) _recent.removeAt(0);
    final existing = _pending[source];
    if (existing != null) return existing;
    final future = _resolve(source, key);
    _pending[source] = future;
    unawaited(
      future.whenComplete(() {
        _pending.remove(source);
      }),
    );
    return future;
  }

  Future<Uri?> _resolve(Uri source, String key) async {
    try {
      final root = await _directory();
      final directory = await Directory('${root.path}/musify-media-artwork')
          .create(recursive: true);
      final file = File('${directory.path}/$key.png');
      if (!await file.exists()) {
        final bytes = await _read(source).timeout(const Duration(seconds: 8));
        final png = await _square(bytes);
        final staging = await directory.createTemp('.pending-');
        final temporary = File('${staging.path}/$key.png');
        try {
          await temporary.writeAsBytes(png, flush: true);
          try {
            await temporary.rename(file.path);
          } on FileSystemException {
            if (!await file.exists()) rethrow;
          }
        } finally {
          await staging.delete(recursive: true);
        }
      }
      await file.setLastModified(DateTime.now());
      _maintenance = _maintenance
          .then((_) => _prune(directory))
          .catchError((_) {});
      await _maintenance;
      return file.uri;
    } catch (_) {
      return null;
    }
  }

  Future<void> _prune(Directory directory) async {
    final files = <({File file, FileStat stat, bool protected})>[];
    final pattern = RegExp(r'[/\\]([a-f0-9]{64})\.png$');
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final match = pattern.firstMatch(entity.path);
      if (match == null) continue;
      try {
        final stat = await entity.stat();
        if (stat.type == FileSystemEntityType.file) {
          files.add((
            file: entity,
            stat: stat,
            protected: _recent.contains(match[1]),
          ));
        }
      } on FileSystemException {
        // Another process may have removed the file.
      }
    }
    files.sort((a, b) {
      if (a.protected != b.protected) return a.protected ? -1 : 1;
      return b.stat.modified.compareTo(a.stat.modified);
    });
    var bytes = 0;
    var entries = 0;
    for (final item in files) {
      if (item.protected ||
          (entries < maxCacheEntries &&
              bytes + item.stat.size <= maxCacheBytes)) {
        entries++;
        bytes += item.stat.size;
        continue;
      }
      try {
        await item.file.delete();
      } on FileSystemException {
        // Cache cleanup must not prevent playback metadata updates.
      }
    }
  }

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
