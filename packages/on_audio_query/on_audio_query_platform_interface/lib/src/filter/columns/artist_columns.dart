// ignore_for_file: non_constant_identifier_names

part of columns_controller;

/// All artist columns used with [MediaFilter].
class ArtistColumns {
  /// The artist [ID].
  int get ID => 0;

  /// The artist [NAME].
  int get ARTIST => 1;

  /// The artist [NUMBER_OF_ALBUMS].
  int get NUMBER_OF_ALBUMS => 2;

  /// The artist [NUMBER_OF_TRACKS].
  int get NUMBER_OF_TRACKS => 3;
}
