import 'dart:convert';

import 'package:musify/main.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistSharingService {
  static Map createCompactPlaylist(Map fullPlaylist) {
    return {
      'title': fullPlaylist['title'],
      if (fullPlaylist['image'] != null) 'image': fullPlaylist['image'],
      'source': 'user-created',
      'list': fullPlaylist['list'].map((song) => song['ytid']).toList(),
    };
  }

  static Future<Map> expandCompactPlaylist(Map compactPlaylist) async {
    final List<dynamic> songIds = compactPlaylist['list'];
    final _yt = YoutubeExplode();
    final expandedSongs = await Future.wait(
      songIds.map((ytid) async {
        try {
          final video = await _yt.videos.get(ytid);
          return returnSongLayout(songIds.indexOf(ytid), video);
        } catch (e, stackTrace) {
          logger.log('Error expanding song: $ytid', e, stackTrace);
          return null;
        }
      }),
    );

    return {
      ...compactPlaylist,
      'list': expandedSongs.where((song) => song != null).toList(),
    };
  }

  static String encodePlaylist(Map playlist) {
    final compactPlaylist = createCompactPlaylist(playlist);
    return base64Url.encode(utf8.encode(json.encode(compactPlaylist)));
  }

  static Future<Map?> decodeAndExpandPlaylist(String encodedPlaylist) async {
    try {
      final jsonString = utf8.decode(base64Url.decode(encodedPlaylist));
      final compactPlaylist = json.decode(jsonString) as Map;
      return await expandCompactPlaylist(compactPlaylist);
    } catch (e, stackTrace) {
      logger.log('Failed to decode playlist', e, stackTrace);
      return null;
    }
  }
}
