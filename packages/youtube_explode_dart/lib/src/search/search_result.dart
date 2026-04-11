import 'package:freezed_annotation/freezed_annotation.dart';

import '../channels/channel_id.dart';
import '../common/common.dart';
import '../playlists/playlist_id.dart';
import '../videos/video_id.dart';

part 'search_result.freezed.dart';

@Deprecated('Use SearchResult instead.')
typedef BaseSearchContent = SearchResult;

@freezed
abstract class SearchResult with _$SearchResult {
  const SearchResult._();

  /// Metadata related to a search query result (video).
  const factory SearchResult.video(
    /// Video ID.
    VideoId id,

    /// Video title.
    String title,

    /// Video author.
    String author,

    /// Video description snippet. (Part of the full description if too long)
    String description,

    /// Video duration as String, HH:MM:SS
    String duration,

    /// Video View Count
    int viewCount,

    /// Video thumbnail
    List<Thumbnail> thumbnails,

    /// Video upload date - As string: 5 years ago.
    String? uploadDate,

    /// True if this video is a live stream.
    bool isLive,

    /// Channel id
    String channelId,
  ) = SearchVideo;

  /// Metadata related to a search query result (playlist)
  const factory SearchResult.playlist(
    /// PlaylistId.
    PlaylistId id,

    /// Playlist title.
    String title,

    /// Playlist video count, cannot be greater than 50.
    int videoCount,

    /// Video thumbnail
    List<Thumbnail> thumbnails,
  ) = SearchPlaylist;

  /// Metadata related to a search query result (channel)
  const factory SearchResult.channel(
    /// Channel id.
    ChannelId id,

    /// Channel name.
    String name,

    /// Description snippet.
    /// Can be empty.
    String description,

    /// Channel uploaded videos.
    int videoCount,

    /// Channel thumbnails.
    List<Thumbnail> thumbnails,
  ) = SearchChannel;
}

@Deprecated('Use SearchPlaylist')
extension PlaylistIdExt on SearchPlaylist {
  @Deprecated('Use SearchPlaylist.id')
  PlaylistId get playlistId => id;

  @Deprecated('Use SearchPlaylist.playlistTile')
  String get playlistTile => title;

  @Deprecated('Use SearchPlaylist.videoCount')
  int get playlistVideoCount => videoCount;
}
