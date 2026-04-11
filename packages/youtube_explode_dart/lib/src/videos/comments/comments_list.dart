import 'dart:async';

import '../../../youtube_explode_dart.dart';
import '../../reverse_engineering/clients/comments_client.dart' as re;

/// This list contains search videos.
///This behaves like a [List] but has the [SearchList.nextPage] to get the next batch of videos.
class CommentsList extends BasePagedList<Comment> {
  final re.CommentsClient _client;
  final YoutubeHttpClient _httpClient;
  final int totalLength;

  /// Construct an instance of [SearchList]
  /// See [SearchList]
  CommentsList(super.base, this.totalLength, this._client, this._httpClient);

  /// Fetches the next batch of videos or returns null if there are no more
  /// results.
  @override
  Future<CommentsList?> nextPage() async {
    final page = await _client.nextPage(_httpClient);
    if (page == null || page.comments == null) {
      return null;
    }

    return CommentsList(
      page.comments!
          .map(
            (e) => Comment(
              e.author,
              ChannelId(e.channelId),
              e.text,
              e.likeCount ?? 0,
              e.publishTime,
              e.repliesCount ?? 0,
              e.isHearted,
              e.continuation,
            ),
          )
          .toList(growable: false),
      totalLength,
      page,
      _httpClient,
    );
  }
}
