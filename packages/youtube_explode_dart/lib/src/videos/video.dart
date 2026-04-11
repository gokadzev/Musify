import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../channels/channel_id.dart';
import '../common/common.dart';
import '../reverse_engineering/pages/watch_page.dart';
import 'video_id.dart';

part 'video.freezed.dart';

typedef MusicData = ({String? song, String? artist, String? album, Uri? image});

/// YouTube video metadata.
@freezed
abstract class Video with _$Video {
  /// Video URL.
  String get url => 'https://www.youtube.com/watch?v=$id';

  /// Returns true if the watch page is available for this video.
  bool get hasWatchPage => watchPage != null;

  factory Video(
    /// Video ID.
    VideoId id,

    /// Video title.
    String title,

    /// Video author.
    String author,

    /// Video author Id.
    ChannelId channelId,

    /// Video upload date.
    /// Note: For search queries it is calculated with:
    ///   DateTime.now() - how much time is was published.
    DateTime? uploadDate,
    String? uploadDateRaw,

    /// Video publish date.
    DateTime? publishDate,

    /// Video description.
    String description,

    /// Duration of the video.
    Duration? duration,

    /// Available thumbnails for this video.
    ThumbnailSet thumbnails,

    /// Search keywords used for this video.
    Iterable<String>? keywords,

    /// Engagement statistics for this video.
    Engagement engagement,

    /// Returns true if this is a live stream.
    //ignore: avoid_positional_boolean_parameters
    bool isLive, [
    /// Music data such as song, artist, album, and image.
    /// Empty if no data is available.
    List<MusicData> musicData = const [],

    /// Used internally.
    /// Shouldn't be used in the code.
    @internal WatchPage? watchPage,
  ]) {
    return Video._internal(
      /// Video ID.
      id,

      /// Video title.
      title,

      /// Video author.
      author,

      /// Video author Id.
      channelId,

      /// Video upload date.
      /// Note: For search queries it is calculated with:
      ///   DateTime.now() - how much time is was published.
      uploadDate,
      uploadDateRaw,

      /// Video publish date.
      publishDate,
      description,
      duration,
      thumbnails,
      UnmodifiableListView(keywords ?? const Iterable.empty()),
      engagement,
      isLive,
      musicData,
      watchPage,
    );
  }

  /// Initializes an instance of [Video]
  const factory Video._internal(
    /// Video ID.
    VideoId id,

    /// Video title.
    String title,

    /// Video author.
    String author,

    /// Video author Id.
    ChannelId channelId,

    /// Video upload date.
    /// Note: For search queries it is calculated with:
    ///   DateTime.now() - how much time is was published.
    DateTime? uploadDate,
    String? uploadDateRaw,

    /// Video publish date.
    DateTime? publishDate,

    /// Video description.
    String description,

    /// Duration of the video.
    Duration? duration,

    /// Available thumbnails for this video.
    ThumbnailSet thumbnails,

    /// Search keywords used for this video.
    UnmodifiableListView<String> keywords,

    /// Engagement statistics for this video.
    Engagement engagement,

    /// Returns true if this is a live stream.
    //ignore: avoid_positional_boolean_parameters
    bool isLive,

    /// Music data such as song, artist, album, and image.
    /// Empty if no data is available.
    List<MusicData> musicData, [
    /// Used internally.
    /// Shouldn't be used in the code.
    @internal WatchPage? watchPage,
  ]) = _Video;

  const Video._();
}
