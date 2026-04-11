import 'package:freezed_annotation/freezed_annotation.dart';

part 'engagement.freezed.dart';

/// User activity statistics.
@freezed
abstract class Engagement with _$Engagement {
  const factory Engagement(
    /// View count.
    int viewCount,

    /// Like count.
    int? likeCount,

    /// Dislike count.
    int? dislikeCount,
  ) = _Engagement;

  const Engagement._();

  /// Average user rating in stars (1 star to 5 stars).
  /// Returns -1 if likeCount or dislikeCount is null.
  num get avgRating {
    if (likeCount == null || dislikeCount == null) {
      return -1;
    }
    if (likeCount! + dislikeCount! == 0) {
      return 0;
    }
    return 1 + 4.0 * likeCount! / (likeCount! + dislikeCount!);
  }
}
