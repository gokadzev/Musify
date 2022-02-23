// import 'dart:convert';

import 'package:musify/services/audio_manager.dart';
// import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

var yt = YoutubeExplode();

List ytplaylists = ["PLmQPPVKNGMHipaJbw0lHPuGPuKQDJkcdn"];
List searchedList = [];
List top50songs = [];
List playlists = [
  {
    "id": "top50",
    "title": "Top 50 Global",
    "subtitle": "Just Updated",
    "header_desc": "Top 50 Global Song.",
    "type": "playlist",
    "image":
        "https://charts-images.scdn.co/assets/locale_en/regional/daily/region_global_large.jpg",
    "list": []
  }
];

String? kUrl = "",
    image = "",
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

Future<List> getTop50() async {
  if (top50songs.length == 0) {
    var index = 0;
    await for (var video
        in yt.playlists.getVideos('PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx')) {
      top50songs.add({
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
        "album": "",
        "type": "song",
        "more_info": {
          "primary_artists": video.title.split('-')[0],
          "singers": video.title.split('-')[0],
        }
      });
      index += 1;
    }
  }
  return top50songs;
}

Future<List<dynamic>> getPlaylists() async {
  if (playlists.length == 1) {
    var index = 0;
    ytplaylists.forEach((playlistID) async {
      var plist = await yt.playlists.get(playlistID);
      playlists.add({
        "id": index,
        "ytid": plist.id,
        "title": plist.title,
        "subtitle": "Just Updated",
        "header_desc": plist.description,
        "type": "playlist",
        "image": "",
        "list": []
      });
      index += 1;
    });
  }

  return playlists;
}

Future getSongsFromPlaylist(playlistid) async {
  var index = 0;
  var playlistSongs = [];
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
  var playlist;
  if (id == "top50") {
    playlist = playlists[0];
    playlist["list"] = await getTop50();
  } else {
    playlist = playlists
        .where((list) => list["id"] is int && list["id"] == id)
        .toList()[0];
  }

  if (playlist["list"].length == 0) {
    playlist["list"] = await getSongsFromPlaylist(playlist["ytid"]);
  }

  return playlist;
}

Future setSongDetails(song) async {
  id = song["id"];
  title = song["title"];
  image = song["image"];
  album = song["album"] == null ? '' : song["album"];
  ytid = song["ytid"].toString();

  try {
    artist = song['more_info']['singers'];
  } catch (e) {
    artist = "-";
  }

  lyrics = "null";
  // service is temporary unavailable
  // String lyricsApiUrl = "https://api.lyrics.ovh/v1/" + artist! + "/" + title!;
  // var lyricsApiRes = await http
  //     .get(Uri.parse(lyricsApiUrl), headers: {"Accept": "application/json"});
  // var lyricsResponse = json.decode(lyricsApiRes.body);
  // if (lyricsResponse['lyrics'] != null) {
  //   lyrics = lyricsResponse['lyrics'];
  // }

  var manifest = await yt.videos.streamsClient.getManifest(ytid!);
  final List<AudioOnlyStreamInfo> sortedStreamInfo =
      manifest.audioOnly.sortByBitrate();
  var audio = sortedStreamInfo.first.url.toString();
  audioPlayer?.setUrl(audio);
  kUrl = audio;
  kUrlNotifier.value = audio;
}
