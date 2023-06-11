import 'package:on_audio_query/on_audio_query.dart' hide context;

final OnAudioQuery _audioQuery = OnAudioQuery();

Future<List<AudioModel>> getMusic(String? searchQuery) async {
  final allSongs = await _audioQuery.querySongs(
    filter: MediaFilter.forSongs(
      audioSortType: AudioSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      type: const {AudioType.IS_MUSIC: true},
    ),
  );

  if (searchQuery != null && searchQuery.isNotEmpty) {
    return allSongs
        .where(
          (song) => song.displayName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()),
        )
        .toList();
  } else {
    return allSongs.toList();
  }
}

Future<List<ArtistModel>> getRandomArtists() async {
  final _artists = await _audioQuery.queryArtists();
  final randomArtists = _artists.toList()..shuffle();
  return randomArtists.take(10).toList();
}
