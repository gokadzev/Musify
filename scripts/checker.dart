// ignore_for_file: avoid_print

import 'package:musify/DB/albums.db.dart';
import 'package:musify/DB/playlists.db.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final _yt = YoutubeExplode();
List playlists = [...playlistsDB, ...albumsDB];

void main() async {
  print('PLAYLISTS AND ALBUMS CHECKING RESULT:');
  print('      ');
  for (final playlist in playlists) {
    final plist = await _yt.playlists.get(playlist['ytid']);

    if (plist.videoCount == null) {
      if (playlist['isAlbum'] != null && playlist['isAlbum']) {
        print('> The album with the ID ${playlist['ytid']} does not exist.');
      } else {
        print('> The playlist with the ID ${playlist['ytid']} does not exist.');
      }
    }
  }
  print('      ');
  print('The checking process is done');
}
