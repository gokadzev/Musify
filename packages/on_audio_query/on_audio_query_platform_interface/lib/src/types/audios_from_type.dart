// ignore_for_file: constant_identifier_names

part of types_controller;

/// Defines where audios will be acquired.
@Deprecated("Deprecated after [3.0.0]. Use one of the [query] methods instead")
enum AudiosFromType {
  /// Audios from specific Album name.
  ALBUM,

  /// Audios from specific Album id.
  ALBUM_ID,

  /// Audios from specific Artist name.
  ARTIST,

  /// Audios from specific Artist id.
  ARTIST_ID,

  /// Audios from specific Genre name.
  GENRE,

  /// Audios from specific Genre id.
  GENRE_ID,

  /// Audios from specific Playlist.
  PLAYLIST,
}
