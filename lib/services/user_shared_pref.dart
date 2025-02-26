import 'dart:convert';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSharedPrefs {
  Future<void> setAllSongs(bool u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allSongs', u);
  }

  Future<bool?> getAllSongs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('allSongs') ?? false;
  }

  Future<void> setDeviceSongs(List<SongModel> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final songStrings = songs.map((song) => jsonEncode(song.getMap)).toList();
    await prefs.setStringList('songs', songStrings);
  }

  Future<List<SongModel>> getDeviceSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final songStrings = prefs.getStringList('songs');
    if (songStrings == null) return [];
    return songStrings.map((song) => SongModel(jsonDecode(song))).toList();
  }
}
