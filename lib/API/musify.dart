import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
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
List suggestedPlaylists = [];
Map activePlaylist = {
  'ytid': '',
  'title': 'No Playlist',
  'subtitle': 'Just Updated',
  'header_desc': '',
  'type': 'playlist',
  'image': '',
  'list': [],
};

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
    var index = 0;
    await for (final song in yt.playlists.getVideos(playlistid).take(10)) {
      playlistSongs.add(
        returnSongLayout(
          index,
          song,
        ),
      );
      index += 1;
    }

    addOrUpdateData('cache', 'playlist10Songs$playlistid', playlistSongs);
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
      'subtitle': 'Just Updated',
      'header_desc': plist.description.length < 120
          ? plist.description
          : plist.description.substring(0, 120),
      'type': 'playlist',
      'image': '',
      'list': []
    });
  }
  return playlistsByUser;
}

String addUserPlaylist(String playlistId, BuildContext context) {
  if (playlistId.length != 34) {
    return '${AppLocalizations.of(context)!.notYTlist}!';
  } else {
    userPlaylists.add(playlistId);
    addOrUpdateData('user', 'playlists', userPlaylists);
    return '${AppLocalizations.of(context)!.addedSuccess}!';
  }
}

void removeUserPlaylist(String playlistId) {
  userPlaylists.remove(playlistId);
  addOrUpdateData('user', 'playlists', userPlaylists);
}

Future<void> addUserLikedSong(dynamic songId) async {
  userLikedSongsList
      .add(await getSongDetails(userLikedSongsList.length, songId));
  addOrUpdateData('user', 'likedSongs', userLikedSongsList);
}

void removeUserLikedSong(dynamic songId) {
  userLikedSongsList.removeWhere((song) => song['ytid'] == songId);
  addOrUpdateData('user', 'likedSongs', userLikedSongsList);
}

bool isSongAlreadyLiked(dynamic songId) {
  return userLikedSongsList.where((song) => song['ytid'] == songId).isNotEmpty;
}

Future<List> getPlaylists([int? playlistsNum]) async {
  if (playlists.isEmpty) {
    await readPlaylistsFromFile();
  }

  if (playlistsNum != null) {
    if (suggestedPlaylists.isEmpty) {
      suggestedPlaylists =
          (playlists.toList()..shuffle()).take(playlistsNum).toList();
    }
    return suggestedPlaylists;
  } else {
    return playlists;
  }
}

Future<void> readPlaylistsFromFile() async {
  playlists =
      json.decode(await rootBundle.loadString('assets/db/playlists.db.json'))
          as List;
}

Future<List> searchPlaylist(String query) async {
  if (playlists.isEmpty) {
    await readPlaylistsFromFile();
  }

  return playlists
      .where(
        (playlist) =>
            playlist['title'].toLowerCase().contains(query.toLowerCase()),
      )
      .toList();
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
    debugPrint('Error in getSearchSuggestions: $e');
    return [];
  }
}

Future<Map> getRandomSong() async {
  const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';
  final List playlistSongs = await getSongsFromPlaylist(playlistId);

  return playlistSongs[random.nextInt(playlistSongs.length)];
}

Future getSongsFromPlaylist(dynamic playlistid) async {
  final List playlistSongs =
      await getData('cache', 'playlistSongs$playlistid') ?? [];
  if (playlistSongs.isEmpty) {
    var index = 0;
    await for (final song in yt.playlists.getVideos(playlistid)) {
      playlistSongs.add(
        returnSongLayout(
          index,
          song,
        ),
      );
      index += 1;
    }
    addOrUpdateData('cache', 'playlistSongs$playlistid', playlistSongs);
  }

  return playlistSongs;
}

Future<void> setActivePlaylist(Map info) async {
  final plist = info['list'] as List;
  activePlaylist = info;
  if (plist is List<SongModel>) {
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

Future<dynamic> getSong(dynamic songId) async {
  final manifest = await yt.videos.streamsClient.getManifest(songId);
  return manifest.audioOnly.withHighestBitrate().url.toString();
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
