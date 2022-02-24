import 'dart:convert';

import 'package:musify/services/audio_manager.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

var yt = YoutubeExplode();

List ytplaylists = [
  "PLmQPPVKNGMHipaJbw0lHPuGPuKQDJkcdn",
  "PLPZdY4vhqvRAKdgI75eWn5XM0gPqs3QMY",
  "PLSR9lWowvoE3A9i4JVVHtQFjlJt0_LItG",
  "PLwztIBLgL4YCJ50tpYJaDZ6Z9aECNuJYe",
  "PLgzTt0k8mXzHcKebL8d0uYHfawiARhQja"
];
List searchedList = [];
List playlists = [];

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
  var s = yt.search.getVideos(searchQuery);
  List list = await s;
  searchedList = [];
  list.forEach((v) => {
        searchedList.add({
          "id": 0,
          "ytid": v.id,
          "title": v.title
              .split('-')[v.title.split('-').length - 1]
              .replaceAll("&amp;", "&")
              .replaceAll("&#039;", "'")
              .replaceAll("&quot;", "\"")
              .replaceAll("[Official Video]", "")
              .replaceAll("(Official Video)", "")
              .replaceAll("(Official Music Video)", ""),
          "image": v.thumbnails.highResUrl,
          "album": "",
          "type": "song",
          "more_info": {
            "primary_artists": v.title.split('-')[0],
            "singers": v.title.split('-')[0],
          }
        })
      });
  return searchedList;
}

Future get7Music(playlistId) async {
  var newSongs = [];
  var index = 0;
  await for (var video in yt.playlists.getVideos(playlistId).take(7)) {
    newSongs.add({
      "id": index,
      "ytid": video.id,
      "title": video.title
          .split('-')[video.title.split('-').length - 1]
          .replaceAll("&amp;", "&")
          .replaceAll("&#039;", "'")
          .replaceAll("&quot;", "\"")
          .replaceAll("[Official Video]", "")
          .replaceAll("(Official Video)", "")
          .replaceAll("(Official Music Video)", ""),
      "image": video.thumbnails.standardResUrl,
      "highResImage": video.thumbnails.maxResUrl,
      "album": "",
      "type": "song",
      "more_info": {
        "primary_artists": video.title.split('-')[0],
        "singers": video.title.split('-')[0],
      }
    });
    index += 1;
  }

  return newSongs;
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
    playlistSongs.add({
      "id": index,
      "ytid": video.id,
      "title": video.title
          .split('-')[video.title.split('-').length - 1]
          .replaceAll("&amp;", "&")
          .replaceAll("&#039;", "'")
          .replaceAll("&quot;", "\"")
          .replaceAll("[Official Video]", "")
          .replaceAll("(Official Video)", "")
          .replaceAll("(Official Music Video)", ""),
      "image": video.thumbnails.standardResUrl,
      "highResImage": video.thumbnails.maxResUrl,
      "album": "",
      "type": "song",
      "more_info": {
        "primary_artists": video.title.split('-')[0],
        "singers": video.title.split('-')[0],
      }
    });
    index += 1;
  }

  return playlistSongs;
}

setActivePlaylist(playlist) async {
  activePlaylist = playlist;
  id = 0;
  setSongDetails(activePlaylist[id!]);
}

Future getPlaylistInfoForWidget(dynamic id) async {
  var playlist = playlists.where((list) => list["ytid"] == id).toList()[0];

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
  String lyricsApiUrl = "https://api.lyrics.ovh/v1/" + artist! + "/" + title!;
  var lyricsApiRes = await http
      .get(Uri.parse(lyricsApiUrl), headers: {"Accept": "application/json"});
  var lyricsResponse;
  if (lyricsApiRes.statusCode > 200 ||
      lyricsApiRes.statusCode <= 400 ||
      // ignore: unnecessary_null_comparison
      lyricsApiRes.body != null) {
    lyricsResponse = await json.decode(lyricsApiRes.body);
    if (lyricsResponse['lyrics'] != null) {
      lyrics = lyricsResponse['lyrics'];
    }
  }
}
