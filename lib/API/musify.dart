import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

List searchedList = [];
List topSongsList = [];
String? kUrl = "",
    checker,
    image = "",
    title = "",
    album = "",
    artist = "",
    lyrics,
    rawkUrl;
String key = "38346591";
String decrypt = "";

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

Future<List> topSongs() async {
  String topSongsUrl =
      "https://musap.vv2021.repl.co/get_data?act=playlist_data";
  var songsListJSON = await http
      .get(Uri.parse(topSongsUrl), headers: {"Accept": "application/json"});
  var songsList = json.decode(songsListJSON.body);
  topSongsList = songsList[0]["list"];
  var songsNumber = 10;
  for (int i = 0; i < songsNumber; i++) {
    topSongsList[i]['title'] = topSongsList[i]['title']
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");
    topSongsList[i]["more_info"]["singers"] = topSongsList[i]["more_info"]
            ["singers"]
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"");
    topSongsList[i]['image'] = topSongsList[i]['image'].toString();
  }
  return topSongsList;
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
  if (getMain['songs']['data'][0]["more_info"]["has_lyrics"] == "true") {
    String lyricsUrl =
        "https://www.jiosaavn.com/api.php?__call=lyrics.getLyrics&lyrics_id=" +
            songId +
            "&ctx=web6dot0&api_version=4&_format=json";
    var lyricsRes = await http
        .get(Uri.parse(lyricsUrl), headers: {"Accept": "application/json"});
    var lyricsEdited = (lyricsRes.body).split("-->");
    var fetchedLyrics = json.decode(lyricsEdited[1]);
    lyrics = fetchedLyrics["lyrics"].toString().replaceAll("<br>", "\n");
  } else {
    lyrics = "null";
    String lyricsApiUrl =
        "https://musifydev.vercel.app/lyrics/" + artist! + "/" + title!;
    var lyricsApiRes = await http
        .get(Uri.parse(lyricsApiUrl), headers: {"Accept": "application/json"});
    var lyricsResponse = json.decode(lyricsApiRes.body);
    if (lyricsResponse['status'] == true && lyricsResponse['lyrics'] != null) {
      lyrics = lyricsResponse['lyrics'];
    }
  }

  kUrl = getMain["songs"]["data"][0]["more_info"]["vlink"];

  rawkUrl = kUrl;
  artist = (getMain["songs"]["data"][0]["more_info"]["singers"])
      .toString()
      .replaceAll("&quot;", "\"")
      .replaceAll("&#039;", "'")
      .replaceAll("&amp;", "&");
  debugPrint(kUrl);
}
