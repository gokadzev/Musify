/// This file is a part of flutter_media_metadata (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: missing_js_lib_annotation

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:js/js.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:flutter_media_metadata/src/models/metadata.dart';

/// ## MetadataRetriever
///
/// Use [MetadataRetriever.fromBytes] to extract [Metadata] from bytes of media file.
///
/// ```dart
/// final metadata = MetadataRetriever.fromBytes(byteData);
/// String? trackName = metadata.trackName;
/// List<String>? trackArtistNames = metadata.trackArtistNames;
/// String? albumName = metadata.albumName;
/// String? albumArtistName = metadata.albumArtistName;
/// int? trackNumber = metadata.trackNumber;
/// int? albumLength = metadata.albumLength;
/// int? year = metadata.year;
/// String? genre = metadata.genre;
/// String? authorName = metadata.authorName;
/// String? writerName = metadata.writerName;
/// int? discNumber = metadata.discNumber;
/// String? mimeType = metadata.mimeType;
/// int? trackDuration = metadata.trackDuration;
/// int? bitrate = metadata.bitrate;
/// Uint8List? albumArt = metadata.albumArt;
/// ```
///
class MetadataRetriever {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'flutter_media_metadata',
      const StandardMethodCodec(),
      registrar,
    );
    final pluginInstance = MetadataRetriever();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) => throw PlatformException(
        code: 'Unimplemented',
        details:
            'flutter_media_metadata for web doesn\'t implement \'${call.method}\'',
      );

  /// Extracts [Metadata] from a [File]. Works on Windows, Linux, macOS, Android & iOS.
  static Future<Metadata> fromFile(dynamic _) async {
    throw UnimplementedError(
      '[MetadataRetriever.fromFile] is not supported on web. This method is only available for Windows, Linux, macOS, Android or iOS. Use [MetadataRetriever.fromBytes] instead.',
    );
  }

  /// Extracts [Metadata] from [Uint8List]. Works only on Web.
  static Future<Metadata> fromBytes(Uint8List bytes) {
    final completer = Completer<Metadata>();
    MediaInfo(
      _Opts(
        chunkSize: 256 * 1024,
        coverData: true,
        format: 'JSON',
      ),
      allowInterop(
        (mediainfo) {
          mediainfo
              .analyzeData(
            allowInterop(() => bytes.length),
            allowInterop(
              (chunkSize, offset) => _Promise(
                allowInterop(
                  (resolve, reject) {
                    resolve(
                      bytes.sublist(
                        offset,
                        offset + chunkSize,
                      ),
                    );
                  },
                ),
              ),
            ),
          )
              .then(
            allowInterop(
              (result) {
                var rawMetadataJson = jsonDecode(result)['media']['track'];
                bool isFound = false;
                for (final data in rawMetadataJson) {
                  if (data['@type'] == 'General') {
                    isFound = true;
                    rawMetadataJson = data;
                    break;
                  }
                }
                if (!isFound) {
                  throw Exception();
                }
                final metadata = <String, dynamic>{
                  'metadata': {},
                  'albumArt': base64Decode(rawMetadataJson['Cover_Data']),
                  'filePath': null,
                };
                _kMetadataKeys.forEach((key, value) {
                  metadata['metadata'][key] = rawMetadataJson[value];
                });
                completer.complete(Metadata.fromJson(metadata));
              },
            ),
            allowInterop(
              () {
                completer.completeError(Exception());
              },
            ),
          );
        },
      ),
      allowInterop(
        () {
          completer.completeError(Exception());
        },
      ),
    );
    return completer.future;
  }
}

@JS('Promise')
class _Promise<T> {
  external _Promise(
      void Function(void Function(T result) resolve, Function reject) executor);
  external _Promise then(void Function(T result) onFulfilled,
      [Function onRejected]);
  // external _Promise(void executor(void resolve(T result), Function reject));
  // external _Promise then(void onFulfilled(T result), [Function onRejected]);
}

@JS('MediaInfo')
// ignore: non_constant_identifier_names
external String MediaInfo(
  Object opts,
  // ignore: library_private_types_in_public_api
  void Function(_MediaInfo) successCallback,
  void Function() erroCallback,
);

@JS()
@anonymous
class _Opts {
  external int chunkSize;
  external bool coverData;
  external String format;

  external factory _Opts({int chunkSize, bool coverData, String format});
}

@JS()
@anonymous
class _MediaInfo {
  external _Promise<String> analyzeData(int Function() getSize,
      _Promise<Uint8List> Function(int chunkSize, int offset) promise);
  // _Promise<Uint8List> promise(int chunkSize, int offset));

  external factory _MediaInfo();
}

const _kMetadataKeys = <String, String>{
  "trackName": "Track",
  "trackArtistNames": "Performer",
  "albumName": "Album",
  "albumArtistName": "Album_Performer",
  "trackNumber": "Track_Position",
  "albumLength": "Track_Position_Total",
  "year": "Recorded_Date",
  "genre": "Genre",
  "writerName": "WrittenBy",
  "trackDuration": "Duration",
  "bitrate": "OverallBitRate",
};
