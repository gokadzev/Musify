import 'package:meta/meta.dart';

/// Video types provided by Youtube
enum VideoType {
  /// Default horizontal video
  normal('videos', 'videoRenderer'),

  /// Youtube shorts video
  shorts('shorts', 'shortsLockupViewModel');

  final String name;

  @internal
  final String youtubeRenderText;

  const VideoType(this.name, this.youtubeRenderText);
}
