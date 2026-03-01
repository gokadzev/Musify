/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musify/constants/clients.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/io_service.dart';
import 'package:musify/services/lyrics_manager.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/proxy_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/utils.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

List globalSongs = [];

List userLikedSongsList = Hive.box('user').get('likedSongs', defaultValue: []);

List userRecentlyPlayed = Hive.box(
  'user',
).get('recentlyPlayedSongs', defaultValue: []);
List userOfflineSongs = Hive.box(
  'userNoBackup',
).get('offlineSongs', defaultValue: []);

dynamic nextRecommendedSong;

final currentLikedSongsLength = ValueNotifier<int>(userLikedSongsList.length);
final currentOfflineSongsLength = ValueNotifier<int>(userOfflineSongs.length);
final currentRecentlyPlayedLength = ValueNotifier<int>(
  userRecentlyPlayed.length,
);
final recentlyPlayedVersion = ValueNotifier<int>(0);

final recentlyPlayedMigration = Future.microtask(() async {
  try {
    var needsPersist = false;
    for (var i = 0; i < userRecentlyPlayed.length; i++) {
      final entry = userRecentlyPlayed[i] as Map;
      if (entry['listeningCount'] == null || entry['lastPlayed'] == null) {
        entry['listeningCount'] = entry['listeningCount'] ?? 1;
        entry['lastPlayed'] = entry['lastPlayed'] ?? DateTime.now();
        needsPersist = true;
      }
    }

    if (needsPersist) {
      unawaited(
        addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed),
      );
    }
  } catch (e, st) {
    logger.log(
      'Error migrating recently played entries',
      error: e,
      stackTrace: st,
    );
  }
});

final lyrics = ValueNotifier<String?>(null);
String? lastFetchedLyrics;

final _clients = [customAndroidVr, customAndroidSdkless];

// Timeouts and durations used across manifest fetching and cache validation.
const Duration _manifestTimeout = Duration(seconds: 12);
const Duration _cacheValidationDuration = Duration(hours: 1);

/// Fetches a stream manifest for a song, honoring proxy settings.
Future<StreamManifest?> _fetchStreamManifest(String songId) async {
  if (useProxy.value) {
    return ProxyManager().getSongManifest(songId).timeout(_manifestTimeout);
  }

  return ytClient.videos.streams
      .getManifest(songId, ytClients: _clients)
      .timeout(_manifestTimeout);
}

/// Returns a cached song URL if present and still valid.
Future<String?> _getCachedSongUrl(
  String cacheKey,
  Duration cacheDuration,
) async {
  final cachedUrl = await getData(
    'cache',
    cacheKey,
    cachingDuration: cacheDuration,
  );

  if (cachedUrl is! String || cachedUrl.isEmpty) {
    return null;
  }

  final cacheBox = await Hive.openBox('cache');
  final cacheDate = cacheBox.get('${cacheKey}_date') as DateTime?;
  final now = DateTime.now();
  final isOld =
      cacheDate != null && now.difference(cacheDate) > _cacheValidationDuration;

  if (!isOld) {
    return cachedUrl;
  }

  if (await _validateCachedUrl(cachedUrl)) {
    return cachedUrl;
  }

  await deleteData('cache', cacheKey);
  await deleteData('cache', '${cacheKey}_date');
  return null;
}

/// Checks if a cached URL still responds successfully.
Future<bool> _validateCachedUrl(String cachedUrl) async {
  try {
    final response = await http.head(Uri.parse(cachedUrl));
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (_) {
    return false;
  }
}

Future<List> fetchSongsList(String searchQuery) async {
  try {
    // If not in cache, perform the search
    final List<Video> searchResults = await ytClient.search.search(searchQuery);
    final songsList = searchResults
        .map((video) => returnSongLayout(0, video))
        .toList();

    return songsList;
  } catch (e, stackTrace) {
    logger.log('Error in fetchSongsList', error: e, stackTrace: stackTrace);
    return [];
  }
}

Future<List> getRecommendedSongs() async {
  try {
    if (externalRecommendations.value && userRecentlyPlayed.isNotEmpty) {
      return await _getRecommendationsFromRecentlyPlayed();
    } else {
      return await _getRecommendationsFromMixedSources();
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error in getRecommendedSongs',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

Future<List> _getRecommendationsFromRecentlyPlayed() async {
  final recent = (List.from(userRecentlyPlayed)..shuffle()).take(3).toList();

  final futures = recent.map((songData) async {
    try {
      final song = await ytClient.videos.get(songData['ytid']);
      final relatedSongs = await ytClient.videos.getRelatedVideos(song) ?? [];
      return relatedSongs.take(3).map((s) => returnSongLayout(0, s)).toList();
    } catch (e, stackTrace) {
      logger.log(
        'Error getting related videos for ${songData['ytid']}',
        error: e,
        stackTrace: stackTrace,
      );
      return <Map>[];
    }
  }).toList();

  final results = await Future.wait(futures);
  // Limit to 15 items max for performance
  final playlistSongs = results.expand((list) => list).take(15).toList()
    ..shuffle();
  return playlistSongs;
}

Future<List> _getRecommendationsFromMixedSources() async {
  final playlistSongs = [...userLikedSongsList, ...userRecentlyPlayed];

  if (globalSongs.isEmpty) {
    const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';
    globalSongs = await getSongsFromPlaylist(playlistId);
  }
  playlistSongs.addAll(globalSongs.take(10));

  if (userCustomPlaylists.value.isNotEmpty) {
    for (final userPlaylist in userCustomPlaylists.value) {
      final _list = (userPlaylist['list'] as List)..shuffle();
      playlistSongs.addAll(_list.take(5));
    }
  }

  return _deduplicateAndShuffle(playlistSongs);
}

List _deduplicateAndShuffle(List playlistSongs) {
  final seenYtIds = <String>{};
  final uniqueSongs = <Map>[];

  playlistSongs.shuffle();

  for (final song in playlistSongs) {
    if (song['ytid'] != null && seenYtIds.add(song['ytid'])) {
      uniqueSongs.add(song);
      // Early exit when we have enough songs
      if (uniqueSongs.length >= 15) break;
    }
  }

  return uniqueSongs;
}

Future<void> updateSongLikeStatus(dynamic songId, bool add) async {
  try {
    if (add) {
      if (!userLikedSongsList.any((song) => song['ytid'] == songId)) {
        final songDetails = await getSongDetails(
          userLikedSongsList.length,
          songId,
        );
        userLikedSongsList.add(songDetails);
      }
    } else {
      userLikedSongsList.removeWhere((song) => song['ytid'] == songId);
    }

    currentLikedSongsLength.value = userLikedSongsList.length;
    unawaited(addOrUpdateData('user', 'likedSongs', userLikedSongsList));
  } catch (e, stackTrace) {
    logger.log(
      'Error updating song like status',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

void moveLikedSong(int oldIndex, int newIndex) {
  final _song = userLikedSongsList[oldIndex];
  userLikedSongsList
    ..removeAt(oldIndex)
    ..insert(newIndex, _song);
  currentLikedSongsLength.value = userLikedSongsList.length;
  unawaited(addOrUpdateData('user', 'likedSongs', userLikedSongsList));
}

Future<void> renameSongInLikedSongs(
  dynamic songId,
  String newTitle,
  String newArtist,
) async {
  try {
    final songIndex = userLikedSongsList.indexWhere(
      (song) => song['ytid'] == songId,
    );

    if (songIndex != -1) {
      userLikedSongsList[songIndex]['title'] = newTitle;
      userLikedSongsList[songIndex]['artist'] = newArtist;

      currentLikedSongsLength.value = userLikedSongsList.length;
      unawaited(addOrUpdateData('user', 'likedSongs', userLikedSongsList));
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error renaming song in liked songs',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

bool isSongAlreadyLiked(songIdToCheck) =>
    userLikedSongsList.any((song) => song['ytid'] == songIdToCheck);

bool isPlaylistAlreadyLiked(playlistIdToCheck) =>
    userLikedPlaylists.any((playlist) => playlist['ytid'] == playlistIdToCheck);

bool isSongAlreadyOffline(songIdToCheck) =>
    userOfflineSongs.any((song) => song['ytid'] == songIdToCheck);

Map<String, dynamic> getOfflineSongByYtid(String ytid) {
  try {
    final song = userOfflineSongs.firstWhere(
      (s) => s['ytid'] == ytid,
      orElse: () => <String, dynamic>{},
    );
    return Map<String, dynamic>.from(song);
  } catch (_) {
    return <String, dynamic>{};
  }
}

Future<List<String>> getSearchSuggestions(String query) async {
  // Custom implementation:

  // const baseUrl = 'https://suggestqueries.google.com/complete/search';
  // final parameters = {
  //   'client': 'firefox',
  //   'ds': 'yt',
  //   'q': query,
  // };

  // final uri = Uri.parse(baseUrl).replace(queryParameters: parameters);

  // try {
  //   final response = await http.get(
  //     uri,
  //     headers: {
  //       'User-Agent':
  //           'Mozilla/5.0 (Windows NT 10.0; rv:96.0) Gecko/20100101 Firefox/96.0',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final suggestions = jsonDecode(response.body)[1] as List<dynamic>;
  //     final suggestionStrings = suggestions.cast<String>().toList();
  //     return suggestionStrings;
  //   }
  // } catch (e, stackTrace) {
  //   logger.log('Error in getSearchSuggestions:$e\n$stackTrace');
  // }

  // Built-in implementation:

  final suggestions = await ytClient.search.getQuerySuggestions(query);

  return suggestions;
}

Future<List<Map<String, int>>> getSkipSegments(String id) async {
  try {
    final res = await http.get(
      Uri(
        scheme: 'https',
        host: 'sponsor.ajay.app',
        path: '/api/skipSegments',
        queryParameters: {
          'videoID': id,
          'category': [
            'sponsor',
            'selfpromo',
            'interaction',
            'intro',
            'outro',
            'music_offtopic',
          ],
          'actionType': 'skip',
        },
      ),
    );
    if (res.body != 'Not Found') {
      final data = jsonDecode(res.body);
      final segments = data.map((obj) {
        return Map.castFrom<String, dynamic, String, int>({
          'start': obj['segment'].first.toInt(),
          'end': obj['segment'].last.toInt(),
        });
      }).toList();
      return List.castFrom<dynamic, Map<String, int>>(segments);
    } else {
      return [];
    }
  } catch (e, stackTrace) {
    logger.log('Error in getSkipSegments', error: e, stackTrace: stackTrace);
    return [];
  }
}

Future<void> getSimilarSong(String songYtId) async {
  try {
    final song = await ytClient.videos.get(songYtId);
    final relatedSongs = await ytClient.videos.getRelatedVideos(song) ?? [];

    if (relatedSongs.isNotEmpty) {
      nextRecommendedSong = returnSongLayout(0, relatedSongs[0]);
    } else {
      logger.log('No related songs found for $songYtId');
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error while fetching next similar song:',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Fetches the best available audio stream for a song.
Future<AudioOnlyStreamInfo?> fetchBestAudioStream(String? songId) async {
  try {
    if (songId == null || songId.isEmpty) {
      logger.log('fetchBestAudioStream: songId is null or empty');
      return null;
    }

    final manifest = await _fetchStreamManifest(songId);
    final audioStream = manifest?.audioOnly;
    if (audioStream == null || audioStream.isEmpty) {
      logger.log('fetchBestAudioStream: no audio streams for $songId');
      return null;
    }
    return selectAudioOnlyStreamForQuality(audioStream.sortByBitrate());
  } on TimeoutException catch (_) {
    logger.log('fetchBestAudioStream request timed out for $songId');
    return null;
  } catch (e, stackTrace) {
    logger.log(
      'Error while fetching best audio stream',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}

/// Resolves a playable stream URL for a song (cached when possible).
Future<String?> fetchSongStreamUrl(String songId, bool isLive) async {
  try {
    if (songId.isEmpty) {
      logger.log('fetchSongStreamUrl: songId is empty');
      return null;
    }
    if (isLive) {
      final streamInfo = await ytClient.videos.streamsClient
          .getHttpLiveStreamUrl(VideoId(songId));
      unawaited(updateRecentlyPlayed(songId));
      return streamInfo;
    }

    const _cacheDuration = Duration(hours: 3);
    final cacheKey = 'song_${songId}_${audioQualitySetting.value}_url';

    // Try to get from cache
    final cachedUrl = await _getCachedSongUrl(cacheKey, _cacheDuration);
    if (cachedUrl != null) {
      unawaited(updateRecentlyPlayed(songId));
      return cachedUrl;
    }

    // Get fresh URL
    final manifest = await _fetchStreamManifest(songId);
    final audioStreams = manifest?.audioOnly;
    if (audioStreams == null || audioStreams.isEmpty) {
      logger.log('fetchSongStreamUrl: no audio streams for $songId');
      return null;
    }

    final selectedStream = selectAudioOnlyStreamForQuality(
      audioStreams.sortByBitrate(),
    );
    final url = selectedStream.url.toString();

    unawaited(addOrUpdateData('cache', cacheKey, url));

    unawaited(updateRecentlyPlayed(songId));
    return url;
  } on TimeoutException catch (_) {
    logger.log('fetchSongStreamUrl request timed out for $songId');
    return null;
  } catch (e, stackTrace) {
    logger.log(
      'Error in fetchSongStreamUrl for $songId:',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}

Future<Map<String, dynamic>> getSongDetails(
  int songIndex,
  String songId,
) async {
  try {
    final song = await ytClient.videos.get(songId);
    return returnSongLayout(songIndex, song);
  } catch (e, stackTrace) {
    logger.log(
      'Error while getting song details',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

Future<String?> getSongLyrics(String? artist, String title) async {
  if (artist == null) return null;
  if (lastFetchedLyrics != '$artist - $title') {
    lyrics.value = null;
    var _lyrics = await LyricsManager().fetchLyrics(artist, title);
    if (_lyrics != null) {
      _lyrics = _lyrics.replaceAll(RegExp(r'\n{2}'), '\n');
      _lyrics = _lyrics.replaceAll(RegExp(r'\n{4}'), '\n\n');
      lyrics.value = _lyrics;
    } else {
      return null;
    }

    lastFetchedLyrics = '$artist - $title';
    return _lyrics;
  }

  return lyrics.value;
}

Future<bool> makeSongOffline(dynamic song, {bool fromPlaylist = false}) async {
  try {
    final String? ytid = song['ytid'];

    if (ytid == null || ytid.isEmpty) {
      logger.log('makeSongOffline: song["ytid"] is null or empty');
      return false;
    }

    if (!fromPlaylist && isSongAlreadyOffline(ytid)) {
      return true;
    }

    final audioPath = FilePaths.getAudioPath(ytid);
    final audioFile = File(audioPath);
    final artworkPath = FilePaths.getArtworkPath(ytid);

    await audioFile.parent.create(recursive: true);

    try {
      final audioManifest = await fetchBestAudioStream(ytid);
      if (audioManifest == null) {
        logger.log('makeSongOffline: audioManifest is null for $ytid');
        return false;
      }

      final stream = ytClient.videos.streamsClient.get(audioManifest);
      final fileStream = audioFile.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();
    } catch (e, stackTrace) {
      logger.log(
        'Error downloading audio file',
        error: e,
        stackTrace: stackTrace,
      );
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
      return false;
    }

    try {
      if (song['highResImage'] != null &&
          song['highResImage'].toString().isNotEmpty) {
        final _artworkFile = await _downloadAndSaveArtworkFile(
          song['highResImage'],
          artworkPath,
        );

        if (_artworkFile != null && await _artworkFile.exists()) {
          song['artworkPath'] = artworkPath;
          song['highResImage'] = artworkPath;
          song['lowResImage'] = artworkPath;
        } else {
          logger.log(
            'Artwork download failed or file does not exist for $ytid',
          );
          // Clear artwork paths if download failed
          song['artworkPath'] = null;
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error downloading artwork', error: e, stackTrace: stackTrace);
      song['artworkPath'] = null;
    }

    song['audioPath'] = audioFile.path;
    song['dateAdded'] = DateTime.now().millisecondsSinceEpoch;

    try {
      final existingIndex = userOfflineSongs.indexWhere(
        (s) => s['ytid'] == ytid,
      );

      if (existingIndex != -1) {
        userOfflineSongs[existingIndex] = song;
      } else {
        userOfflineSongs.add(song);
      }

      unawaited(
        addOrUpdateData('userNoBackup', 'offlineSongs', userOfflineSongs),
      );
      currentOfflineSongsLength.value = userOfflineSongs.length;
    } catch (e, st) {
      logger.log(
        'Error updating global offline songs list',
        error: e,
        stackTrace: st,
      );
    }

    return true;
  } catch (e, stackTrace) {
    logger.log('Error making song offline', error: e, stackTrace: stackTrace);
    return false;
  }
}

Future<bool> removeSongFromOffline(
  dynamic songId, {
  bool fromPlaylist = false,
}) async {
  try {
    final audioPath = FilePaths.getAudioPath(songId);
    final audioFile = File(audioPath);
    final artworkPath = FilePaths.getArtworkPath(songId);
    final artworkFile = File(artworkPath);

    try {
      if (await audioFile.exists()) await audioFile.delete(recursive: true);
    } catch (e, stackTrace) {
      logger.log('Error deleting audio file', error: e, stackTrace: stackTrace);
    }

    try {
      if (await artworkFile.exists()) await artworkFile.delete(recursive: true);
    } catch (e, stackTrace) {
      logger.log(
        'Error deleting artwork file',
        error: e,
        stackTrace: stackTrace,
      );
    }

    try {
      userOfflineSongs.removeWhere((song) => song['ytid'] == songId);
      currentOfflineSongsLength.value = userOfflineSongs.length;
      unawaited(
        addOrUpdateData('userNoBackup', 'offlineSongs', userOfflineSongs),
      );
    } catch (e, st) {
      logger.log(
        'Error updating offline songs registry after removal',
        error: e,
        stackTrace: st,
      );
    }

    return true;
  } catch (e, stackTrace) {
    logger.log(
      'Error removing song from offline storage',
      error: e,
      stackTrace: stackTrace,
    );
    return false;
  }
}

Future<File?> _downloadAndSaveArtworkFile(String url, String filePath) async {
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);

      // Validate that the file was actually written
      if (await file.exists() && await file.length() > 0) {
        return file;
      } else {
        logger.log('Artwork file was not written properly: $filePath');
        return null;
      }
    } else {
      logger.log(
        'Failed to download file. Status code: ${response.statusCode}',
      );
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error downloading and saving file',
      error: e,
      stackTrace: stackTrace,
    );
  }

  return null;
}

const recentlyPlayedSongsLimit = 250;

Future<void> updateRecentlyPlayed(dynamic songId) async {
  try {
    if (userRecentlyPlayed.isNotEmpty &&
        userRecentlyPlayed.length == 1 &&
        userRecentlyPlayed[0]['ytid'] == songId) {
      final existing = userRecentlyPlayed[0] as Map;
      existing['listeningCount'] = (existing['listeningCount'] ?? 0) + 1;
      existing['lastPlayed'] = DateTime.now();
      recentlyPlayedVersion.value++;
      unawaited(
        addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed),
      );
      return;
    }

    if (userRecentlyPlayed.length >= recentlyPlayedSongsLimit) {
      userRecentlyPlayed.removeLast();
    }

    final existingIndex = userRecentlyPlayed.indexWhere(
      (song) => song['ytid'] == songId,
    );
    if (existingIndex != -1) {
      final song = userRecentlyPlayed.removeAt(existingIndex) as Map;
      song['listeningCount'] = (song['listeningCount'] ?? 0) + 1;
      song['lastPlayed'] = DateTime.now();
      userRecentlyPlayed.insert(0, song);
    } else {
      final newSongDetails = await getSongDetails(0, songId);
      newSongDetails['listeningCount'] = 1;
      newSongDetails['lastPlayed'] = DateTime.now();
      userRecentlyPlayed.insert(0, newSongDetails);
    }

    currentRecentlyPlayedLength.value = userRecentlyPlayed.length;
    recentlyPlayedVersion.value++;
    unawaited(
      addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed),
    );
  } catch (e, stackTrace) {
    logger.log(
      'Error updating recently played',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

Future<void> removeFromRecentlyPlayed(dynamic songId) async {
  if (userRecentlyPlayed.any((song) => song['ytid'] == songId)) {
    userRecentlyPlayed.removeWhere((song) => song['ytid'] == songId);
    currentRecentlyPlayedLength.value = userRecentlyPlayed.length;
    recentlyPlayedVersion.value++;
    unawaited(
      addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed),
    );
  }
}

/// Returns the most-played songs, ordered by `listeningCount` desc and
/// `lastPlayed` desc as a tiebreaker. Does not mutate the persisted list.
List<Map> getMostPlayed({int limit = 20, bool deduplicate = true}) {
  final copy = List<Map>.from(userRecentlyPlayed);

  if (deduplicate) {
    final seen = <String>{};
    copy.removeWhere((m) {
      final id = m['ytid']?.toString();
      if (id == null) return true;
      if (seen.contains(id)) return true;
      seen.add(id);
      return false;
    });
  }

  copy.sort((a, b) {
    final ai = (a['listeningCount'] is int)
        ? a['listeningCount'] as int
        : int.tryParse(a['listeningCount']?.toString() ?? '') ?? 0;
    final bi = (b['listeningCount'] is int)
        ? b['listeningCount'] as int
        : int.tryParse(b['listeningCount']?.toString() ?? '') ?? 0;
    if (ai != bi) return bi.compareTo(ai);

    final ad = a['lastPlayed'] is DateTime
        ? a['lastPlayed'] as DateTime
        : DateTime.tryParse(a['lastPlayed']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b['lastPlayed'] is DateTime
        ? b['lastPlayed'] as DateTime
        : DateTime.tryParse(b['lastPlayed']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });

  return copy.take(limit).toList();
}
