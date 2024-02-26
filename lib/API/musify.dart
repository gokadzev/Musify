import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
List userCustomPlaylists =
    Hive.box('user').get('customPlaylists', defaultValue: []);
List userLikedSongsList = Hive.box('user').get('likedSongs', defaultValue: []);
List userLikedPlaylists =
    Hive.box('user').get('likedPlaylists', defaultValue: []);
List userRecentlyPlayed =
    Hive.box('user').get('recentlyPlayedSongs', defaultValue: []);
List userOfflineSongs =
    Hive.box('userNoBackup').get('offlineSongs', defaultValue: []);
List suggestedPlaylists = [];
Map activePlaylist = {
  'ytid': '',
  'title': 'No Playlist',
  'header_desc': '',
  'image': '',
  'list': [],
};

final currentLikedSongsLength = ValueNotifier<int>(userLikedSongsList.length);
final currentLikedPlaylistsLength =
    ValueNotifier<int>(userLikedPlaylists.length);
final currentOfflineSongsLength = ValueNotifier<int>(userOfflineSongs.length);

final lyrics = ValueNotifier<String?>(null);
String? lastFetchedLyrics;

int id = 0;

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
    final playlistSongs = [...userLikedSongsList, ...userRecentlyPlayed];

    if (globalSongs.isEmpty) {
      const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';
      globalSongs = await getSongsFromPlaylist(playlistId);
    }

    playlistSongs.addAll(globalSongs.take(10));

    if (userCustomPlaylists.isNotEmpty) {
      for (final userPlaylist in userCustomPlaylists) {
        final _list = userPlaylist['list'] as List;
        _list.shuffle();
        playlistSongs.addAll(_list.take(5));
      }
    }

    playlistSongs.shuffle();

    final seenYtIds = <String>{};
    playlistSongs.removeWhere((song) => !seenYtIds.add(song['ytid']));

    return playlistSongs.take(15).toList();
  } catch (e, stackTrace) {
    logger.log('Error in getRecommendedSongs', e, stackTrace);
    return [];
  }
}

Future<List<dynamic>> getUserPlaylists() async {
  final playlistsByUser = [...userCustomPlaylists];
  for (final playlistID in userPlaylists) {
    try {
      final plist = await _yt.playlists.get(playlistID);
      playlistsByUser.add({
        'ytid': plist.id.toString(),
        'title': plist.title,
        'header_desc': plist.description.length < 120
            ? plist.description
            : plist.description.substring(0, 120),
        'image': null,
        'list': [],
      });
    } catch (e, stackTrace) {
      logger.log(
        'Error occurred while fetching playlist so playlist will be removed:',
        e,
        stackTrace,
      );
      userPlaylists.remove(playlistID);
      addOrUpdateData('user', 'playlists', userPlaylists);
    }
  }
  return playlistsByUser;
}

Future<String> addUserPlaylist(String playlistId, BuildContext context) async {
  if (playlistId.startsWith('http://') || playlistId.startsWith('https://')) {
    return '${context.l10n!.notYTlist}!';
  } else {
    try {
      await _yt.playlists.get(playlistId);
      userPlaylists.add(playlistId);
      addOrUpdateData('user', 'playlists', userPlaylists);
      return '${context.l10n!.addedSuccess}!';
    } catch (e) {
      return '${context.l10n!.error}!';
    }
  }
}

String createCustomPlaylist(
  String playlistName,
  String? image,
  String? description,
  BuildContext context,
) {
  final customPlaylist = {
    'title': playlistName,
    'isCustom': true,
    if (image != null) 'image': image,
    if (description != null) 'header_desc': description,
    'list': [],
  };
  userCustomPlaylists.add(customPlaylist);
  addOrUpdateData('user', 'customPlaylists', userCustomPlaylists);
  return '${context.l10n!.addedSuccess}!';
}

String addSongInCustomPlaylist(
  String playlistName,
  Map song, {
  int? indexToInsert,
}) {
  final customPlaylist = userCustomPlaylists.firstWhere(
    (playlist) => playlist['title'] == playlistName,
    orElse: () => null,
  );

  if (customPlaylist != null) {
    final List<dynamic> playlistSongs = customPlaylist['list'];
    indexToInsert != null
        ? playlistSongs.insert(indexToInsert, song)
        : playlistSongs.add(song);
    addOrUpdateData('user', 'customPlaylists', userCustomPlaylists);
    return 'Song added to custom playlist: $playlistName';
  } else {
    return 'Custom playlist not found: $playlistName';
  }
}

void removeSongFromPlaylist(
  Map playlist,
  Map songToRemove, {
  int? removeOneAtIndex,
}) {
  if (playlist['list'] == null) return;
  final playlistSongs = List<dynamic>.from(playlist['list']);
  removeOneAtIndex != null
      ? playlistSongs.removeAt(removeOneAtIndex)
      : playlistSongs
          .removeWhere((song) => song['ytid'] == songToRemove['ytid']);
  playlist['list'] = playlistSongs;
  if (playlist['isCustom'])
    addOrUpdateData('user', 'customPlaylists', userCustomPlaylists);
  else
    addOrUpdateData('user', 'playlists', userPlaylists);
}

void removeUserPlaylist(String playlistId) {
  userPlaylists.remove(playlistId);
  addOrUpdateData('user', 'playlists', userPlaylists);
}

void removeUserCustomPlaylist(dynamic playlist) {
  userCustomPlaylists.remove(playlist);
  addOrUpdateData('user', 'customPlaylists', userCustomPlaylists);
}

Future<void> updateSongLikeStatus(dynamic songId, bool add) async {
  if (add) {
    userLikedSongsList
        .add(await getSongDetails(userLikedSongsList.length, songId));
  } else {
    userLikedSongsList.removeWhere((song) => song['ytid'] == songId);
  }
  addOrUpdateData('user', 'likedSongs', userLikedSongsList);
}

void moveLikedSong(int oldIndex, int newIndex) {
  final _song = userLikedSongsList[oldIndex];
  userLikedSongsList.removeAt(oldIndex);
  userLikedSongsList.insert(newIndex, _song);
  currentLikedSongsLength.value = userLikedSongsList.length;
  addOrUpdateData('user', 'likedSongs', userLikedSongsList);
}

Future<void> updatePlaylistLikeStatus(
  String playlistId,
  String playlistImage,
  String playlistTitle,
  bool add,
) async {
  if (add) {
    userLikedPlaylists.add({
      'ytid': playlistId,
      'title': playlistTitle,
      'header_desc': '',
      'image': playlistImage,
      'list': [],
    });
  } else {
    userLikedPlaylists
        .removeWhere((playlist) => playlist['ytid'] == playlistId);
  }
  addOrUpdateData('user', 'likedPlaylists', userLikedPlaylists);
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
}) async {
  if (playlistsNum != null && query == null) {
    if (suggestedPlaylists.isEmpty) {
      suggestedPlaylists = playlists.toList()..shuffle();
    }
    return suggestedPlaylists.take(playlistsNum).toList();
  }

  if (query != null && playlistsNum == null) {
    final lowercaseQuery = query.toLowerCase();
    return playlists.where((playlist) {
      final lowercaseTitle = playlist['title'].toLowerCase();
      return lowercaseTitle.contains(lowercaseQuery);
    }).toList();
  }

  if (onlyLiked && playlistsNum == null && query == null) {
    return userLikedPlaylists;
  }

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
  } catch (e, stack) {
    logger.log('Error in getSkipSegments', e, stack);
    return [];
  }
}

Future<Map> getRandomSong() async {
  if (globalSongs.isEmpty) {
    const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';
    globalSongs = await getSongsFromPlaylist(playlistId);
  }

  return globalSongs[Random().nextInt(globalSongs.length)];
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

Future updatePlaylistList(
  BuildContext context,
  String playlistId,
) async {
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
  id = 0;

  await audioHandler.playSong(activePlaylist['list'][id]);
}

Future<Map<String, dynamic>?> getPlaylistInfoForWidget(
  dynamic id, {
  bool isArtist = false,
}) async {
  if (!isArtist) {
    Map<String, dynamic>? playlist =
        playlists.firstWhere((list) => list['ytid'] == id, orElse: () => null);

    if (playlist == null) {
      final usPlaylists = await getUserPlaylists();
      playlist = usPlaylists.firstWhere(
        (list) => list['ytid'] == id,
        orElse: () => null,
      );
    }

    if (playlist != null && playlist['list'].isEmpty) {
      playlist['list'] = await getSongsFromPlaylist(playlist['ytid']);
      if (!playlists.contains(playlist)) {
        playlists.add(playlist);
      }
    }

    return playlist;
  } else {
    final playlist = <String, dynamic>{
      'title': id,
    };

    playlist['list'] = await fetchSongsList(id);

    return playlist;
  }
}

Future<AudioOnlyStreamInfo> getSongManifest(String songId) async {
  try {
    final manifest = await _yt.videos.streamsClient.getManifest(songId);
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return audioStream;
  } catch (e, stackTrace) {
    logger.log('Error while getting song streaming manifest', e, stackTrace);
    rethrow; // Rethrow the exception to allow the caller to handle it
  }
}

const Duration _cacheDuration = Duration(hours: 6);

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
    } else if (isLive) {
      return await getLiveStreamUrl(songId);
    } else {
      return await getAudioUrl(songId, cacheKey);
    }
  } catch (e, stackTrace) {
    logger.log('Error while getting song streaming URL', e, stackTrace);
    rethrow;
  }
}

Future<String> getLiveStreamUrl(String songId) async {
  final streamInfo =
      await _yt.videos.streamsClient.getHttpLiveStreamUrl(VideoId(songId));
  return streamInfo;
}

Future<String> getAudioUrl(
  String songId,
  String cacheKey,
) async {
  final manifest = await _yt.videos.streamsClient.getManifest(songId);
  final audioQuality = selectAudioQuality(manifest.audioOnly.sortByBitrate());
  final audioUrl = audioQuality.url.toString();

  addOrUpdateData('cache', cacheKey, audioUrl);
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

Future getSongLyrics(String artist, String title) async {
  if (lastFetchedLyrics != '$artist - $title') {
    lyrics.value = null;
    final _lyrics = await LyricsManager().fetchLyrics(artist, title);
    if (_lyrics != null) {
      lyrics.value = _lyrics;
    } else {
      lyrics.value = 'not found';
    }

    lastFetchedLyrics = '$artist - $title';
    return _lyrics;
  }

  return lyrics.value;
}

void makeSongOffline(dynamic song) async {
  final _dir = await getApplicationSupportDirectory();
  final _audioDirPath = '${_dir.path}/tracks';
  final _artworkDirPath = '${_dir.path}/artworks';
  final String ytid = song['ytid'];
  final _audioFile = File('$_audioDirPath/$ytid.m4a');
  final _artworkFile = File('$_artworkDirPath/$ytid.jpg');

  await Directory(_audioDirPath).create(recursive: true);
  await Directory(_artworkDirPath).create(recursive: true);

  final audioManifest = await getSongManifest(ytid);
  final stream = _yt.videos.streamsClient.get(audioManifest);
  final fileStream = _audioFile.openWrite();
  await stream.pipe(fileStream);
  await fileStream.flush();
  await fileStream.close();

  final artworkFile = await _downloadAndSaveArtworkFile(
    song['highResImage'],
    _artworkFile.path,
  );

  if (artworkFile != null) {
    song['artworkPath'] = artworkFile.path;
    song['highResImage'] = artworkFile.path;
    song['lowResImage'] = artworkFile.path;
  }
  song['audioPath'] = _audioFile.path;
  userOfflineSongs.add(song);
  addOrUpdateData('userNoBackup', 'offlineSongs', userOfflineSongs);
}

void removeSongFromOffline(dynamic songId) async {
  final _dir = await getApplicationSupportDirectory();
  final _audioDirPath = '${_dir.path}/tracks';
  final _artworkDirPath = '${_dir.path}/artworks';
  final _audioFile = File('$_audioDirPath/$songId.m4a');
  final _artworkFile = File('$_artworkDirPath/$songId.jpg');

  if (await _audioFile.exists()) await _audioFile.delete();
  if (await _artworkFile.exists()) await _artworkFile.delete();

  userOfflineSongs.removeWhere((song) => song['ytid'] == songId);
  addOrUpdateData('userNoBackup', 'offlineSongs', userOfflineSongs);
  currentOfflineSongsLength.value = userOfflineSongs.length;
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

Future<void> updateRecentlyPlayed(dynamic songId) async {
  if (userRecentlyPlayed.length >= 20) {
    userRecentlyPlayed.removeLast();
  }
  userRecentlyPlayed.removeWhere((song) => song['ytid'] == songId);

  final newSongDetails =
      await getSongDetails(userRecentlyPlayed.length, songId);

  userRecentlyPlayed.insert(0, newSongDetails);
  addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed);
}
