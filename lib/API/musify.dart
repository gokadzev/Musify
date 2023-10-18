import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musify/enums/quality_enum.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/lyrics_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final yt = YoutubeExplode();

final random = Random();

List playlists = [];
List userPlaylists = Hive.box('user').get('playlists', defaultValue: []);
List userCustomPlaylists =
    Hive.box('user').get('customPlaylists', defaultValue: []);
List userLikedSongsList = Hive.box('user').get('likedSongs', defaultValue: []);
List userLikedPlaylists =
    Hive.box('user').get('likedPlaylists', defaultValue: []);
List userRecentlyPlayed =
    Hive.box('user').get('recentlyPlayedSongs', defaultValue: []);
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

final currentRecentlyPlayedLength =
    ValueNotifier<int>(userRecentlyPlayed.length);

final lyrics = ValueNotifier<String?>(null);
String? lastFetchedLyrics;

int id = 0;

Future<List> fetchSongsList(String searchQuery) async {
  try {
    final List<Video> searchResults = await yt.search.search(searchQuery);

    return searchResults.map((video) => returnSongLayout(0, video)).toList();
  } catch (e) {
    logger.log('Error in fetchSongsList: $e');
    return [];
  }
}

Future<List> getRecommendedSongs() async {
  try {
    const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';
    var playlistSongs = [...userLikedSongsList, ...userRecentlyPlayed];

    final ytSongs = await getSongsFromPlaylist(playlistId);
    playlistSongs += ytSongs.take(10).toList();

    playlistSongs.shuffle();

    final seenYtIds = <String>{};
    playlistSongs.removeWhere((song) => !seenYtIds.add(song['ytid']));

    return playlistSongs.take(15).toList();
  } catch (e) {
    logger.log('Error in getRecommendedSongs: $e');
    return [];
  }
}

Future<List<dynamic>> getUserPlaylists() async {
  final playlistsByUser = [...userCustomPlaylists];
  for (final playlistID in userPlaylists) {
    final plist = await yt.playlists.get(playlistID);
    playlistsByUser.add({
      'ytid': plist.id.toString(),
      'title': plist.title,
      'header_desc': plist.description.length < 120
          ? plist.description
          : plist.description.substring(0, 120),
      'image': '',
      'list': [],
    });
  }
  return playlistsByUser;
}

String addUserPlaylist(String playlistId, BuildContext context) {
  if (playlistId.length != 34) {
    return '${context.l10n!.notYTlist}!';
  } else {
    userPlaylists.add(playlistId);
    addOrUpdateData('user', 'playlists', userPlaylists);
    return '${context.l10n!.addedSuccess}!';
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
  dynamic song, {
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
  dynamic playlist,
  dynamic songToRemove, {
  int? removeOneAtIndex,
}) {
  if (playlist == null || playlist['list'] == null) return;
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

Future<void> updatePlaylistLikeStatus(
  dynamic playlistId,
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

Future<List> getPlaylists({
  String? query,
  int? playlistsNum,
  bool onlyLiked = false,
}) async {
  if (playlists.isEmpty) {
    await readPlaylistsFromFile();
  }

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

Future<void> readPlaylistsFromFile() async {
  playlists =
      json.decode(await rootBundle.loadString('assets/db/playlists.db.json'))
          as List;
}

Future<List<String>> getSearchSuggestions(String query) async {
  const baseUrl = 'https://suggestqueries.google.com/complete/search';
  final parameters = {
    'client': 'firefox',
    'ds': 'yt',
    'q': query,
  };

  final uri = Uri.parse(baseUrl).replace(queryParameters: parameters);

  try {
    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; rv:96.0) Gecko/20100101 Firefox/96.0',
      },
    );

    if (response.statusCode == 200) {
      final suggestions = jsonDecode(response.body)[1] as List<dynamic>;
      final suggestionStrings = suggestions.cast<String>().toList();
      return suggestionStrings;
    }
  } catch (e) {
    logger.log('Error in getSearchSuggestions: $e');
  }

  return <String>[];
}

Future<String?> getArtistArtwork(String artistName) async {
  artistName = artistName.replaceAll(RegExp(r',| FEAT| &| FT'), '').trim();

  try {
    final response = await http.get(
      Uri.parse('https://genius.com/artists/$artistName'),
    );

    if (response.statusCode == 200) {
      final body = response.body;
      const startToken =
          '<div class="user_avatar profile_header-avatar clipped_background_image';
      final start = body.indexOf(startToken);
      if (start != -1) {
        final urlStart = body.indexOf('background-image: url(', start);
        if (urlStart != -1) {
          final urlEnd = body.indexOf("'", urlStart + 23);
          if (urlEnd != -1) {
            final finalLink = body.substring(urlStart + 23, urlEnd);
            if (finalLink.startsWith('https')) {
              return finalLink.replaceFirst('.1000x1000x1', '.300x300x1');
            }
          }
        }
      }
    }
  } catch (e) {
    return null;
  }

  return null;
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
    logger.log('Error in getSkipSegments: $e $stack');
    return [];
  }
}

Future<Map> getRandomSong() async {
  const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';
  final playlistSongs = await getSongsFromPlaylist(playlistId);

  return playlistSongs[random.nextInt(playlistSongs.length)];
}

Future<List> getSongsFromPlaylist(dynamic playlistId) async {
  final songList = await getData('cache', 'playlistSongs$playlistId') ?? [];

  if (songList.isEmpty) {
    await for (final song in yt.playlists.getVideos(playlistId)) {
      songList.add(returnSongLayout(songList.length, song));
    }

    addOrUpdateData('cache', 'playlistSongs$playlistId', songList);
  }

  return songList;
}

Future updatePlaylistList(
  BuildContext context,
  dynamic playlistId,
) async {
  final index = findPlaylistIndexByYtId(playlistId);
  if (index != -1) {
    final songList = [];
    await for (final song in yt.playlists.getVideos(playlistId)) {
      songList.add(returnSongLayout(songList.length, song));
    }

    playlists[index]['list'] = songList;
    addOrUpdateData('cache', 'playlistSongs$playlistId', songList);
    showToast(context, context.l10n!.playlistUpdated);
  }
  return playlists[index];
}

int findPlaylistIndexByYtId(String ytid) {
  for (var i = 0; i < playlists.length; i++) {
    if (playlists[i]['ytid'] == ytid) {
      return i;
    }
  }
  return -1;
}

Future<void> setActivePlaylist(Map info) async {
  activePlaylist = info;
  id = 0;

  await audioHandler.playSong(activePlaylist['list'][id]);
}

Future<Map<String, dynamic>?> getPlaylistInfoForWidget(dynamic id) async {
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
}

Future<AudioOnlyStreamInfo> getSongManifest(String songId) async {
  try {
    final manifest = await yt.videos.streamsClient.getManifest(songId);
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return audioStream;
  } catch (e) {
    logger.log('Error while getting song streaming manifest: $e');
    rethrow; // Rethrow the exception to allow the caller to handle it
  }
}

Future<String> getSong(String songId, bool isLive) async {
  try {
    final isQualityChanged = audioQualitySetting.value != null;

    final cacheKey = isQualityChanged
        ? 'song_${songId}_${audioQualitySetting.value!.name}_url'
        : 'song_${songId}__url';

    final cachedUrl = await getData(
      'cache',
      cacheKey,
      cachingDuration: const Duration(hours: 12),
    );

    if (cachedUrl != null) {
      return cachedUrl;
    }

    if (isLive) {
      return await getLiveStreamUrl(songId);
    } else {
      return await getAudioUrl(songId, isQualityChanged, cacheKey);
    }
  } catch (e) {
    logger.log('Error while getting song streaming URL: $e');
    rethrow;
  }
}

Future<String> getLiveStreamUrl(String songId) async {
  final streamInfo =
      await yt.videos.streamsClient.getHttpLiveStreamUrl(VideoId(songId));
  return streamInfo;
}

Future<String> getAudioUrl(
  String songId,
  bool isQualityChanged,
  String cacheKey,
) async {
  final manifest = await yt.videos.streamsClient.getManifest(songId);
  String audioUrl;

  if (!isQualityChanged) {
    audioUrl = manifest.audioOnly.withHighestBitrate().url.toString();
  } else {
    final availableSources = manifest.audioOnly.sortByBitrate();
    final selectedQuality =
        audioQualitySetting.value ?? AudioQuality.bestQuality;

    switch (selectedQuality) {
      case AudioQuality.lowQuality:
        audioUrl = availableSources.last.url.toString();
        break;
      case AudioQuality.mediumQuality:
        audioUrl =
            availableSources[availableSources.length ~/ 2].url.toString();
        break;
      case AudioQuality.bestQuality:
        audioUrl = availableSources.first.url.toString();
        break;
      default:
        audioUrl = availableSources.first.url.toString();
        break;
    }
  }

  unawaited(updateRecentlyPlayed(songId));
  addOrUpdateData('cache', cacheKey, audioUrl);
  return audioUrl;
}

Future<Map<String, dynamic>> getSongDetails(
  dynamic songIndex,
  dynamic songId,
) async {
  try {
    final song = await yt.videos.get(songId);
    return returnSongLayout(songIndex, song);
  } catch (e) {
    logger.log('Error while getting song details: $e');
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

Future<void> updateRecentlyPlayed(dynamic songId) async {
  if (userRecentlyPlayed.length >= 20) {
    userRecentlyPlayed.removeAt(0);
  }
  userRecentlyPlayed.removeWhere((song) => song['ytid'] == songId);

  final newSongDetails =
      await getSongDetails(userRecentlyPlayed.length, songId);
  userRecentlyPlayed.add(newSongDetails);
  addOrUpdateData('user', 'recentlyPlayedSongs', userRecentlyPlayed);
}
