import 'dart:async';

import '../../youtube_explode_dart.dart';
import '../extensions/helpers_extension.dart';
import '../reverse_engineering/pages/search_page.dart';

/// This contains the search results which can be a video, channel or playlist.
///This behaves like a [List] but has the [SearchList.nextPage] to get the next batch of videos.
class SearchList extends BasePagedList<SearchResult> {
  final SearchPage _page;
  final YoutubeHttpClient _httpClient;

  /// Construct an instance of [SearchList]
  /// See [SearchList]
  SearchList(super.base, this._page, this._httpClient);

  /// Fetches the next batch of videos or returns null if there are no more
  /// results.
  @override
  Future<SearchList?> nextPage() async {
    final page = await _page.nextPage(_httpClient);
    if (page == null) {
      return null;
    }

    return SearchList(page.searchContent, page, _httpClient);
  }
}

/// This contains the search results which can only be a video
/// Same as [SearchList] but filters to only return Videos.
///This behaves like a [List] but has the [SearchList.nextPage] to get the next batch of videos.

class VideoSearchList extends BasePagedList<Video> {
  final SearchPage _page;
  final YoutubeHttpClient _httpClient;

  /// Construct an instance of [SearchList]
  /// See [SearchList]
  VideoSearchList(super.base, this._page, this._httpClient);

  /// Fetches the next batch of videos or returns null if there are no more
  /// results.
  @override
  Future<VideoSearchList?> nextPage() async {
    final page = await _page.nextPage(_httpClient);
    if (page == null) {
      return null;
    }

    return VideoSearchList(
      page.searchContent
          .whereType<SearchVideo>()
          .map(
            (e) => Video(
              e.id,
              e.title,
              e.author,
              ChannelId(e.channelId),
              e.uploadDate.toDateTime(),
              e.uploadDate,
              null,
              e.description,
              e.duration.toDuration(),
              ThumbnailSet(e.id.value),
              null,
              Engagement(e.viewCount, null, null),
              e.isLive,
            ),
          )
          .toList(),
      page,
      _httpClient,
    );
  }
}
