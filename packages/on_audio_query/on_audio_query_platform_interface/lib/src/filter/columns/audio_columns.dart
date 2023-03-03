// ignore_for_file: non_constant_identifier_names

part of columns_controller;

/// All audio columns used with [MediaFilter].
// TODO: Change class to enum (Dart 1.17.*)
class AudioColumns {
  /// The audio [ID].
  int get ID => 0;

  /// The audio [DATA].
  int get DATA => 1;

  /// The audio [DISPLAY_NAME].
  int get DISPLAY_NAME => 2;

  /// The audio [ALBUM].
  int get ALBUM => 4;

  /// The audio [ALBUM_ID].
  int get ALBUM_ID => 6;

  /// The audio [ARTIST].
  int get ARTIST => 7;

  /// The audio [ARTIST_ID].
  int get ARTIST_ID => 8;

  /// The audio [GENRE].
  int get GENRE => 23;

  /// The audio [GENRE_ID].
  int get GENRE_ID => 24;

  /// The audio [COMPOSER].
  int get COMPOSER => 10;

  /// The audio [TITLE].
  int get TITLE => 14;

  /// The audio [DURATION].
  int get DURATION => 13;
}
