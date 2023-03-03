import 'package:on_audio_query/on_audio_query.dart' hide context;

final OnAudioQuery _audioQuery = OnAudioQuery();

Future<List<AudioModel>> getMusic({searchQuery}) async {
  final allSongs = await _audioQuery.querySongs(
    filter: MediaFilter.forSongs(
      audioSortType: AudioSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
      toQuery: const {},
      toRemove: const {},
      type: const {AudioType.IS_MUSIC: true},
    ),
  );

  if (searchQuery != null) {
    return allSongs.toList();
  } else {
    return allSongs.toList();
  }
}

Future<List<ArtistModel>> getArtists() async {
  final _artists = await _audioQuery.queryArtists();
  return _artists;
}
