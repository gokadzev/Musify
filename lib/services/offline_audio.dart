import 'dart:io';

import 'package:musify/models/custom_audio_model.dart';
import 'package:on_audio_query/on_audio_query.dart' hide context;

final OnAudioQuery audioQuery = OnAudioQuery();

AudioSortType _sortBy = AudioSortType.DATE_ADDED;

final List<String> cachedAudioArtworkPaths = [];
int _lastKnownSongCount = 0;
List<AudioModelWithArtwork>? _cachedSongsWithArtwork;

void upadateSortType(AudioSortType sort) => _sortBy = sort;

class SupportDirectoryManager {
  static String? _appSupportFolder;

  static Future<String> getAppSupportFolder() async {
    _appSupportFolder ??= (await getApplicationSupportDirectory()).path;
    return _appSupportFolder!;
  }
}

Future<String> saveArtworkImageToSupportDirectory(int songId) async {
  final imagePath =
      '${await SupportDirectoryManager.getAppSupportFolder()}/${songId}_cached_image.jpg';

  if (!cachedAudioArtworkPaths.contains(imagePath)) {
    final imageFile = File(imagePath);
    final _artwork = await audioQuery.queryArtwork(
      songId,
      ArtworkType.AUDIO,
      filter: MediaFilter.forArtwork(artworkQuality: 100, artworkSize: 350),
    );

    final imageBytes = _artwork?.artwork;
    if (!await imageFile.exists() && imageBytes != null) {
      await imageFile.writeAsBytes(imageBytes.toList());
    }
    cachedAudioArtworkPaths.add(imagePath);
  }

  return imagePath;
}

Future<List<AudioModelWithArtwork>> getMusic({
  String? searchQuery,
  AudioSortType? sortBy,
}) async {
  final allSongs = await audioQuery.querySongs(
    filter: MediaFilter.forSongs(audioSortType: sortBy ?? _sortBy),
  );

  if (_lastKnownSongCount != allSongs.length) {
    _lastKnownSongCount = allSongs.length;
    _cachedSongsWithArtwork = null;
  }

  if (_cachedSongsWithArtwork != null) {
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return _cachedSongsWithArtwork!
          .where(
            (song) => song.displayName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()),
          )
          .toList();
    } else {
      return _cachedSongsWithArtwork!;
    }
  }

  final songsWithArtwork = <AudioModelWithArtwork>[];

  for (final song in allSongs) {
    final _artworkPath = await saveArtworkImageToSupportDirectory(song.id);

    songsWithArtwork.add(
      AudioModelWithArtwork(
        info: song.getMap,
        albumArtwork: _artworkPath,
      ),
    );
  }

  _cachedSongsWithArtwork = songsWithArtwork;

  if (searchQuery != null && searchQuery.isNotEmpty) {
    return songsWithArtwork
        .where(
          (song) => song.displayName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()),
        )
        .toList();
  } else {
    return songsWithArtwork.toList();
  }
}

Future<List<ArtistModel>> getRandomArtists() async {
  final _artists = await audioQuery.queryArtists();
  final randomArtists = _artists.toList()..shuffle();
  return randomArtists.take(10).toList();
}
