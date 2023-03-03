// ignore_for_file: constant_identifier_names

part of types_controller;

/// Defines where artwork will be acquired.
enum ArtworkType {
  /// Artwork from Audios.
  AUDIO,

  /// Artwork from Albums.
  ALBUM,

  /// Artwork from Playlists.
  ///
  /// Important:
  ///
  /// * The artwork will be the artwork from the first audio inside the playlist.
  PLAYLIST,

  /// Artwork from Artists.
  ///
  /// Important:
  ///
  /// * There's no native support for [Artists] artwork so, we take the artwork from
  /// the first audio.
  ARTIST,

  /// Artwork from Genres.
  ///
  /// * There's no native support for [Genres] artwork so, we take the artwork from
  /// the first audio.
  GENRE,
}

/// Deprecated after [3.0.0]. Use [ArtworkFormatType] methods instead
@Deprecated('Deprecated after [3.0.0]. Use [ArtworkFormatType] methods instead')
enum ArtworkFormat {
  /// Deprecated after [3.0.0]. Use [ArtworkFormatType.JPEG] methods instead
  JPEG,

  /// Deprecated after [3.0.0]. Use [ArtworkFormatType.PNG] methods instead
  PNG,
}
