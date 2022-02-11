import 'dart:convert';

import 'package:musify/services/audio_manager.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

var yt = YoutubeExplode();

List searchedList = [];
List top50songs = [];
List playlists = [
  {
    "id": "top50",
    "title": "Top 50 Global",
    "subtitle": "Just Updated",
    "header_desc": "Top 50 Global Song.",
    "type": "playlist",
    "perma_url": "",
    "image":
        "https://charts-images.scdn.co/assets/locale_en/regional/daily/region_global_large.jpg",
    "language": "",
    "year": "",
    "play_count": "",
    "explicit_content": 0,
    "list_count": 30,
    "list_type": "",
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
              .replaceAll("(Official Video)", ""),
          "image": v.thumbnails.highResUrl,
          "album": "",
          "type": "song",
          "description": "",
          "ctr": 943,
          "position": 1,
          "more_info": {
            "vcode": "6010910441258415",
            "primary_artists": v.title.split('-')[0],
            "singers": v.title.split('-')[0],
            "video_available": "null",
            "triller_available": "false",
            "language": "English"
          }
        })
      });
  return searchedList;
}

Future<List> getTop50() async {
  top50songs = [];
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
          .replaceAll("(Official Video)", ""),
      "image": video.thumbnails.highResUrl,
      "album": "",
      "type": "song",
      "description": "",
      "ctr": 943,
      "position": 1,
      "more_info": {
        "vcode": "6010910441258415",
        "primary_artists": video.title.split('-')[0],
        "singers": video.title.split('-')[0],
        "video_available": "null",
        "triller_available": "false",
        "language": "English"
      }
    });
    index += 1;
  }
  return top50songs;
}

Future<List<dynamic>> getPlaylists() async {
  return playlists;
}

Future getPlaylistInfoForWidget(dynamic id) async {
  var playlist;
  if (id == "top50") {
    playlist = playlists[0];
    playlist["list"] = await getTop50();
  }

  return playlist;
}

Future setSongDetails(song) async {
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
  String lyricsApiUrl = "https://api.lyrics.ovh/v1/" + artist! + "/" + title!;
  var lyricsApiRes = await http
      .get(Uri.parse(lyricsApiUrl), headers: {"Accept": "application/json"});
  var lyricsResponse = json.decode(lyricsApiRes.body);
  if (lyricsResponse['lyrics'] != null) {
    lyrics = lyricsResponse['lyrics'];
  }

  var manifest = await yt.videos.streamsClient.getManifest(ytid!);
  final List<AudioOnlyStreamInfo> sortedStreamInfo =
      manifest.audioOnly.sortByBitrate();
  var audio = sortedStreamInfo.first.url.toString();

  kUrl = audio;
  kUrlNotifier.value = audio;
}
