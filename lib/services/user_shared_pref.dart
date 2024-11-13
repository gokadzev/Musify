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
}
