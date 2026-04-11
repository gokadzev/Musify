import 'package:freezed_annotation/freezed_annotation.dart';

part 'thumbnail_set.freezed.dart';

/// Set of thumbnails for a video.
@freezed
abstract class ThumbnailSet with _$ThumbnailSet {
  /// Initializes an instance of [ThumbnailSet]
  const factory ThumbnailSet(
    /// Video id.
    String videoId,
  ) = _ThumbnailSet;

  const ThumbnailSet._();

  /// Low resolution thumbnail URL.
  String get lowResUrl => 'https://img.youtube.com/vi/$videoId/default.jpg';

  /// Medium resolution thumbnail URL.
  String get mediumResUrl =>
      'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

  /// High resolution thumbnail URL.
  String get highResUrl => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  /// Standard resolution thumbnail URL.
  /// Not always available.
  String get standardResUrl =>
      'https://img.youtube.com/vi/$videoId/sddefault.jpg';

  /// Max resolution thumbnail URL.
  /// Not always available.
  String get maxResUrl =>
      'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
}
