import 'package:musify/models/custom_audio_model.dart';
import 'package:musify/services/download_manager.dart';
import 'package:on_audio_query/on_audio_query.dart' hide context;

final OnAudioQuery audioQuery = OnAudioQuery();

AudioSortType _sortBy = AudioSortType.DATE_ADDED;

void upadateSortType(AudioSortType sort) => _sortBy = sort;

Future<List<AudioModelWithArtwork>> getMusic({
  String? searchQuery,
  AudioSortType? sortBy,
}) async {
  final allSongs = await audioQuery.querySongs(
    filter: MediaFilter.forSongs(
      audioSortType: sortBy ?? _sortBy,
    ),
  );

  final songsWithArtwork = <AudioModelWithArtwork>[];

  for (final song in allSongs) {
    final _artwork = await audioQuery.queryArtwork(
      song.id,
      ArtworkType.AUDIO,
      filter: MediaFilter.forArtwork(artworkQuality: 100, artworkSize: 350),
    );

    final _artworkImage = _artwork?.artwork;

    final _artworkPath = _artwork != null && _artworkImage != null
        ? await saveImageToSupportDirectory(song.id, _artworkImage)
        : null;

    songsWithArtwork.add(
      AudioModelWithArtwork(
        info: song.getMap,
        albumArtwork: _artworkPath,
      ),
    );
  }

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
