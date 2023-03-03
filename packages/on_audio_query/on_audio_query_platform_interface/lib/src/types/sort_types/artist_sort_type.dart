// ignore_for_file: constant_identifier_names

part of sorts_controller;

/// Defines the sort type used for [queryArtists].
enum ArtistSortType {
  ///[ARTIST] will return song list based in [artists] names.
  ARTIST,

  ///[NUM_OF_TRACKS] will return song list based in artists [number_of_tracks].
  NUM_OF_TRACKS,

  ///[NUM_OF_ALBUMS] will return song list based in artists [number_of_albums].
  NUM_OF_ALBUMS,
}
