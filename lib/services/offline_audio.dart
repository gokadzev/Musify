import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:musify/models/custom_audio_model.dart';
import 'package:musify/services/data_manager.dart';
import 'package:on_audio_query/on_audio_query.dart' hide context;

final OnAudioQuery audioQuery = OnAudioQuery();

AudioSortType _sortBy = AudioSortType.DATE_ADDED;

final List cachedAudioArtworkPaths =
    Hive.box('cache').get('cachedAudioArtworks', defaultValue: []);
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
    if (imageBytes != null && !(await imageFile.exists())) {
      unawaited(imageFile.writeAsBytes(imageBytes.toList()));
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

  if (_cachedSongsWithArtwork?.length == allSongs.length) {
    final filteredCachedSongs =
        _filterSongs(_cachedSongsWithArtwork!, searchQuery);
    return filteredCachedSongs;
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
  addOrUpdateData('cache', 'cachedAudioArtworks', cachedAudioArtworkPaths);

  if (searchQuery != null) {
    final filteredSongs = _filterSongs(songsWithArtwork, searchQuery);
    return filteredSongs;
  } else {
    return songsWithArtwork;
  }
}

List<AudioModelWithArtwork> _filterSongs(
  List<AudioModelWithArtwork> songs,
  String? searchQuery,
) {
  final lowerCaseSearchQuery = searchQuery?.toLowerCase();

  if (lowerCaseSearchQuery != null && lowerCaseSearchQuery.isNotEmpty) {
    return songs
        .where(
          (song) =>
              song.displayName.toLowerCase().contains(lowerCaseSearchQuery),
        )
        .toList();
  } else {
    return songs;
  }
}

Future<List<ArtistModel>> getRandomArtists() async {
  final _artists = await audioQuery.queryArtists();
  final randomArtists = _artists.toList()..shuffle();
  return randomArtists.take(10).toList();
}
