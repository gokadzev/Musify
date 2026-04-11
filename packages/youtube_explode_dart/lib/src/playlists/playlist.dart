import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/common.dart';
import 'playlist_id.dart';

part 'playlist.freezed.dart';

/// YouTube playlist metadata.
@freezed
abstract class Playlist with _$Playlist {
  /// Initializes an instance of [Playlist].
  const factory Playlist(
    /// Playlist ID.
    PlaylistId id,

    /// Playlist title.
    String title,

    /// Playlist author.
    /// Can be null if it's a system playlist (e.g. Video Mix, Topics, etc.).
    String author,

    /// Playlist description.
    String description,

    /// Available thumbnails for this playlist.
    /// Can be null if the playlist is empty.
    ThumbnailSet thumbnails,

    /// Engagement statistics.
    Engagement engagement,

    /// Total videos in this playlist.
    int? videoCount,
  ) = _Playlist;

  const Playlist._();

  /// Playlist URL.
  String get url => 'https://www.youtube.com/playlist?list=$id';
}
