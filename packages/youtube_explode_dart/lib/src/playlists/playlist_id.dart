import 'package:freezed_annotation/freezed_annotation.dart';

import '../extensions/helpers_extension.dart';

part 'playlist_id.freezed.dart';

/// Encapsulates a valid YouTube playlist ID.
@freezed
abstract class PlaylistId with _$PlaylistId {
  static final _regMatchExp =
      RegExp(r'youtube\..+?/playlist.*?list=(.*?)(?:&|/|$)');
  static final _compositeMatchExp =
      RegExp(r'youtube\..+?/watch.*?list=(.*?)(?:&|/|$)');
  static final _shortCompositeMatchExp =
      RegExp(r'youtu\.be/.*?/.*?list=(.*?)(?:&|/|$)');
  static final _embedCompositeMatchExp =
      RegExp(r'youtube\..+?/embed/.*?/.*?list=(.*?)(?:&|/|$)');

  /// Initializes an instance of [PlaylistId]
  factory PlaylistId(String idOrUrl) {
    final id = parsePlaylistId(idOrUrl);
    if (id == null) {
      throw ArgumentError.value(idOrUrl, 'idOrUrl', 'Invalid url');
    }
    return PlaylistId._internal(id);
  }

  const PlaylistId._();

  const factory PlaylistId._internal(
    /// The playlist id as string.
    String value,
  ) = _PlaylistId;

  ///  Converts [obj] to a [PlaylistId] by calling .toString on that object.
  /// If it is already a [PlaylistId], [obj] is returned
  factory PlaylistId.fromString(dynamic obj) {
    if (obj is PlaylistId) {
      return obj;
    }
    return PlaylistId(obj.toString());
  }

  /// Returns true if the given [playlistId] is valid.
  static bool validatePlaylistId(String playlistId) {
    playlistId = playlistId.toUpperCase();

    if (playlistId.isNullOrWhiteSpace) {
      return false;
    }

    // Watch later
    if (playlistId == 'WL') {
      return true;
    }

    // My mix playlist
    if (playlistId == 'RDMM') {
      return true;
    }

    // Playlist IDs vary greatly in length, but they are at least 2 characters long
    if (playlistId.length < 2) {
      return false;
    }

    return !RegExp(r'[^0-9a-zA-Z_\-]').hasMatch(playlistId);
  }

  /// Parses a playlist [url] returning its id.
  /// If the [url] is a valid it is returned itself.
  static String? parsePlaylistId(String url) {
    if (url.isNullOrWhiteSpace) {
      return null;
    }

    if (validatePlaylistId(url)) {
      return url;
    }

    final regMatch = _regMatchExp.firstMatch(url)?.group(1);
    if (!regMatch.isNullOrWhiteSpace && validatePlaylistId(regMatch!)) {
      return regMatch;
    }

    final compositeMatch = _compositeMatchExp.firstMatch(url)?.group(1);
    if (!compositeMatch.isNullOrWhiteSpace &&
        validatePlaylistId(compositeMatch!)) {
      return compositeMatch;
    }

    final shortCompositeMatch =
        _shortCompositeMatchExp.firstMatch(url)?.group(1);
    if (!shortCompositeMatch.isNullOrWhiteSpace &&
        validatePlaylistId(shortCompositeMatch!)) {
      return shortCompositeMatch;
    }

    final embedCompositeMatch =
        _embedCompositeMatchExp.firstMatch(url)?.group(1);
    if (!embedCompositeMatch.isNullOrWhiteSpace &&
        validatePlaylistId(embedCompositeMatch!)) {
      return embedCompositeMatch;
    }
    return null;
  }

  @override
  String toString() => value;
}
