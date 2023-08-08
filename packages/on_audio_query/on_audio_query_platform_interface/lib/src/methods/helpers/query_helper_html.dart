import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

class QueryHelper extends QueryHelperInterface {
  @override
  Future<MP3Instance> loadMP3(
    String audio, {
    bool? fromAsset,
    bool? fromAppDir,
  }) async {
    // Before decode: assets/Jungle%20-%20Heavy,%20California.mp3
    // After decode: assets/Jungle - Heavy, California.mp3
    String decodedPath = Uri.decodeFull(audio);

    // 'Load' the audio and get all bytes.
    ByteData loadedAudio = await rootBundle.load(decodedPath);

    //
    return MP3Instance(loadedAudio.buffer.asUint8List());
  }

  @override
  Future<List<Map<String, Object>>> getFiles({
    bool? fromAsset,
    bool? fromAppDir,
    bool lookSubs = true,
    int? limit,
  }) async {
    // The web implementation doesn't have app directory.
    fromAsset ??= true;

    // List that will contain all informations.
    List<Map<String, Object>> instances = [];

    // All assets are saved inside the 'AssetManifest'.
    String assets = await rootBundle.loadString(defaultAssetsDirectory);

    // Decorde the String
    Map decoded = json.decode(assets);

    // Get only [mp3] files.
    var paths = decoded.keys.where(
      (file) => file.endsWith(".mp3"),
    );

    // 'Define' a limit to the files.
    if (limit != null) paths = paths.take(limit).toList();

    // For every path, create a map with the path and file information.
    for (var path in paths) {
      instances.add({
        "path": path,
        "mp3": await loadMP3(
          path,
          fromAsset: fromAsset,
        ),
      });
    }

    //
    return instances;
  }

  @override
  Future<String?> saveArtworks({
    required int id,
    required Uint8List? artwork,
    required String fileType,
    bool temporary = true,
  }) {
    throw UnsupportedError('Unsupported method when using [Web]');
  }

  @override
  Future<ArtworkModel?> getCachedArtwork({
    required int id,
    bool temporary = true,
  }) {
    throw UnimplementedError('Unsupported method when using [Web]');
  }
}
