import 'package:freezed_annotation/freezed_annotation.dart';

import '../../channels/channel_id.dart';

part 'comment.freezed.dart';

/// YouTube comment metadata.
@freezed
abstract class Comment with _$Comment {
  /// Initializes an instance of [Comment]
  const factory Comment(
    /// Comment author name.
    String author,

    /// Comment author channel id.
    ChannelId channelId,

    /// Comment text.
    String text,

    /// Comment likes count.
    int likeCount,

    /// Published time as string. (For example: "2 years ago")
    String publishedTime,

    /// Comment reply count.
    int replyCount,

    /// True if the comment is hearted by the creator.
    //ignore: avoid_positional_boolean_parameters
    bool isHearted,

    /// Used internally.
    /// Shouldn't be used in the code.
    @internal String? continuation,
  ) = _Comment;
}
