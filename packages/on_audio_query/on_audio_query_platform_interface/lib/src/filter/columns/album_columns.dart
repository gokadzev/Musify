// ignore_for_file: non_constant_identifier_names

part of columns_controller;

/// All album columns used with [MediaFilter].
class AlbumColumns {
  /// The album [ID].
  int get ID => 0;

  /// The album [NAME].
  int get ALBUM => 1;

  /// The album [ARTIST].
  int get ARTIST => 2;

  /// The album [IARTIST_IDD].
  int get ARTIST_ID => 3;

  /// The album [FIRST_YEAR].
  int get FIRST_YEAR => 4;

  /// The album [LAST_YEAR].
  int get LAST_YEAR => 5;

  /// The album [NUMBER_OF_SONGS].
  int get NUMBER_OF_SONGS => 6;

  /// The album [NUMBER_OF_SONGS_FOR_ARTIST].
  int get NUMBER_OF_SONGS_FOR_ARTIST => 7;
}
