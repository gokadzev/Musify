import 'dart:typed_data';

import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

/// A query helper interface..
abstract class QueryHelperInterface {
  /// This method will load the audio using the audio path and return a [MP3Instance]
  /// with all information about this file.
  ///
  /// Note:
  ///  - If [fromAsset] is true, will 'query' from `AssetManifest`. \
  ///  - If [fromAppDir] is true, will 'query' from `App Directory`(path_provider).
  Future<MP3Instance> loadMP3(
    String audio, {
    bool? fromAsset,
    bool? fromAppDir,
  });

  /// This method will get all files and paths from [Assets] or [AppDirectory].
  ///
  /// Note:
  ///  - If [fromAsset] is true, will 'query' from `AssetManifest`. \
  ///  - If [fromAppDir] is true, will 'query' from `App Directory`(path_provider).
  ///  - If [lookSubs] is true, will 'search' for all audios(Even inside folders.).
  ///  - If [limit] is null, will 'query' all informations.
  Future<List<Map<String, Object>>> getFiles({
    bool? fromAsset,
    bool? fromAppDir,
    bool lookSubs = true,
    int? limit,
  });

  /// This method will save/cache a specific audio.
  ///
  /// Note:
  ///  - If [temporary] is true, will cache the file inside a temporary folder,
  /// the system will automatically delete after some time.
  Future<String?> saveArtworks({
    required int id,
    required Uint8List artwork,
    required String fileType,
    bool temporary = true,
  });

  /// This method will request the save/cache audio artwork.
  ///
  /// Note:
  ///  - If [temporary] is true, will search the artwork inside the temporary folder.
  Future<ArtworkModel?> getCachedArtwork({
    required int id,
    bool temporary = true,
  });
}
