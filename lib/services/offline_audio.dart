import 'package:flutter/material.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:on_audio_query/on_audio_query.dart';

final OnAudioQuery _audioQuery = OnAudioQuery();

Future<List<SongModel>> getDownloadedSongs() async {
  try {
    final downloadedSongs = await _audioQuery.querySongs(
      path: downloadDirectory,
    );
    return downloadedSongs;
  } catch (e, stack) {
    debugPrint('$e $stack');
    return [];
  }
}

Future<List<SongModel>> getLocalMusic({searchQuery}) async {
  final allSongs = <SongModel>[
    for (final p in localSongsFolders) ...await _audioQuery.querySongs(path: p)
  ];
  if (searchQuery != null) {
    return allSongs
        .where(
          (song) =>
              song.isAlarm == false &&
              song.isNotification == false &&
              song.isRingtone == false &&
              song.displayName
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()),
        )
        .toList();
  } else {
    return allSongs
        .where(
          (song) =>
              song.isAlarm == false &&
              song.isNotification == false &&
              song.isRingtone == false,
        )
        .toList();
  }
}

Future<List<ArtistModel>> getArtists() async {
  final _artists = await _audioQuery.queryArtists();
  return _artists;
}
