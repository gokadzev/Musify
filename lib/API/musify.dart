import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:musify/helper/formatter.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/data_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

var yt = YoutubeExplode();

List ytplaylists = [];

List searchedList = [];
List playlists = [];
List userPlaylists = [];
List userLikedSongsList = [];
List suggestedPlaylists = [];

String? kUrl = "",
    image = "",
    highResImage = "",
    title = "",
    album = "",
    artist = "",
    ytid = "",
    lyrics;

dynamic activeSong;

int? id = 0;

List activePlaylist = [];

Future<List> fetchSongsList(searchQuery) async {
  var s = yt.search.search(searchQuery);
  List list = await s;
  searchedList = [];
  for (var v in list) {
    searchedList.add(returnSongLayout(
        0,
        v.id.toString(),
        formatSongTitle(v.title.split('-')[v.title.split('-').length - 1]),
        v.thumbnails.standardResUrl,
        v.thumbnails.maxResUrl,
        v.title.split('-')[0]));
  }
  return searchedList;
}

Future get10Music(playlistId) async {
  var newSongs = [];
  var index = 0;
  await for (var video in yt.playlists.getVideos(playlistId).take(10)) {
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
    final plist = await yt.playlists.get(playlistID);
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

addUserLikedSong(songId) async {
  userLikedSongsList
      .add(await getSongDetails(userLikedSongsList.length, songId));
  addOrUpdateData("user", "likedSongs", userLikedSongsList);
}

removeUserLikedSong(songId) {
  userLikedSongsList.removeWhere((song) => song["ytid"] == songId);
  addOrUpdateData("user", "likedSongs", userLikedSongsList);
}

bool isSongAlreadyLiked(songId) {
  return userLikedSongsList.where((song) => song["ytid"] == songId).isNotEmpty;
}

Future<List> getPlaylists([int? playlistsNum]) async {
  if (playlists.isEmpty) {
    var localplaylists =
        json.decode(await rootBundle.loadString('assets/db/playlists.db.json'));
    playlists = localplaylists;
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

  if (searchPlaylist.isEmpty) {
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
  activeSong = song;

  try {
    artist = song['more_info']['singers'];
  } catch (e) {
    artist = "-";
  }

  lyrics = "null";

  final audio = await getSongUrl(ytid);
  audioPlayer?.setUrl(audio);
  kUrl = audio;
  kUrlNotifier.value = audio;
}

Future getSongUrl(songId) async {
  final manifest = await yt.videos.streamsClient.getManifest(songId);
  return manifest.audioOnly.withHighestBitrate().url.toString();
}

Future getSongStream(songId) async {
  final manifest = await yt.videos.streamsClient.getManifest(songId);
  return manifest.audioOnly.withHighestBitrate();
}

Future getSongDetails(songIndex, songId) async {
  final song = await yt.videos.get(songId);
  return returnSongLayout(
      songIndex,
      song.id.toString(),
      formatSongTitle(song.title.split('-')[song.title.split('-').length - 1]),
      song.thumbnails.standardResUrl,
      song.thumbnails.maxResUrl,
      song.title.split('-')[0]);
}

Future getSongLyrics() async {
  final String lyricsApiUrl =
      'https://api.lyrics.ovh/v1/${artist!}/${title!.split(" (")[0].split("|")[0].trim()}';
  try {
    final lyricsApiRes = await DefaultCacheManager().getSingleFile(lyricsApiUrl,
        headers: {
          "Accept": "application/json"
        }).timeout(const Duration(seconds: 5));
    final lyricsResponse = await json.decode(await lyricsApiRes.readAsString());
    if (lyricsResponse['lyrics'] != null) {
      lyrics = lyricsResponse['lyrics'];
    }
  } catch (e) {}
}
