import 'dart:convert';

import 'package:musify/helper/formatter.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:musify/services/data_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

var yt = YoutubeExplode();

List ytplaylists = [
  "PLmQPPVKNGMHipaJbw0lHPuGPuKQDJkcdn",
  "PLPZdY4vhqvRAKdgI75eWn5XM0gPqs3QMY",
  "PLSR9lWowvoE3A9i4JVVHtQFjlJt0_LItG",
  "PLwztIBLgL4YCJ50tpYJaDZ6Z9aECNuJYe",
  "PLgzTt0k8mXzHcKebL8d0uYHfawiARhQja",
  "RDCLAK5uy_lBNUteBRencHzKelu5iDHwLF6mYqjL-JU",
  "RDCLAK5uy_kA_dvd-bpRQ98y6LwOjAnhQL5lyjNnZYA",
  "RDCLAK5uy_no33oh6TOe0vPTFGabR24wAu3NeiVvc-Q",
  "RDCLAK5uy_n0oLcyKJhNW8BmrnMySAoVuLjRZfgozG0",
  "RDCLAK5uy_lHUYsU7VTxndTCtf-ofbHDsvQWspcFBJ8",
  "RDCLAK5uy_n0TxkLvMf0yENdVCRD31Oes1XEBoJgpIU",
  "RDCLAK5uy_lrRVyinf4bGiN8dQ1jRWkVOMroYKAvnqE",
  "RDCLAK5uy_mpcC2CwnVbb6kBi_d99_FZvgG2QSi5ylo",
  "RDCLAK5uy_mnNGm2TBGoE7ciVFLrzepoNMWyreMuNlw",
  "RDCLAK5uy_mnBFITP45AFCdVtu8b7JfLFLbUZR46ObU",
  "RDCLAK5uy_k-fiP0mCE_HlLqk-h15LlxGmjTCTn4_aA",
  "RDCLAK5uy_nnZGCEPxzc5FASdbQVMufD25OfYBJlHqY"
];
List searchedList = [];
List playlists = [];
List userPlaylists = [];
List userLikedSongs = [];

String? kUrl = "",
    image = "",
    highResImage = "",
    title = "",
    album = "",
    artist = "",
    ytid = "",
    lyrics;

int? id = 0;

List activePlaylist = [];

Future<List> fetchSongsList(searchQuery) async {
  var s = yt.search.search(searchQuery);
  List list = await s;
  searchedList = [];
  list.forEach((v) => {
        searchedList.add(returnSongLayout(
            0,
            v.id.toString(),
            formatSongTitle(v.title.split('-')[v.title.split('-').length - 1]),
            v.thumbnails.standardResUrl,
            v.thumbnails.maxResUrl,
            v.title.split('-')[0]))
      });
  return searchedList;
}

Future get7Music(playlistId) async {
  var newSongs = [];
  var index = 0;
  await for (var video in yt.playlists.getVideos(playlistId).take(7)) {
    newSongs.add(returnSongLayout(
        index,
        video.id.toString(),
        formatSongTitle(
            video.title.split('-')[video.title.split('-').length - 1]),
        video.thumbnails.standardResUrl,
        video.thumbnails.maxResUrl,
        video.title.split('-')[0]));
    index += 1;
  }

  return newSongs;
}

Future<List<dynamic>> getUserPlaylists() async {
  var playlistsByUser = [];
  for (var playlistID in userPlaylists) {
    var plist = await yt.playlists.get(playlistID);
    playlistsByUser.add({
      "ytid": plist.id,
      "title": plist.title,
      "subtitle": "Just Updated",
      "header_desc": plist.description.length < 120
          ? plist.description
          : plist.description.substring(0, 120),
      "type": "playlist",
      "image": "",
      "list": []
    });
  }
  return playlistsByUser;
}

addUserPlaylist(playlistId) {
  userPlaylists.add(playlistId);
  addOrUpdateData("user", "playlists", userPlaylists);
}

removeUserPlaylist(playlistId) {
  userPlaylists.remove(playlistId.toString());
  addOrUpdateData("user", "playlists", userPlaylists);
}

Future<List<dynamic>> getUserLikedSongs() async {
  var likedSongsByUser = [];
  for (var songId in userLikedSongs) {
    print(songId);
    var song = await yt.videos.get(songId);
    likedSongsByUser.add(returnSongLayout(
        0,
        song.id.toString(),
        formatSongTitle(
            song.title.split('-')[song.title.split('-').length - 1]),
        song.thumbnails.standardResUrl,
        song.thumbnails.maxResUrl,
        song.title.split('-')[0]));
  }
  return likedSongsByUser;
}

addUserLikedSong(songId) {
  userLikedSongs.add(songId);
  addOrUpdateData("user", "likedSongs", userLikedSongs);
}

removeUserLikedSong(songId) {
  userLikedSongs.remove(songId.toString());
  addOrUpdateData("user", "likedSongs", userLikedSongs);
}

isSongAlreadyLiked(songId) {
  if (userLikedSongs.contains(songId)) {
    return true;
  } else {
    return false;
  }
}

Future<List<dynamic>> getPlaylists() async {
  var localPlaylists = [
    {
      "ytid": "PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx",
      "title": "Top 50 Global",
      "subtitle": "Just Updated",
      "header_desc": "Top 50 Global Song.",
      "type": "playlist",
      "image":
          "https://charts-images.scdn.co/assets/locale_en/regional/daily/region_global_large.jpg",
      "list": []
    }
  ];

  if (playlists.length == 0) {
    ytplaylists.forEach((playlistID) async {
      var plist = await yt.playlists.get(playlistID);
      localPlaylists.add({
        "ytid": plist.id,
        "title": plist.title,
        "subtitle": "Just Updated",
        "header_desc": plist.description.length < 120
            ? plist.description
            : plist.description.substring(0, 120),
        "type": "playlist",
        "image": "",
        "list": []
      });
    });
    playlists = localPlaylists;
  }
  return playlists;
}

Future getSongsFromPlaylist(playlistid) async {
  var playlistSongs = [];
  var index = 0;
  await for (var video in yt.playlists.getVideos(playlistid)) {
    playlistSongs.add(returnSongLayout(
        index,
        video.id.toString(),
        formatSongTitle(
            video.title.split('-')[video.title.split('-').length - 1]),
        video.thumbnails.standardResUrl,
        video.thumbnails.maxResUrl,
        video.title.split('-')[0]));
    index += 1;
  }

  return playlistSongs;
}

setActivePlaylist(playlist) async {
  activePlaylist = playlist;
  id = 0;
  setSongDetails(activePlaylist[id!]);
  play();
}

Future getPlaylistInfoForWidget(dynamic id) async {
  var searchPlaylist = playlists.where((list) => list["ytid"] == id).toList();

  if (searchPlaylist.length == 0) {
    var usPlaylists = await getUserPlaylists();
    searchPlaylist = usPlaylists.where((list) => list["ytid"] == id).toList();
  }

  var playlist = searchPlaylist[0];

  if (playlist["list"].length == 0) {
    playlist["list"] = await getSongsFromPlaylist(playlist["ytid"]);
  }

  return playlist;
}

Future setSongDetails(song) async {
  id = song["id"];
  title = song["title"];
  image = song["image"];
  highResImage = song["highResImage"];
  album = song["album"] == null ? '' : song["album"];
  ytid = song["ytid"].toString();

  try {
    artist = song['more_info']['singers'];
  } catch (e) {
    artist = "-";
  }

  lyrics = "null";

  var audio = await getSongUrl(ytid);
  audioPlayer?.setUrl(audio);
  kUrl = audio;
  kUrlNotifier.value = audio;
}

Future getSongUrl(songId) async {
  var manifest = await yt.videos.streamsClient.getManifest(songId);
  final List<AudioOnlyStreamInfo> sortedStreamInfo =
      manifest.audioOnly.sortByBitrate();
  return sortedStreamInfo.first.url.toString();
}

Future getSongLyrics() async {
  String lyricsApiUrl =
      'https://api.lyrics.ovh/v1/${artist!}/${title!.split(" (")[0].split("|")[0].trim()}';
  try {
    var lyricsApiRes = await DefaultCacheManager()
        .getSingleFile(lyricsApiUrl, headers: {"Accept": "application/json"});
    var lyricsResponse;
    lyricsResponse = await json.decode(await lyricsApiRes.readAsString());
    if (lyricsResponse['lyrics'] != null) {
      lyrics = lyricsResponse['lyrics'];
    }
  } catch (e) {}
}
