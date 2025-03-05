/*
 *     Copyright (C) 2025 Valeri Gokadze
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
import 'package:musify/DB/albums.db.dart';
import 'package:musify/DB/playlists.db.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/lyrics_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final _yt = YoutubeExplode();

List globalSongs = [];

List playlists = [...playlistsDB, ...albumsDB];
List userPlaylists = Hive.box('user').get('playlists', defaultValue: []);
final userCustomPlaylists = ValueNotifier<List>(
  Hive.box('user').get('customPlaylists', defaultValue: []),
);
List userLikedSongsList = Hive.box('user').get('likedSongs', defaultValue: []);
List userLikedPlaylists = Hive.box(
  'user',
).get('likedPlaylists', defaultValue: []);
List userRecentlyPlayed = Hive.box(
  'user',
).get('recentlyPlayedSongs', defaultValue: []);
List userOfflineSongs = Hive.box(
  'userNoBackup',
).get('offlineSongs', defaultValue: []);
List suggestedPlaylists = [];
List onlinePlaylists = [];
Map activePlaylist = {
  'ytid': '',
  'title': 'No Playlist',
  'image': '',
  'source': 'user-created',
  'list': [],
};

List<YoutubeApiClient> userChosenClients = [
  YoutubeApiClient.tv,
  YoutubeApiClient.androidVr,
  YoutubeApiClient.safari,
];

dynamic nextRecommendedSong;

final currentLikedSongsLength = ValueNotifier<int>(userLikedSongsList.length);
final currentLikedPlaylistsLength = ValueNotifier<int>(
  userLikedPlaylists.length,
);
final currentOfflineSongsLength = ValueNotifier<int>(userOfflineSongs.length);
final currentRecentlyPlayedLength = ValueNotifier<int>(
  userRecentlyPlayed.length,
);

final lyrics = ValueNotifier<String?>(null);
String? lastFetchedLyrics;

int activeSongId = 0;

Future<List> fetchSongsList(String searchQuery) async {
  try {
    final List<Video> searchResults = await _yt.search.search(searchQuery);

    return searchResults.map((video) => returnSongLayout(0, video)).toList();
  } catch (e, stackTrace) {
    logger.log('Error in fetchSongsList', e, stackTrace);
    return [];
  }
}

Future<List> getRecommendedSongs() async {
  try {
    if (defaultRecommendations.value && userRecentlyPlayed.isNotEmpty) {
      final recent = userRecentlyPlayed.take(3).toList();

      final futures =
          recent.map((songData) async {
            final song = await _yt.videos.get(songData['ytid']);
            final relatedSongs = await _yt.videos.getRelatedVideos(song) ?? [];
            return relatedSongs
                .take(3)
                .map((s) => returnSongLayout(0, s))
                .toList();
          }).toList();

      final results = await Future.wait(futures);
      final playlistSongs = results.expand((list) => list).toList()..shuffle();
      return playlistSongs;
    } else {
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

      playlistSongs.shuffle();
      final seenYtIds = <String>{};
      playlistSongs.removeWhere((song) => !seenYtIds.add(song['ytid']));
      return playlistSongs.take(15).toList();
    }
  } catch (e, stackTrace) {
    logger.log('Error in getRecommendedSongs', e, stackTrace);
    return [];
  }
}

Future<List<dynamic>> getUserPlaylists() async {
  final playlistsByUser = [...userCustomPlaylists.value];
  for (final playlistID in userPlaylists) {
    try {
      final plist = await _yt.playlists.get(playlistID);
      playlistsByUser.add({
        'ytid': plist.id.toString(),
        'title': plist.title,
        'image': null,
        'source': 'user-youtube',
        'list': [],
      });
    } catch (e, stackTrace) {
      playlistsByUser.add({
        'ytid': playlistID.toString(),
        'title': 'Failed playlist',
        'image': null,
        'source': 'user-youtube',
        'list': [],
      });
      logger.log('Error occurred while fetching the playlist:', e, stackTrace);
    }
  }
  return playlistsByUser;
}

bool youtubeValidate(String url) {
  final regExp = RegExp(
    r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.*(list=([a-zA-Z0-9_-]+)).*$',
  );
  return regExp.hasMatch(url);
}

String? youtubePlaylistParser(String url) {
  if (!youtubeValidate(url)) {
    return null;
  }

  final regExp = RegExp('[&?]list=([a-zA-Z0-9_-]+)');
  final match = regExp.firstMatch(url);

  return match?.group(1);
}

Future<String> addUserPlaylist(String input, BuildContext context) async {
  String? playlistId = input;

  if (input.startsWith('http://') || input.startsWith('https://')) {
    playlistId = youtubePlaylistParser(input);

    if (playlistId == null) {
      return '${context.l10n!.notYTlist}!';
    }
  }

  try {
    final _playlist = await _yt.playlists.get(playlistId);

    if (userPlaylists.contains(playlistId)) {
      return '${context.l10n!.playlistAlreadyExists}!';
    }

    if (_playlist.title.isEmpty &&
        _playlist.author.isEmpty &&
        _playlist.videoCount == null) {
      return '${context.l10n!.invalidYouTubePlaylist}!';
    }

    userPlaylists.add(playlistId);
    addOrUpdateData('user', 'playlists', userPlaylists);
    return '${context.l10n!.addedSuccess}!';
  } catch (e) {
    return '${context.l10n!.error}: $e';
  }
}

String createCustomPlaylist(
  String playlistName,
  String? image,
  BuildContext context,
) {
  final customPlaylist = {
    'title': playlistName,
    'source': 'user-created',
    if (image != null) 'image': image,
    'list': [],
  };
  userCustomPlaylists.value = [...userCustomPlaylists.value, customPlaylist];
  addOrUpdateData('user', 'customPlaylists', userCustomPlaylists.value);
  return '${context.l10n!.addedSuccess}!';
}

String addSongInCustomPlaylist(
  BuildContext context,
  String playlistName,
  Map song, {
  int? indexToInsert,
}) {
  final customPlaylist = userCustomPlaylists.value.firstWhere(
    (playlist) => playlist['title'] == playlistName,
    orElse: () => null,
  );

  if (customPlaylist != null) {
    final List<dynamic> playlistSongs = customPlaylist['list'];
    if (playlistSongs.any(
      (playlistElement) => playlistElement['ytid'] == song['ytid'],
    )) {
      return context.l10n!.songAlreadyInPlaylist;
    }
    indexToInsert != null
        ? playlistSongs.insert(indexToInsert, song)
        : playlistSongs.add(song);
    addOrUpdateData('user', 'customPlaylists', userCustomPlaylists.value);
    return context.l10n!.songAdded;
  } else {
    logger.log('Custom playlist not found: $playlistName', null, null);
    return context.l10n!.error;
  }
}

bool removeSongFromPlaylist(
  Map playlist,
  Map songToRemove, {
  int? removeOneAtIndex,
}) {
  try {
    if (playlist['list'] == null) return false;

    final playlistSongs = List<dynamic>.from(playlist['list']);
    if (removeOneAtIndex != null) {
      if (removeOneAtIndex < 0 || removeOneAtIndex >= playlistSongs.length) {
        return false;
      }
      playlistSongs.removeAt(removeOneAtIndex);
    } else {
      final initialLength = playlistSongs.length;
      playlistSongs.removeWhere((song) => song['ytid'] == songToRemove['ytid']);
      if (playlistSongs.length == initialLength) return false;
    }

    playlist['list'] = playlistSongs;

    if (playlist['source'] == 'user-created') {
      addOrUpdateData('user', 'customPlaylists', userCustomPlaylists.value);
    } else {
      addOrUpdateData('user', 'playlists', userPlaylists);
    }

    return true;
  } catch (e, stackTrace) {
    logger.log('Error while removing song from playlist: ', e, stackTrace);
    return false;
  }
}

void removeUserPlaylist(String playlistId) {
  userPlaylists.remove(playlistId);
  addOrUpdateData('user', 'playlists', userPlaylists);
}

void removeUserCustomPlaylist(dynamic playlist) {
  final updatedPlaylists = List.from(userCustomPlaylists.value)
    ..remove(playlist);
  userCustomPlaylists.value = updatedPlaylists;
  addOrUpdateData('user', 'customPlaylists', userCustomPlaylists.value);
}

Future<void> updateSongLikeStatus(dynamic songId, bool add) async {
  if (add) {
    userLikedSongsList.add(
      await getSongDetails(userLikedSongsList.length, songId),
    );
  } else {
    userLikedSongsList.removeWhere((song) => song['ytid'] == songId);
  }
  addOrUpdateData('user', 'likedSongs', userLikedSongsList);
}

void moveLikedSong(int oldIndex, int newIndex) {
  final _song = userLikedSongsList[oldIndex];
  userLikedSongsList
    ..removeAt(oldIndex)
    ..insert(newIndex, _song);
  currentLikedSongsLength.value = userLikedSongsList.length;
  addOrUpdateData('user', 'likedSongs', userLikedSongsList);
}

Future<void> updatePlaylistLikeStatus(String playlistId, bool add) async {
  try {
    if (add) {
      final playlist = playlists.firstWhere(
        (playlist) => playlist['ytid'] == playlistId,
        orElse: () => <String, dynamic>{},
      );

      if (playlist.isNotEmpty) {
        userLikedPlaylists.add(playlist);
      } else {
        final playlistInfo = await getPlaylistInfoForWidget(playlistId);
        if (playlistInfo != null) {
          userLikedPlaylists.add(playlistInfo);
        }
      }
    } else {
      userLikedPlaylists.removeWhere(
        (playlist) => playlist['ytid'] == playlistId,
      );
    }

    addOrUpdateData('user', 'likedPlaylists', userLikedPlaylists);
  } catch (e, stackTrace) {
    logger.log('Error updating playlist like status: ', e, stackTrace);
  }
}

bool isSongAlreadyLiked(songIdToCheck) =>
    userLikedSongsList.any((song) => song['ytid'] == songIdToCheck);

bool isPlaylistAlreadyLiked(playlistIdToCheck) =>
    userLikedPlaylists.any((playlist) => playlist['ytid'] == playlistIdToCheck);

bool isSongAlreadyOffline(songIdToCheck) =>
    userOfflineSongs.any((song) => song['ytid'] == songIdToCheck);

Future<List> getPlaylists({
  String? query,
  int? playlistsNum,
  bool onlyLiked = false,
  String type = 'all',
}) async {
  // Early exit if there are no playlists to process.
  if (playlists.isEmpty ||
      (playlistsNum == null && query == null && suggestedPlaylists.isEmpty)) {
    return [];
  }

  // If a query is provided (without a limit), filter playlists based on the query and type,
  // and augment with online search results.
  if (query != null && playlistsNum == null) {
    final lowercaseQuery = query.toLowerCase();
    final filteredPlaylists =
        playlists.where((playlist) {
          final title = playlist['title'].toLowerCase();
          final matchesQuery = title.contains(lowercaseQuery);
          final matchesType =
              type == 'all' ||
              (type == 'album' && playlist['isAlbum'] == true) ||
              (type == 'playlist' && playlist['isAlbum'] != true);
          return matchesQuery && matchesType;
        }).toList();

    final searchTerm = type == 'album' ? '$query album' : query;
    final searchResults = await _yt.search.searchContent(
      searchTerm,
      filter: TypeFilters.playlist,
    );

    // Avoid duplicate online playlists.
    final existingYtIds =
        onlinePlaylists.map((p) => p['ytid'] as String).toSet();

    final newPlaylists =
        searchResults
            .whereType<SearchPlaylist>()
            .map((playlist) {
              final playlistMap = {
                'ytid': playlist.id.toString(),
                'title': playlist.title,
                'source': 'youtube',
                'list': [],
              };
              if (!existingYtIds.contains(playlistMap['ytid'])) {
                existingYtIds.add(playlistMap['ytid'].toString());
                return playlistMap;
              }
              return null;
            })
            .whereType<Map<String, dynamic>>()
            .toList();
    onlinePlaylists.addAll(newPlaylists);

    // Merge online playlists that match the query.
    filteredPlaylists.addAll(
      onlinePlaylists.where(
        (p) => p['title'].toLowerCase().contains(lowercaseQuery),
      ),
    );
    return filteredPlaylists;
  }

  // If a specific number of playlists is requested (without a query),
  // return a shuffled subset of suggested playlists.
  if (playlistsNum != null && query == null) {
    if (suggestedPlaylists.isEmpty) {
      suggestedPlaylists = List.from(playlists)..shuffle();
    }
    return suggestedPlaylists.take(playlistsNum).toList();
  }

  // If only liked playlists should be returned, ignore other parameters.
  if (onlyLiked && playlistsNum == null && query == null) {
    return userLikedPlaylists;
  }

  // If a specific type is requested, filter accordingly.
  if (type != 'all') {
    return playlists.where((playlist) {
      return type == 'album'
          ? playlist['isAlbum'] == true
          : playlist['isAlbum'] != true;
    }).toList();
  }

  // Default to returning all playlists.
  return playlists;
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

  final suggestions = await _yt.search.getQuerySuggestions(query);

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
      final segments =
          data.map((obj) {
            return Map.castFrom<String, dynamic, String, int>({
              'start': obj['segment'].first.toInt(),
              'end': obj['segment'].last.toInt(),
            });
          }).toList();
      return List.castFrom<dynamic, Map<String, int>>(segments);
    } else {
      return [];
    }
  } catch (e, stack) {
    logger.log('Error in getSkipSegments', e, stack);
    return [];
  }
}

void getSimilarSong(String songYtId) async {
  try {
    final song = await _yt.videos.get(songYtId);
    final relatedSongs = await _yt.videos.getRelatedVideos(song) ?? [];

    if (relatedSongs.isNotEmpty) {
      nextRecommendedSong = returnSongLayout(0, relatedSongs[0]);
    }
  } catch (e, stackTrace) {
    logger.log('Error while fetching next similar song:', e, stackTrace);
  }
}

Future<List> getSongsFromPlaylist(dynamic playlistId) async {
  final songList = await getData('cache', 'playlistSongs$playlistId') ?? [];

  if (songList.isEmpty) {
    await for (final song in _yt.playlists.getVideos(playlistId)) {
      songList.add(returnSongLayout(songList.length, song));
    }

    addOrUpdateData('cache', 'playlistSongs$playlistId', songList);
  }

  return songList;
}

Future updatePlaylistList(BuildContext context, String playlistId) async {
  final index = findPlaylistIndexByYtId(playlistId);
  if (index != -1) {
    final songList = [];
    await for (final song in _yt.playlists.getVideos(playlistId)) {
      songList.add(returnSongLayout(songList.length, song));
    }

    playlists[index]['list'] = songList;
    addOrUpdateData('cache', 'playlistSongs$playlistId', songList);
    showToast(context, context.l10n!.playlistUpdated);
  }
  return playlists[index];
}

int findPlaylistIndexByYtId(String ytid) {
  return playlists.indexWhere((playlist) => playlist['ytid'] == ytid);
}

Future<void> setActivePlaylist(Map info) async {
  activePlaylist = info;
  activeSongId = 0;

  await audioHandler.playSong(activePlaylist['list'][activeSongId]);
}

Future<Map?> getPlaylistInfoForWidget(
  dynamic id, {
  bool isArtist = false,
}) async {
  if (isArtist) {
    return {'title': id, 'list': await fetchSongsList(id)};
  }

  Map? playlist;

  // Check in local playlists.
  playlist = playlists.firstWhere((p) => p['ytid'] == id, orElse: () => null);

  // Check in user playlists if not found.
  if (playlist == null) {
    final userPl = await getUserPlaylists();
    playlist = userPl.firstWhere((p) => p['ytid'] == id, orElse: () => null);
  }

  // Check in cached online playlists if still not found.
  playlist ??= onlinePlaylists.firstWhere(
    (p) => p['ytid'] == id,
    orElse: () => null,
  );

  // If still not found, attempt to fetch playlist info.
  if (playlist == null) {
    try {
      final ytPlaylist = await _yt.playlists.get(id);
      playlist = {
        'ytid': ytPlaylist.id.toString(),
        'title': ytPlaylist.title,
        'image': null,
        'source': 'user-youtube',
        'list': [],
      };
      onlinePlaylists.add(playlist);
    } catch (e, stackTrace) {
      logger.log('Failed to fetch playlist info for id $id', e, stackTrace);
      return null;
    }
  }

  // If the playlist exists but its song list is empty, fetch and cache the songs.
  if (playlist['list'] == null ||
      (playlist['list'] is List && (playlist['list'] as List).isEmpty)) {
    playlist['list'] = await getSongsFromPlaylist(playlist['ytid']);
    if (!playlists.contains(playlist)) {
      playlists.add(playlist);
    }
  }

  return playlist;
}

final clients = {
  'tv': YoutubeApiClient.tv,
  'androidVr': YoutubeApiClient.androidVr,
  'safari': YoutubeApiClient.safari,
  'ios': YoutubeApiClient.ios,
  'android': YoutubeApiClient.android,
  'androidMusic': YoutubeApiClient.androidMusic,
  'mediaConnect': YoutubeApiClient.mediaConnect,
  'web': YoutubeApiClient.mweb,
};

Future<AudioOnlyStreamInfo> getSongManifest(String songId) async {
  try {
    final manifest = await _yt.videos.streams.getManifest(
      songId,
      ytClients: userChosenClients,
    );
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return audioStream;
  } catch (e, stackTrace) {
    logger.log('Error while getting song streaming manifest', e, stackTrace);
    rethrow; // Rethrow the exception to allow the caller to handle it
  }
}

const Duration _cacheDuration = Duration(hours: 3);

Future<String> getSong(String songId, bool isLive) async {
  try {
    final qualitySetting = audioQualitySetting.value;
    final cacheKey = 'song_${songId}_${qualitySetting}_url';

    final cachedUrl = await getData(
      'cache',
      cacheKey,
      cachingDuration: _cacheDuration,
    );

    unawaited(updateRecentlyPlayed(songId));

    if (cachedUrl != null) {
      return cachedUrl;
    }

    if (isLive) {
      return await getLiveStreamUrl(songId);
    }

    return await getAudioUrl(songId);
  } catch (e, stackTrace) {
    logger.log('Error while getting song streaming URL', e, stackTrace);
    rethrow;
  }
}

Future<String> getLiveStreamUrl(String songId) async {
  final streamInfo = await _yt.videos.streamsClient.getHttpLiveStreamUrl(
    VideoId(songId),
  );
  return streamInfo;
}

Future<String> getAudioUrl(String songId) async {
  final manifest = await _yt.videos.streamsClient.getManifest(songId);
  final audioQuality = selectAudioQuality(manifest.audioOnly.sortByBitrate());
  final audioUrl = audioQuality.url.toString();

  return audioUrl;
}

AudioStreamInfo selectAudioQuality(List<AudioStreamInfo> availableSources) {
  final qualitySetting = audioQualitySetting.value;

  if (qualitySetting == 'low') {
    return availableSources.last;
  } else if (qualitySetting == 'medium') {
    return availableSources[availableSources.length ~/ 2];
  } else if (qualitySetting == 'high') {
    return availableSources.first;
  } else {
    return availableSources.withHighestBitrate();
  }
}

Future<Map<String, dynamic>> getSongDetails(
  int songIndex,
  String songId,
) async {
  try {
    final song = await _yt.videos.get(songId);
    return returnSongLayout(songIndex, song);
  } catch (e, stackTrace) {
    logger.log('Error while getting song details', e, stackTrace);
    rethrow;
  }
}

Future<String?> getSongLyrics(String artist, String title) async {
  if (lastFetchedLyrics != '$artist - $title') {
    lyrics.value = null;
    var _lyrics = await LyricsManager().fetchLyrics(artist, title);
    if (_lyrics != null) {
      _lyrics = _lyrics.replaceAll(RegExp(r'\n{2}'), '\n');
      _lyrics = _lyrics.replaceAll(RegExp(r'\n{4}'), '\n\n');
      lyrics.value = _lyrics;
    } else {
      lyrics.value = 'not found';
    }

    lastFetchedLyrics = '$artist - $title';
    return _lyrics;
  }

  return lyrics.value;
}

Future<void> makeSongOffline(dynamic song) async {
  try {
    final _dir = await getApplicationSupportDirectory();
    final _audioDirPath = '${_dir.path}/tracks';
    final _artworkDirPath = '${_dir.path}/artworks';
    final String ytid = song['ytid'];
    final _audioFile = File('$_audioDirPath/$ytid.m4a');
    final _artworkFile = File('$_artworkDirPath/$ytid.jpg');

    await Directory(_audioDirPath).create(recursive: true);
    await Directory(_artworkDirPath).create(recursive: true);

    try {
      final audioManifest = await getSongManifest(ytid);
      final stream = _yt.videos.streamsClient.get(audioManifest);
      final fileStream = _audioFile.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();
    } catch (e, stackTrace) {
      logger.log('Error downloading audio file', e, stackTrace);
      throw Exception('Failed to download audio: $e');
    }

    try {
      final artworkFile = await _downloadAndSaveArtworkFile(
        song['highResImage'],
        _artworkFile.path,
      );

      if (artworkFile != null) {
        song['artworkPath'] = artworkFile.path;
        song['highResImage'] = artworkFile.path;
        song['lowResImage'] = artworkFile.path;
      }
    } catch (e, stackTrace) {
      logger.log('Error downloading artwork', e, stackTrace);
    }

    song['audioPath'] = _audioFile.path;
    userOfflineSongs.add(song);
    addOrUpdateData('userNoBackup', 'offlineSongs', userOfflineSongs);
    currentOfflineSongsLength.value = userOfflineSongs.length;
  } catch (e, stackTrace) {
    logger.log('Error making song offline', e, stackTrace);
    rethrow;
  }
}

Future<void> removeSongFromOffline(dynamic songId) async {
  final _dir = await getApplicationSupportDirectory();
  final _audioDirPath = '${_dir.path}/tracks';
  final _artworkDirPath = '${_dir.path}/artworks';
  final _audioFile = File('$_audioDirPath/$songId.m4a');
  final _artworkFile = File('$_artworkDirPath/$songId.jpg');

  if (await _audioFile.exists()) await _audioFile.delete(recursive: true);
  if (await _artworkFile.exists()) await _artworkFile.delete(recursive: true);

  userOfflineSongs.removeWhere((song) => song['ytid'] == songId);
  currentOfflineSongsLength.value = userOfflineSongs.length;
  addOrUpdateData('userNoBackup', 'offlineSongs', userOfflineSongs);
}

Future<File?> _downloadAndSaveArtworkFile(String url, String filePath) async {
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      logger.log(
        'Failed to download file. Status code: ${response.statusCode}',
        null,
        null,
      );
    }
  } catch (e, stackTrace) {
    logger.log('Error downloading and saving file', e, stackTrace);
  }

  return null;
}

const recentlyPlayedSongsLimit = 50;

Future<void> updateRecentlyPlayed(dynamic songId) async {
  if (userRecentlyPlayed.length == 1 && userRecentlyPlayed[0]['ytid'] == songId)
    return;
  if (userRecentlyPlayed.length >= recentlyPlayedSongsLimit) {
    userRecentlyPlayed.removeLast();
  }

  userRecentlyPlayed.removeWhere((song) => song['ytid'] == songId);
  currentRecentlyPlayedLength.value = userRecentlyPlayed.length;

  final newSongDetails = await getSongDetails(
    userRecentlyPlayed.length,
    songId,
  );

  userRecentlyPlayed.insert(0, newSongDetails);
  currentRecentlyPlayedLength.value = userRecentlyPlayed.length;
  addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed);
}
