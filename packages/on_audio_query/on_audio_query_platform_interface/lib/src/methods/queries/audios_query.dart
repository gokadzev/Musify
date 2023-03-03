import 'package:flutter/foundation.dart';

import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';
import 'package:path/path.dart' as p;

import '../helpers/extensions/format_extension.dart';
import '../helpers/extensions/filter_extension.dart';
import '../helpers/query_helper_stub.dart'
    if (dart.library.io) '../helpers/query_helper_io.dart'
    if (dart.library.html) '../helpers/query_helper_html.dart';

class AudiosQuery {
  ///
  List<AudioModel> get listOfAudios => _audios;

  //
  List<AudioModel> _audios = [];

  // Helper.
  final QueryHelper _helper = QueryHelper();

  // Default filter.
  final MediaFilter _defaultFilter = MediaFilter.forAudios();

  // Audio projection.
  List<String?> audioProjection = [
    "_id",
    "_data",
    "_display_name",
    "_size",
    "album",
    null,
    "album_id",
    "artist",
    "artist_id",
    null,
    null,
    null,
    null,
    null,
    "title",
    "track",
    "year",
    null,
    null,
    null,
    null,
    null,
    "genre",
    "genre_id",
  ];

  /// Method used to 'query' all the audios and their informations.
  Future<List<AudioModel>> queryAudios({
    MediaFilter? filter,
    bool? fromAsset,
    bool? fromAppDir,
  }) async {
    // If the parameters filter is null, use the default filter.
    filter ??= _defaultFilter;

    //
    fromAsset ??= false;
    fromAppDir ??= false;

    // Retrive all (or limited) files path.
    List<Map<String, Object>> instances = await _helper.getFiles(
      fromAsset: fromAsset,
      fromAppDir: fromAppDir,
      limit: filter.limit,
    );

    // Since all the 'query' is made 'manually'. If we have multiple (100+) audio
    // files, will take more than 10 seconds to load everything. So, we need to use
    // the flutter isolate (compute) to load this files on another 'thread'.
    List<Map<String, Object?>> computedAudios = await compute(
      _fetchListOfAudios,
      instances,
    );

    // 'Run' the filter.
    _audios = computedAudios.mediaFilter<AudioModel>(filter, audioProjection);

    // Now we sort the list based on [sortType].
    //
    // Some variables has a [Null] value, so we need use the [orEmpty] extension,
    // this will return a empty string. Using a empty value to [compareTo] will bring
    // all null values to start of the list so, we use this method to put at the end:
    //
    // ```dart
    //  list.sort((v1, v2) => v1 == null ? 1 : 0);
    // ```
    //
    // If this [Null] value is a [int] we need another method:
    //
    // ```dart
    //  list.sort((v1, v2) {
    //    if (v1 == null && v2 == null) return -1;
    //    if (v1 == null && v2 != null) return 1;
    //    if (v1 != null && v2 == null) return 0;
    //    return v1!.compareTo(v2!);
    //  });
    // ```
    switch (filter.audioSortType) {
      case AudioSortType.TITLE:
        _audios.sort((v1, v2) => v1.title.compareTo(v2.title));
        break;

      case AudioSortType.ARTIST:
        _audios.sort(
          (v1, v2) => v1.artist.orEmpty
              .isCase(
                filter!.ignoreCase,
              )
              .compareTo(
                v2.artist.orEmpty.isCase(filter.ignoreCase),
              ),
        );
        _audios.sort((v1, v2) => v1.artist == null ? 1 : 0);
        break;

      case AudioSortType.ALBUM:
        _audios.sort(
          (v1, v2) => v1.album.orEmpty
              .isCase(
                filter!.ignoreCase,
              )
              .compareTo(
                v2.album.orEmpty.isCase(filter.ignoreCase),
              ),
        );
        break;

      // case AudioSortType.DURATION:
      //   audios.sort((v1, v2) {
      //     if (v1.duration == null && v2.duration == null) return -1;
      //     if (v1.duration == null && v2.duration != null) return 1;
      //     if (v1.duration != null && v2.duration == null) return 0;
      //     return v1.duration!.compareTo(v2.duration!);
      //   });
      //   break;

      case AudioSortType.SIZE:
        _audios.sort((v1, v2) => v1.size.compareTo(v2.size));
        break;

      case AudioSortType.DISPLAY_NAME:
        _audios.sort(
          (v1, v2) => v1.displayName
              .isCase(
                filter!.ignoreCase,
              )
              .compareTo(
                v2.displayName.isCase(filter.ignoreCase),
              ),
        );
        break;

      default:
        break;
    }

    // Now we sort the order of the list based on [orderType].
    return filter.orderType.index == 1 ? _audios.reversed.toList() : _audios;
  }

  // This method will be used on another isolate.
  Future<List<Map<String, Object?>>> _fetchListOfAudios(
    List<Map<String, Object>> instances,
  ) async {
    // Define a empty list of audios.
    List<Map<String, Object?>> listOfAudios = [];

    // For each [audio] inside the [audios], take one and try read the [bytes].
    // Will return a Map with some informations:
    //   * Title
    //   * Artist
    //   * Album
    //   * Genre
    //   * Track
    //   * Version (ignored)
    //   * Year (ignored)
    //   * Settings (ignored)
    //   * APIC
    for (var mp3instance in instances) {
      //
      String? currentPath;

      //
      mp3instance.forEach((key, value) {
        //
        if (key == 'path') currentPath = '$value';

        //
        if (key == 'mp3' && (value as MP3Instance).parseTagsSync()) {
          //
          Map<String, dynamic>? data = value.getMetaTags();

          // If [data] is null, the file probably has some wrong [bytes].
          if (data != null && currentPath != null) {
            listOfAudios.add(_formatAudio(
              data,
              currentPath!,
              value.mp3Bytes.length,
            ));
          }
        }
      });
    }

    // Back to the 'main' isolate.
    return listOfAudios;
  }

  // Method to convert/join all media information.
  Map<String, Object?> _formatAudio(Map audio, String data, int size) {
    String? fExtension = p.extension(data);
    return {
      "_id": "${audio["Title"]} : ${audio["Artist"]}".generateAudioId(),
      "_data": data,
      "_uri": null,
      "_display_name": "${audio["Artist"]} - ${audio["Title"]}$fExtension",
      "_display_name_wo_ext": "${audio["Artist"]} - ${audio["Title"]}",
      "_size": size,
      "album": audio["Album"],
      "album_id": "${audio["Album"]}".generateId(),
      "artist": audio["Artist"],
      "artist_id": "${audio["Artist"]}".generateId(),
      "genre": audio["Genre"],
      "genre_id": "${audio["Genre"]}".generateId(),
      "bookmark": null,
      "composer": null,
      "date_added": null,
      "date_modified": null,
      "duration": 0,
      "title": audio["Title"],
      "track": audio["Track"],
      "file_extension": fExtension
    };
  }
}
