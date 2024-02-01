// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'package:musify/DB/albums.db.dart';
import 'package:musify/DB/playlists.db.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final _yt = YoutubeExplode();
List playlists = [...playlistsDB, ...albumsDB];

void main() async {
  print('PLAYLISTS AND ALBUMS CHECKING RESULT:');
  print('      ');

  for (final playlist in playlists) {
    try {
      final plist = await _yt.playlists.get(playlist['ytid']);

      if (plist.videoCount == null) {
        if (playlist['isAlbum'] != null && playlist['isAlbum']) {
          print('> The album with the ID ${playlist['ytid']} does not exist.');
        } else {
          print(
            '> The playlist with the ID ${playlist['ytid']} does not exist.',
          );
        }
      }

      final imageAvailability = await isImageAvailable(playlist['image']);
      if (!imageAvailability) {
        if (playlist['isAlbum'] != null && playlist['isAlbum']) {
          print(
            '> The album artwork with the URL ${playlist['image']} is not available.',
          );
        } else {
          print(
            '> The playlist artwork with the URL ${playlist['image']} is not available.',
          );
        }
      }
    } catch (e) {
      print(
        'An error occurred while checking playlist ${playlist['title']}: $e',
      );
    }
  }

  print('      ');
  print('The checking process is done');
}

Future<bool> isImageAvailable(String url) async {
  try {
    final response = await http.head(Uri.parse(url));
    return response.statusCode == 200;
  } catch (e) {
    print('Something went wrong in isImageAvailable for the url: $url');
    return false;
  }
}
