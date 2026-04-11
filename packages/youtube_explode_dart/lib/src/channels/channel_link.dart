import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_link.freezed.dart';

/// Represents a channel link.
@freezed
abstract class ChannelLink with _$ChannelLink {
  /// Initialize an instance of [ChannelLink]
  const factory ChannelLink(
    /// Link title.
    String title,

    /// Link URL.
    /// Already decoded with the YouTube shortener already taken out.
    Uri url,

    /// Link Icon URL.
    @Deprecated(
      'As of at least 26-08-2023 YT no longer provides icons for links, so this URI is always empty',
    )
    Uri icon,
  ) = _ChannelLink;
}
