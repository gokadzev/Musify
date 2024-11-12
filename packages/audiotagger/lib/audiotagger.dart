import 'dart:async';
import 'dart:typed_data';

import 'package:audiotagger/models/audiofile.dart';
import 'package:flutter/services.dart';

import 'models/tag.dart';

/// Audiotagger is the main class of the plugin.
/// Create an instance with constructor:
/// ```dart
/// final tagger = new Audiotagger();
/// ```
class Audiotagger {
  late MethodChannel _channel;

  /// Default constructor for Audiotagger class
  Audiotagger() {
    _channel = MethodChannel('audiotagger');
  }

  /// Method to write ID3 tags to MP3 file.
  ///
  /// [path]: The path of the file.
  ///
  /// [tags]: A `Map` of the tags.
  ///
  /// [artwork]: The file path of the song artwork.
  ///
  /// [version]: The version of ID3 tag frame you want to write.  By default set to ID3V2.
  ///
  /// [return]: `true` if the operation has success, `false` instead.
  Future<bool?> writeTagsFromMap({
    required String path,
    required Map tags,
    String? artwork,
  }) async {
    return await _channel.invokeMethod("writeTags", {
      "path": path,
      "tags": tags,
      "artwork": artwork,
    });
  }

  /// Method to write ID3 tags to MP3 file.
  ///
  /// [path]: The path of the file.
  ///
  /// [tags]: A `Tag` object.
  ///
  /// [artwork]: The file path of the song artwork.
  ///
  /// [version]: The version of ID3 tag frame you want to write.  By default set to ID3V2.
  ///
  /// [return]: `true` if the operation has success, `false` instead.
  Future<bool?> writeTags({
    required String path,
    required Tag tag,
  }) async {
    return await _channel.invokeMethod("writeTags", {
      "path": path,
      "tags": tag.toMap(),
      "artwork": tag.artwork,
    });
  }

  /// Method to write ID3 tags to MP3 file.
  ///
  /// [path]: The path of the file.
  ///
  /// [tagField]: The name of the field you want to change (refer to documentation for their name, section "Map of tags").
  ///
  /// [value]: Value of the field.
  ///
  /// [artwork]: The file path of the song artwork.
  ///
  /// [version]: The version of ID3 tag frame you want to write.  By default set to ID3V2.
  ///
  /// [return]: `true` if the operation has success, `false` instead.
  Future<bool?> writeTag({
    required String path,
    required String tagField,
    required String value,
  }) async {
    return await _channel.invokeMethod("writeTags", {
      "path": path,
      "tags": tagField != "artwork" ? <String, String>{tagField: value} : null,
      "artwork": tagField == "artwork" ? value : null,
    });
  }

  /// Method to read ID3 tags from MP3 file.
  ///
  /// [path]: The path of the file.
  ///
  /// [return]: A `Map` of the tags
  Future<Map?> readTagsAsMap({
    required String path,
  }) async {
    return await _channel.invokeMethod("readTags", {
      "path": path,
    });
  }

  /// Method to read ID3 tags from MP3 file.
  ///
  /// [path]: The path of the file.
  ///
  /// [return]: A `Tag` object of the ID3 tags of the song;
  Future<Tag?> readTags({
    required String path,
  }) async {
    return Tag.fromMap((await readTagsAsMap(path: path))!);
  }

  /// Method to read Artwork image from MP3 file.
  ///
  /// [path]: The path of the file.
  ///
  /// [return]: A byte array representation of the image.
  Future<Uint8List?> readArtwork({
    required String path,
  }) async {
    return await _channel.invokeMethod("readArtwork", {
      "path": path,
    });
  }

  /// Method to get technical information about MP3 file.
  ///
  /// [path]: The path of the file.
  ///
  /// [return]: An `AudioFile` object.
  Future<Map?> readAudioFileAsMap({
    required String path,
  }) async {
    return await _channel.invokeMethod("readAudioFile", {
      "path": path,
    });
  }

  /// Method to get technical information about MP3 file.
  ///
  /// [path]: The path of the file.
  ///
  /// [return]: A `Map` of the informations.
  Future<AudioFile?> readAudioFile({
    required String path,
  }) async {
    return AudioFile.fromMap((await readAudioFileAsMap(path: path))!);
  }
}
