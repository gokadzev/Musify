// ignore_for_file: constant_identifier_names

part of types_controller;

/// Defines the type of Filter.
/// Each type has a subtype, [10] in total.
///
/// If [Args] are null, will automatically select the first one, [TITLE] or [NAME]
@Deprecated("Deprecated after [3.0.0]. Use one of the [query] methods instead")
enum WithFiltersType {
  /// Filter [AUDIOS].
  ///
  /// * Contains [4] args:
  ///   * TITLE
  ///   * DISPLAY_NAME
  ///   * ALBUM
  ///   * ARTIST
  AUDIOS, //4

  /// Filter [ALBUMS].
  ///
  /// * Contains [2] args:
  ///   * ALBUM
  ///   * ARTIST
  ALBUMS, //2

  /// Filter [PLAYLISTS].
  ///
  /// * Contains [1] args:
  ///   * PLAYLIST
  PLAYLISTS, //1

  /// Filter [ARTISTS].
  ///
  /// * Contains [1] args:
  ///   * ARTIST
  ARTISTS, //1

  /// Filter [GENRES].
  ///
  /// * Contains [1] args:
  ///   * GENRE
  GENRES, //1
}

/// Args types for Audios.
enum AudiosArgs {
  /// Uses song [TITLE] as filter.
  TITLE,

  /// Uses song [DISPLAY_NAME] as filter.
  ///
  /// This arg will only work when using [Android], when using [IOS] will use
  /// [TITLE] as filter.
  DISPLAY_NAME,

  /// Uses song [ALBUM] as filter.
  ALBUM,

  /// Uses song [ARTIST] as filter.
  ARTIST,
}

/// Args types for Albums.
enum AlbumsArgs {
  /// Uses [ALBUM] as filter.
  ALBUM,

  /// Uses album [ARTIST] as filter.
  ARTIST,
}

/// Args types for Playlists.
enum PlaylistsArgs {
  /// Uses [PLAYLIST] as filter.
  PLAYLIST,
}

/// Args types for Artists.
enum ArtistsArgs {
  /// Uses [ARTIST] as filter.
  ARTIST,
}

/// Args types for Genres.
enum GenresArgs {
  /// Uses [GENRE] as filter.
  GENRE,
}
