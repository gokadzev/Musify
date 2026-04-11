import 'package:freezed_annotation/freezed_annotation.dart';

import 'channel_id.dart';

part 'channel.freezed.dart';

/// YouTube channel metadata.
@freezed
abstract class Channel with _$Channel {
  ///
  const factory Channel(
    /// Channel ID.
    ChannelId id,

    /// Channel title.
    String title,

    /// URL of the channel's logo image.
    String logoUrl,

    /// URL of the channel's banner image.
    String bannerUrl,

    /// The (approximate) channel subscriber's count.
    int? subscribersCount,
  ) = _Channel;

  /// Channel URL.
  String get url => 'https://www.youtube.com/channel/$id';

  const Channel._();
}
