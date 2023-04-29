import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/lyrics_service.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final yt = YoutubeExplode();

final random = Random();

List playlists = [];
List userPlaylists = Hive.box('user').get('playlists', defaultValue: []);
List userLikedSongsList = Hive.box('user').get('likedSongs', defaultValue: []);
List userLikedPlaylists =
    Hive.box('user').get('likedPlaylists', defaultValue: []);
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

final lyrics = ValueNotifier<String>('null');
String lastFetchedLyrics = 'null';

int id = 0;

Future<List> fetchSongsList(String searchQuery) async {
  final List list = await yt.search.search(searchQuery);
  final searchedList = [
    for (final s in list)
      returnSongLayout(
        0,
        s,
      )
  ];

  return searchedList;
}

Future get10Music(dynamic playlistid) async {
  final List playlistSongs =
      await getData('cache', 'playlist10Songs$playlistid') ?? [];
  if (playlistSongs.isEmpty) {
    try {
      final List<dynamic> ytSongs =
          await yt.playlists.getVideos(playlistid).take(10).toList();
      final tenSongs = List<dynamic>.generate(
        ytSongs.length,
        (index) => returnSongLayout(index, ytSongs[index]),
      );
      playlistSongs.addAll(tenSongs);

      addOrUpdateData('cache', 'playlist10Songs$playlistid', playlistSongs);
    } catch (e) {
      logger.e('Error retrieving playlist songs: $e');
      return null;
    }
  }
  return playlistSongs;
}

Future<List<dynamic>> getUserPlaylists() async {
  final playlistsByUser = [];
  for (final playlistID in userPlaylists) {
    final plist = await yt.playlists.get(playlistID);
    playlistsByUser.add({
      'ytid': plist.id.toString(),
      'title': plist.title,
      'header_desc': plist.description.length < 120
          ? plist.description
          : plist.description.substring(0, 120),
      'image': '',
      'list': []
    });
  }
  return playlistsByUser;
}

String addUserPlaylist(String playlistId, BuildContext context) {
  if (playlistId.length != 34) {
    return '${context.l10n()!.notYTlist}!';
  } else {
    userPlaylists.add(playlistId);
    addOrUpdateData('user', 'playlists', userPlaylists);
    return '${context.l10n()!.addedSuccess}!';
  }
}

void removeUserPlaylist(String playlistId) {
  userPlaylists.remove(playlistId);
  addOrUpdateData('user', 'playlists', userPlaylists);
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
      suggestedPlaylists =
          (playlists.toList()..shuffle()).take(playlistsNum).toList();
    }
    return suggestedPlaylists;
  } else if (query != null && playlistsNum == null) {
    return playlists
        .where(
          (playlist) =>
              playlist['title'].toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  } else if (onlyLiked && playlistsNum == null && query == null) {
    return userLikedPlaylists;
  } else {
    return playlists;
  }
}

Future<void> readPlaylistsFromFile() async {
  playlists =
      json.decode(await rootBundle.loadString('assets/db/playlists.db.json'))
          as List;
}

Future<List> getSearchSuggestions(String query) async {
  const baseUrl =
      'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=';
  final link = Uri.parse(baseUrl + query);
  try {
    final response = await http.get(
      link,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; rv:96.0) Gecko/20100101 Firefox/96.0'
      },
    );
    if (response.statusCode != 200) {
      return [];
    }
    final res = jsonDecode(response.body)[1] as List;
    return res;
  } catch (e) {
    logger.e('Error in getSearchSuggestions: $e');
    return [];
  }
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
            'music_offtopic'
          ],
          'actionType': 'skip'
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
    logger.e('$e $stack');
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

Future<void> setActivePlaylist(Map info) async {
  final plist = info['list'] as List;
  activePlaylist = info;
  if (plist is List<AudioModel>) {
    activePlaylist['list'] = [];
    id = 0;
    final activeTempPlaylist = <AudioSource>[
      for (final song in plist)
        createAudioSource(songModelToMediaItem(song, song.data))
    ];

    await addSongs(activeTempPlaylist);
    await setNewPlaylist();

    await audioPlayer.play();
  } else {
    id = 0;
    await playSong(activePlaylist['list'][id]);
  }
}

Future getPlaylistInfoForWidget(dynamic id) async {
  var searchPlaylist = playlists.where((list) => list['ytid'] == id).toList();
  var isUserPlaylist = false;

  if (searchPlaylist.isEmpty) {
    final usPlaylists = await getUserPlaylists();
    searchPlaylist = usPlaylists.where((list) => list['ytid'] == id).toList();
    isUserPlaylist = true;
  }

  final playlist = searchPlaylist[0];

  if (playlist['list'].length == 0) {
    searchPlaylist[searchPlaylist.indexOf(playlist)]['list'] =
        await getSongsFromPlaylist(playlist['ytid']);
    if (!isUserPlaylist) {
      playlists[playlists.indexOf(playlist)]['list'] =
          searchPlaylist[searchPlaylist.indexOf(playlist)]['list'];
    }
  }

  return playlist;
}

Future<String> getSong(dynamic songId, bool isLive) async {
  final url = isLive
      ? await yt.videos.streamsClient.getHttpLiveStreamUrl(VideoId(songId))
      : (await yt.videos.streamsClient.getManifest(songId))
          .audioOnly
          .withHighestBitrate()
          .url
          .toString();
  return url;
}

Future getSongDetails(dynamic songIndex, dynamic songId) async {
  final song = await yt.videos.get(songId);
  return returnSongLayout(
    songIndex,
    song,
  );
}

Future getSongLyrics(String artist, String title) async {
  if (lastFetchedLyrics != '$artist - $title') {
    lyrics.value = 'null';
    final _lyrics = await Lyrics().getLyrics(artist: artist, track: title);
    lyrics.value = _lyrics;
    lastFetchedLyrics = '$artist - $title';
    return _lyrics;
  }

  return lyrics.value;
}
