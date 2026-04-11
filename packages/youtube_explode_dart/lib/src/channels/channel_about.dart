import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/thumbnail.dart';
import 'channel_link.dart';

part 'channel_about.freezed.dart';

/// YouTube channel's about page metadata.
@freezed
abstract class ChannelAbout with _$ChannelAbout {
  const factory ChannelAbout(
    /// Full channel description.
    String? description,

    /// Channel view count.
    int? viewCount,

    /// Channel join date.
    /// Formatted as: Gen 01, 2000
    String? joinDate,

    /// Channel title.
    String title,

    /// Channel thumbnails.
    List<Thumbnail> thumbnails,

    /// Channel country.
    String? country,

    /// Channel links.
    List<ChannelLink> channelLinks,
  ) = _ChannelAbout;
}
