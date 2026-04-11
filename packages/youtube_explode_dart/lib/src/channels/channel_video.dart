import 'package:freezed_annotation/freezed_annotation.dart';

import '../videos/video_id.dart';

part 'channel_video.freezed.dart';

/// Metadata related to content from a channel's page (video)
@freezed
abstract class ChannelVideo with _$ChannelVideo {
  const factory ChannelVideo(
    /// Video ID.
    VideoId videoId,

    /// Video title.
    String videoTitle,

    /// Video duration, this is always zero for shorts.
    Duration videoDuration,

    /// Video thumbnail
    String videoThumbnail,

    /// Video upload date. This is always empty for shorts.
    /// Formatted like 10 hours ago
    String videoUploadDate,

    /// Video view count.
    int videoViews,
  ) = _ChannelVideo;
}
