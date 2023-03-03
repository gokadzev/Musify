import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

class QueryHelper extends QueryHelperInterface {
  /// User directory path.
  static final String _userDir = '${Platform.environment["USERPROFILE"]}';

  /// System default music directory.
  static final Directory _defaultDirectory = Directory('$_userDir\\Music');

  /// System default music path.
  static final String defaultMusicPath = '$_userDir\\Music';

  @override
  Future<MP3Instance> loadMP3(
    String audio, {
    bool? fromAsset,
    bool? fromAppDir,
  }) async {
    // File bytes.
    Uint8List audioBytes;

    // We need [rootBundle] to load/read the file bytes.
    if (fromAsset ?? false) {
      // Before decode: assets/Jungle%20-%20Heavy,%20California.mp3
      // After decode: assets/Jungle - Heavy, California.mp3
      String decodedPath = Uri.decodeFull(audio);

      // 'Load' the audio and get all bytes.
      ByteData loadedAudio = await rootBundle.load(decodedPath);

      // Define the file bytes.
      audioBytes = loadedAudio.buffer.asUint8List();
    } else {
      // Define the file bytes.
      audioBytes = File(audio).readAsBytesSync();
    }

    //
    return MP3Instance(audioBytes);
  }

  ///
  @override
  Future<List<Map<String, Object>>> getFiles({
    bool? fromAsset,
    bool? fromAppDir,
    bool lookSubs = true,
    int? limit,
  }) async {
    // List that will contain all informations.
    List<Map<String, Object>> instances = [];

    //
    List<String> paths = [];

    // Check if the 'query' is from 'Assets', 'App Directory' or 'Default path' .
    if (fromAsset ?? false) {
      // All assets are saved inside the 'AssetManifest'.
      String assets = await rootBundle.loadString('AssetManifest.json');

      // Decorde the String
      Map pFiles = json.decode(assets);

      // Get only [mp3] files.
      var mp3Files = pFiles.keys.where(
        (file) => file.endsWith(".mp3"),
      );

      // Set all paths.
      paths = mp3Files.toList().cast<String>();

      //
    } else {
      // If [fromAppDir] is true. Get all files from the App directory.
      List<File> directoryEntities = (fromAppDir != null && fromAppDir)
          ? await getApplicationSupportDirectory().then((dir) {
              return dir
                  .listSync(followLinks: lookSubs)
                  .whereType<File>()
                  .toList();
            })
          // The defaultDirectory on windows: 'C:\Users\user\Music'.
          : _defaultDirectory
              .listSync(recursive: lookSubs)
              .whereType<File>()
              .toList();

      // Get only [mp3] files.
      var mp3Files = directoryEntities.where(
        (file) => file.path.endsWith('.mp3'),
      );

      // Set all paths.
      paths = mp3Files.map((e) => e.path).toList();
    }

    // 'Define' a limit to the files.
    if (limit != null) paths = paths.take(limit).toList();

    // For every path, create a map with the path and file information.
    for (var path in paths) {
      instances.add({
        "path": path,
        "mp3": await loadMP3(
          path,
          fromAsset: fromAsset,
          fromAppDir: fromAppDir,
        ),
      });
    }

    //
    return instances;
  }

  @override
  Future<String?> saveArtworks({
    required int id,
    required Uint8List artwork,
    required String fileType,
    bool temporary = true,
  }) async {
    // Define if the artwork will be saved inside a tmp folder or the app
    // directory.
    Directory dirPath = temporary
        ? await getTemporaryDirectory()
        : await getApplicationSupportDirectory();

    // Create the file object.
    //
    // * [dirPath] will be the tmp/app folder.
    // * [defaultArtworksPath] is the plugin artwork folder path.
    // * The [file] name will be created using the artwork/media [id] and file
    // [type].
    File artFile = File(
      dirPath.path + defaultArtworksPath + '\\$id$fileType',
    );

    // Write the bytes to the file. Will create a file if it's null.
    await artFile.writeAsBytes(artwork);

    // Return the file path.
    return artFile.path;
  }

  @override
  Future<ArtworkModel?> getCachedArtwork({
    required int id,
    bool temporary = true,
  }) async {
    // Define if the artwork will be 'queried' inside a tmp folder or the app
    // directory.
    Directory dir = temporary
        ? await getTemporaryDirectory()
        : await getApplicationSupportDirectory();

    // 'Build' the artwork directory.
    Directory artworksDir = Directory(dir.path + defaultArtworksPath);

    // Return if no folder was found.
    if (!artworksDir.existsSync()) return null;

    // Get all files inside the folder and get only the first which contains the
    // given [id].
    File? art;
    try {
      art = artworksDir
          .listSync(recursive: true)
          .whereType<File>()
          .firstWhere((f) => f.path.contains('$id'));
    } catch (e) {
      return null;
    }

    // Check if the file exists. If true, 'build' a ArtworkModel with all info.
    if (art.existsSync()) {
      return ArtworkModel({
        '_id': id,
        'artwork': await art.readAsBytes(),
        'path': art.path,
        'type': art.uri.pathSegments.last
      });
    }

    //
    return null;
  }
}
