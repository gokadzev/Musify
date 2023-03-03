// ignore_for_file: dead_code
import 'dart:convert';
import 'dart:typed_data';

import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

import '../helpers/query_helper_stub.dart'
    if (dart.library.io) '../helpers/query_helper_io.dart'
    if (dart.library.html) '../helpers/query_helper_html.dart';

class ArtworkQuery {
  ///
  final QueryHelper _helper = QueryHelper();

  //
  static final MediaFilter _defaultFilter = MediaFilter.forArtwork();

  ///
  Future<ArtworkModel?> queryArtwork(
    List<AudioModel> audios,
    int id,
    ArtworkType type, {
    bool? fromAsset,
    bool? fromAppDir,
    MediaFilter? filter,
  }) async {
    //
    filter ??= _defaultFilter;

    //
    if (!(filter.overrideCache ?? false)) {
      //
      ArtworkModel? cache = await _helper.getCachedArtwork(
        id: id,
        temporary: filter.cacheTemporarily ?? true,
      );

      //
      if (cache != null) return cache;
    }

    //
    try {
      //
      AudioModel audio = audios.singleWhere(
        (audio) =>
            id == audio.id ||
            id == audio.albumId ||
            id == audio.artistId ||
            id == audio.genreId,
      );

      //
      MP3Instance mp3instance = await _helper.loadMP3(
        audio.data,
        fromAsset: fromAsset,
        fromAppDir: fromAppDir,
      );

      //
      if (mp3instance.parseTagsSync()) {
        //
        String? artwork = mp3instance.getMetaTags()?["APIC"]["base64"];

        if (artwork == null) return null;

        //
        String? fileType;

        //
        if (artwork.startsWith('iVBORw0KGgo')) {
          fileType = '.png';
        } else if (artwork.startsWith('/9j')) {
          fileType = '.jpeg';
        }

        //
        if (fileType == null) return null;

        //
        Uint8List artAsByte = base64Decode(artwork);

        //
        String? path;
        if (filter.cacheArtwork ?? true) {
          path = await _helper.saveArtworks(
            id: id,
            artwork: artAsByte,
            fileType: fileType,
            temporary: filter.cacheTemporarily ?? true,
          );
        }

        //
        return ArtworkModel({
          '_id': id,
          'artwork': artAsByte,
          'path': path,
          'type': fileType,
        });
      }
    } catch (e) {
      //
    }

    return null;
  }
}
