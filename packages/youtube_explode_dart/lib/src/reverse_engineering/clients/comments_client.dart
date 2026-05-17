import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../../youtube_explode_dart.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../pages/watch_page.dart';

@internal
class CommentsClient {
  final JsonMap root;

  late final List<JsonMap>? _commentRenderers = _getCommentRenderers();

  late final List<_Comment>? comments =
      _commentRenderers?.map((e) => _Comment(e)).toList(growable: false);

  late final String? _continuationToken = _getContinuationToken();

  CommentsClient(this.root);

  ///
  static Future<CommentsClient?> get(
    YoutubeHttpClient httpClient,
    Video video,
  ) async {
    final watchPage = video.watchPage ??
        await retry<WatchPage>(
          httpClient,
          () async => WatchPage.get(httpClient, video.id.value),
        );

    final continuation = watchPage.initialData.commentsContinuation;
    if (continuation == null) {
      return null;
    }

    final data = await httpClient.sendContinuation('next', continuation);
    return CommentsClient(data);
  }

  ///
  static Future<CommentsClient?> getReplies(
    YoutubeHttpClient httpClient,
    String token,
  ) async {
    final data = await httpClient.sendContinuation('next', token);
    return CommentsClient(data);
  }

  /*
onResponseReceivedEndpoints[1].reloadContinuationItemsCommand.continuationItems[2].commentThreadRenderer.comment.commentRenderer.contentText.runs[0].text   */
  List<JsonMap>? _getCommentRenderers() {
    final endpoints =
        root.getJson<List<dynamic>>('onResponseReceivedEndpoints');
    final endpoint = endpoints?.last as JsonMap?;
    if (endpoint == null) {
      return null;
    }

    // This was used in old youtube versions.
    final continuationItems = endpoint.getJson<List<dynamic>>(
      'appendContinuationItemsAction/continuationItems',
    );
    final comments = continuationItems
        ?.where((e) => e['commentRenderer'] != null)
        .toList(growable: false);

    if (comments?.isNotEmpty ?? false) {
      return comments?.cast<JsonMap>();
    }

    // This can probably be simplified.
    final cmd = endpoint.getJson<JsonMap>('reloadContinuationItemsCommand') ??
        endpoint.getJson<JsonMap>('appendContinuationItemsAction');
    final items = cmd?.getJson<List<dynamic>>('continuationItems') ??
        cmd?.getJson<List<dynamic>>('appendContinuationItemsAction');
    return items
            ?.where((e) => e['commentThreadRenderer'] != null)
            .map((e) =>
                (e as JsonMap).getJson<JsonMap>('commentThreadRenderer')!)
            .toList(growable: false) ??
        const [];
  }

  String? _getContinuationToken() {
    final endpoints =
        root.getJson<List<dynamic>>('onResponseReceivedEndpoints')!;
    final last = endpoints.last as JsonMap;
    final items = last.getJson<List<dynamic>>(
      'appendContinuationItemsAction/continuationItems',
    );
    final item =
        items?.firstWhereOrNull((e) => e['continuationItemRenderer'] != null)
            as JsonMap?;
    final token = item?.getJson<String>(
      'continuationItemRenderer/button/buttonRenderer/command/continuationCommand/token',
    ); /* Used for the replies */
    if (token != null) return token;

    final cmd = last.getJson<JsonMap>('reloadContinuationItemsCommand') ??
        last.getJson<JsonMap>('appendContinuationItemsAction');
    final continuationItems =
        cmd?.getJson<List<dynamic>>('continuationItems') ??
            cmd?.getJson<List<dynamic>>('appendContinuationItemsAction');
    final continuationItem = continuationItems?.firstWhereOrNull(
        (e) => e['continuationItemRenderer'] != null) as JsonMap?;
    return continuationItem?.getJson<String>(
      'continuationItemRenderer/continuationEndpoint/continuationCommand/token',
    );
  }

  // onResponseReceivedEndpoints[0].reloadContinuationItemsCommand.continuationItems[0].commentsHeaderRenderer
  int getCommentsCount() {
    final firstEndpoint = root
        .getJson<List<dynamic>>('onResponseReceivedEndpoints')!
        .first as JsonMap;
    return firstEndpoint
            .getJson<String>(
              'reloadContinuationItemsCommand/continuationItems/0/commentsHeaderRenderer/commentsCount/runs/0/text',
            )
            ?.parseIntWithUnits() ??
        0;
  }

  Future<CommentsClient?> nextPage(YoutubeHttpClient httpClient) async {
    if (_continuationToken == null) {
      return null;
    }

    final data = await httpClient.sendContinuation('next', _continuationToken!);
    return CommentsClient(data);
  }
}

class _Comment {
  final JsonMap root;

  late final JsonMap _commentRenderer =
      root.getJson<JsonMap>('commentRenderer') ??
          root.getJson<JsonMap>('comment/commentRenderer')!;

  late final JsonMap? _commentRepliesRenderer =
      root.getJson<JsonMap>('replies/commentRepliesRenderer');

  /// Used to get replies
  late final String? continuation = _commentRepliesRenderer?.getJson<String>(
    'contents/0/continuationItemRenderer/continuationEndpoint/continuationCommand/token',
  );

  late final int? repliesCount = _commentRenderer.getT<int>('replyCount');

  late final String author =
      _commentRenderer.getJson<String>('authorText/simpleText')!;

  late final String channelThumbnail = (_commentRenderer
          .getJson<List<dynamic>>('authorThumbnail/thumbnails')!
          .last as JsonMap)
      .getT<String>('url')!;

  late final String channelId = _commentRenderer
      .getJson<String>('authorEndpoint/browseEndpoint/browseId')!;

  late final String text = _commentRenderer
      .getJson<List<dynamic>>('contentText/runs')!
      .cast<Map<dynamic, dynamic>>()
      .parseRuns();

  late final String publishTime =
      _commentRenderer.getJson<String>('publishedTimeText/runs/0/text')!;

  late final int? likeCount = _commentRenderer
      .getJson<String>('voteCount/simpleText')
      .parseIntWithUnits();

  late final bool isHearted = _commentRenderer.getJson<JsonMap>(
        'actionButtons/commentActionButtonsRenderer/creatorHeart',
      ) !=
      null;

  _Comment(this.root);

  @override
  String toString() => '$author: $text';
}

extension _CommentsDataExtension on WatchPageInitialData {
  JsonMap? getContinuationContext() {
    if (root['contents'] != null) {
      final contents = root.getJson<List<dynamic>>(
        'contents/twoColumnWatchNextResults/results/results/contents',
      );
      final section =
          contents?.lastWhereOrNull((e) => e['itemSectionRenderer'] != null)
              as JsonMap?;
      final sectionContents =
          section?.getJson<List<dynamic>>('itemSectionRenderer/contents');
      final first = sectionContents?.firstOrNull as JsonMap?;
      return first?.getJson<JsonMap>(
        'continuationItemRenderer/continuationEndpoint/continuationCommand',
      );
    }
    return null;
  }

  String? get commentsContinuation =>
      getContinuationContext()?.getT<String>('token');
}
