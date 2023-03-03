import 'package:flutter/foundation.dart';

import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

import '../helpers/extensions/format_extension.dart';
import '../helpers/extensions/filter_extension.dart';
import '../helpers/query_helper_stub.dart'
    if (dart.library.io) '../helpers/query_helper_io.dart'
    if (dart.library.html) '../helpers/query_helper_html.dart';

class AlbumsQuery {
  //
  final QueryHelper _helper = QueryHelper();

  // Default filter.
  final MediaFilter _defaultFilter = MediaFilter.forAlbums();

  //
  List<AudioModel> _audios = [];

  // Album projection.
  List<String?> projection = [
    "_id",
    "album",
    "artist",
    "artist_id",
    null,
    null,
    "numsongs",
    null,
  ];

  /// Method used to "query" all the albums and their informations.
  Future<List<AlbumModel>> queryAlbums(
    List<AudioModel> audios, {
    MediaFilter? filter,
    bool? fromAsset,
    bool? fromAppDir,
  }) async {
    // If the parameters filter is null, use the default filter.
    filter ??= _defaultFilter;

    //
    _audios = audios;

    // Retrive all (or limited) files path.
    List<Map<String, Object>> instances = await _helper.getFiles(
      fromAsset: fromAsset,
      fromAppDir: fromAppDir,
      limit: filter.limit,
    );

    // Since all the 'query' is made 'manually'. If we have multiple (100+) audio
    // files, will take more than 10 seconds to load everything. So, we need to use
    // the flutter isolate (compute) to load this files on another 'thread'.
    List<Map<String, Object?>> computedAlbums = await compute(
      _fetchListOfAlbums,
      instances,
    );

    // 'Run' the filter.
    List<AlbumModel> albums = computedAlbums.mediaFilter<AlbumModel>(
      filter,
      projection,
    );

    // Now we sort the list based on [sortType].
    //
    // Some variables has a [Null] value, so we need use the [orEmpty] extension,
    // this will return a empty string. Using a empty value to [compareTo] will bring
    // all null values to start of the list so, we use this method to put at the end:
    //
    // ```dart
    //  list.sort((v1, v2) => v1 == null ? 1 : 0);
    // ```
    switch (filter.albumSortType) {
      case AlbumSortType.ALBUM:
        albums.sort((v1, v2) => v1.album
            .isCase(filter!.ignoreCase)
            .compareTo(v2.album.isCase(filter.ignoreCase)));
        break;

      case AlbumSortType.ARTIST:
        albums.sort(
          (v1, v2) => v1.artist.orEmpty
              .isCase(filter!.ignoreCase)
              .compareTo(v2.artist.orEmpty.isCase(filter.ignoreCase)),
        );
        break;

      case AlbumSortType.NUM_OF_SONGS:
        albums.sort(
          (v1, v2) => v1.numOfSongs.compareTo(v2.numOfSongs),
        );
        break;

      default:
        break;
    }

    // Now we sort the order of the list based on [orderType].
    return filter.orderType.index == 1 ? albums.reversed.toList() : albums;
  }

  // This method will be used on another isolate.
  Future<List<Map<String, Object?>>> _fetchListOfAlbums(
    List<Map<String, Object>> instances,
  ) async {
    // This "helper" list will avoid duplicate values inside the final list.
    List<String> hList = [];

    // Define a empty list of audios.
    List<Map<String, Object?>> listOfAlbums = [];

    // For each [audio] inside the [audios], take one and try read the [bytes].
    for (var mp3instance in instances) {
      //
      mp3instance.forEach((key, value) async {
        if (key == 'mp3' && (value as MP3Instance).parseTagsSync()) {
          //
          Map<String, dynamic>? data = value.getMetaTags();

          String? album = data?["Album"] as String?;

          //
          if (data == null || album == null) return;

          // If [data] is null, the file probably has some wrong [bytes].
          // To avoid duplicate items, check if [helperList] already has this name.
          if (album.isEmpty || hList.contains(album)) return;

          // "format" into a [Map<String, dynamic>], all keys are based on [Android]
          // platforms so, if you change some key, will have to change the [Android] too.
          Map<String, Object?> formattedAudio =
              await _formatAlbum(data, 'path');

          // Temporary and the final list.
          listOfAlbums.add(formattedAudio);

          //
          hList.add(album);
        }
      });
    }

    // Back to the 'main' isolate.
    return listOfAlbums;
  }

  //
  Future<Map<String, Object?>> _formatAlbum(Map album, String data) async {
    // Get the number of audios from a album.
    int numOfAudios = _audios.where((audio) {
      //
      if (audio.album != null && audio.album!.isNotEmpty) {
        return audio.album! == album["Album"];
      }

      //
      return false;
    }).length;

    //
    return {
      "_id": "${album["Album"]}".generateId(),
      "album": album["Album"],
      "artist": "${album["Artist"]}",
      "artist_id": "${album["Artist"]}".generateId(),
      "numsongs": numOfAudios,
    };
  }
}
