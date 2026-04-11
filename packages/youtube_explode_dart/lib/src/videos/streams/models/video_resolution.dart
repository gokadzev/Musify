import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_resolution.g.dart';

/// Width and height of a video.
@JsonSerializable()
class VideoResolution implements Comparable<VideoResolution> {
  /// Viewport width.
  final int width;

  /// Viewport height.
  final int height;

  /// Initializes an instance of [VideoResolution]
  const VideoResolution(this.width, this.height);

  factory VideoResolution.fromJson(Map<String, dynamic> json) =>
      _$VideoResolutionFromJson(json);

  Map<String, dynamic> toJson() => _$VideoResolutionToJson(this);

  @override
  String toString() => '${width}x$height';

  @override
  int compareTo(VideoResolution other) {
    if (width == other.width && height == other.height) {
      return 0;
    }

    if (width > other.width) {
      return 1;
    }

    if (width == other.width && height > other.height) {
      return 1;
    }
    return -1;
  }

  @override
  operator ==(Object other) {
    if (other is VideoResolution) {
      return width == other.width && height == other.height;
    }
    return false;
  }

  operator >(VideoResolution other) {
    return compareTo(other) > 0;
  }

  operator <(VideoResolution other) {
    return compareTo(other) < 0;
  }

  operator >=(VideoResolution other) {
    return compareTo(other) >= 0;
  }

  operator <=(VideoResolution other) {
    return compareTo(other) <= 0;
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}
