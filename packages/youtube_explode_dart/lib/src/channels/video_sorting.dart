import 'package:meta/meta.dart';

/// Metadata about video are sorted with [ChannelClient.getUploadsFromPage]
enum VideoSorting {
  newest._('dd'),
  oldest._('da'),
  popularity._('p');

  /// Code used to fetch the video.
  /// Used internally.
  @internal
  final String code;

  const VideoSorting._(this.code);
}
