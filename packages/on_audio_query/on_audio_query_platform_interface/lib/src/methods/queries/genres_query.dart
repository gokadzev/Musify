import 'package:flutter/foundation.dart';

import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

import '../helpers/extensions/format_extension.dart';
import '../helpers/extensions/filter_extension.dart';
import '../helpers/query_helper_stub.dart'
    if (dart.library.io) '../helpers/query_helper_io.dart'
    if (dart.library.html) '../helpers/query_helper_html.dart';

class GenresQuery {
  //
  final QueryHelper _helper = QueryHelper();

  // Default filter.
  final MediaFilter _defaultFilter = MediaFilter.forGenres();

  // Genre projection (to filter).
  List<String?> projection = [
    "_id",
    "name",
  ];

  /// Method used to "query" all the genres and their informations.
  Future<List<GenreModel>> queryGenres({
    MediaFilter? filter,
    bool? fromAsset,
    bool? fromAppDir,
  }) async {
    // If the parameters filter is null, use the default filter.
    filter ??= _defaultFilter;

    // Retrive all (or limited) files path.
    List<Map<String, Object>> instances = await _helper.getFiles(
      fromAsset: fromAsset,
      fromAppDir: fromAppDir,
      limit: filter.limit,
    );

    // Since all the 'query' is made 'manually'. If we have multiple (100+) audio
    // files, will take more than 10 seconds to load everything. So, we need to use
    // the flutter isolate (compute) to load this files on another 'thread'.
    List<Map<String, Object?>> computedGenres = await compute(
      _fetchListOfGenres,
      instances,
    );

    // 'Run' the filter.
    List<GenreModel> genres = computedGenres.mediaFilter<GenreModel>(
      filter,
      projection,
    );

    // Now we sort the list based on [sortType].
    switch (filter.genreSortType) {
      case GenreSortType.GENRE:
        genres.sort((val1, val2) => val1.genre
            .isCase(filter!.ignoreCase)
            .compareTo(val2.genre.isCase(filter.ignoreCase)));
        break;

      default:
        break;
    }

    // Now we sort the order of the list based on [orderType].
    return filter.orderType.index == 1 ? genres.reversed.toList() : genres;
  }

  // This method will be used on another isolate.
  Future<List<Map<String, Object?>>> _fetchListOfGenres(
    List<Map<String, Object>> instances,
  ) async {
    // This "helper" list will avoid duplicate values inside the final list.
    List<String> hList = [];

    // Define a empty list of audios.
    List<Map<String, Object?>> listOfGenres = [];

    // All genres media count.
    Map<String, int> mediaCount = {};

    // For each [audio] inside the [audios], take one and try read the [bytes].
    for (var mp3instance in instances) {
      //
      mp3instance.forEach((key, value) async {
        //
        if (key == 'mp3' && (value as MP3Instance).parseTagsSync()) {
          //
          Map<String, dynamic>? data = value.getMetaTags();

          // If [data] is null, the file probably has some wrong [bytes].
          if (data == null) return;

          // Get the genre name and remove all (possible) whitespace.
          String? genre = (data["Genre"] as String?)?.trim();

          // If null or empty, return.
          if (genre == null || genre.isEmpty) return;

          // Get the current count of audios for this genre, if null, create the
          // item and add the value of 0.
          int count = mediaCount.putIfAbsent(genre, () {
            return mediaCount[genre] = 0;
          });

          // Add or updated the number of audios for this genre.
          mediaCount[genre] = count + 1;

          // "format" into a [Map<String, dynamic>], all keys are based on [Android]
          // platforms so, if you change some key, will have to change the [Android] too.
          Map<String, Object?> formattedGenre = await _formatGenre(
            genre,
            count,
          );

          // Check if the genre already exists.
          //
          // If true, update the [numOfSongs] and return.
          if (hList.contains(genre)) {
            //
            int index = listOfGenres.indexWhere(
              (tGenre) => tGenre['name'] == genre,
            );

            listOfGenres[index] = formattedGenre;
            return;
          }

          // Temporary and the final list.
          listOfGenres.add(formattedGenre);

          //
          hList.add(genre);
        }
      });
    }

    // Back to the 'main' isolate.
    return listOfGenres;
  }

  Future<Map<String, Object?>> _formatGenre(String genreName, int count) async {
    return {
      "_id": genreName.generateId(),
      "name": genreName,
      "num_of_songs": count,
    };
  }
}
