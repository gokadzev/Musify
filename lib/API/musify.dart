import 'dart:convert';

import 'package:musify/services/audio_manager.dart';
import 'package:flutter/material.dart';
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

Future fetchSongDetails(songId) async {
  String songUrl = "https://musap.vv2021.repl.co/get_data?act=search&id=" +
      songId.toString();
  var res = await http
      .get(Uri.parse(songUrl), headers: {"Accept": "application/json"});
  var getMain = json.decode(res.body);

  title = (getMain["songs"]["data"][0]["title"])
      .split("(")[0]
      .replaceAll("&amp;", "&")
      .replaceAll("&#039;", "'")
      .replaceAll("&quot;", "\"");
  image = (getMain["songs"]["data"][0]["image"]);
  album = (getMain["songs"]["data"][0]["album"])
      .replaceAll("&quot;", "\"")
      .replaceAll("&#039;", "'")
      .replaceAll("&amp;", "&");
  try {
    artist = getMain['songs']['data'][0]['more_info']['singers'];
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

  kUrl = getMain["songs"]["data"][0]["more_info"]["vlink"];
  kUrlNotifier.value = getMain["songs"]["data"][0]["more_info"]["vlink"];

  artist = (getMain["songs"]["data"][0]["more_info"]["singers"])
      .toString()
      .replaceAll("&quot;", "\"")
      .replaceAll("&#039;", "'")
      .replaceAll("&amp;", "&");
  debugPrint(kUrl);
}
