import 'dart:convert';

import 'package:musify/services/audio_manager.dart';
import 'package:http/http.dart' as http;

List searchedList = [];
List top50songs = [];
List playlists = [];
String? kUrl = "", image = "", title = "", album = "", artist = "", lyrics;

Future<List> fetchSongsList(searchQuery) async {
  String searchUrl =
      "https://musap.vv2021.repl.co/get_data?act=search&q=" + searchQuery;
  var res = await http
      .get(Uri.parse(searchUrl), headers: {"Accept": "application/json"});
  var getMain = json.decode(res.body);

  searchedList = getMain["songs"]["data"];
  for (int i = 0; i < searchedList.length; i++) {
    searchedList[i]['title'] = searchedList[i]['title']
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");

    searchedList[i]['more_info']['singers'] = searchedList[i]['more_info']
            ['singers']
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");
  }
  return searchedList;
}

Future<List> getTop50() async {
  String topSongsUrl = "https://musap.vv2021.repl.co/get_data?act=global_fifty";
  var songsListJSON = await http
      .get(Uri.parse(topSongsUrl), headers: {"Accept": "application/json"});
  var songsList = json.decode(songsListJSON.body);
  top50songs = songsList["list"];
  var songsNumber = 10;
  for (int i = 0; i < songsNumber; i++) {
    top50songs[i]['title'] = top50songs[i]['title']
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");
    top50songs[i]["more_info"]["singers"] = top50songs[i]["more_info"]
            ["singers"]
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");
    top50songs[i]['image'] = top50songs[i]['image'].toString();
  }

  return top50songs;
}

Future<List> getPlaylists() async {
  String playlistsURL =
      "https://musap.vv2021.repl.co/get_data?act=playlists_data";
  var playlistsJSON = await http
      .get(Uri.parse(playlistsURL), headers: {"Accept": "application/json"});
  playlists = json.decode(playlistsJSON.body);

  return playlists;
}

Future getPlaylistInfoForWidget(int id) async {
  String playlistURL =
      "https://musap.vv2021.repl.co/get_data?act=playlist_data&id=" +
          id.toString();
  var playlistJSON = await http
      .get(Uri.parse(playlistURL), headers: {"Accept": "application/json"});
  var playlist = json.decode(playlistJSON.body);

  return playlist;
}

Future setSongDetails(song) async {
  title = song["title"];
  image = song["image"];
  album = song["album"] == null ? '' : song["album"];

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

  kUrl = song["more_info"]["vlink"];
  kUrlNotifier.value = song["more_info"]["vlink"];
}
