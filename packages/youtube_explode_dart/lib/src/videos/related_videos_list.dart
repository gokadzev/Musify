import 'package:meta/meta.dart';

import '../../youtube_explode_dart.dart';
import '../reverse_engineering/clients/related_videos_client.dart';

/// This list contains videos related to another [Video].
/// This behaves like a [List] but has the [RelatedVideosList.nextPage] to get the next batch of videos.
class RelatedVideosList extends BasePagedList<Video> {
  final RelatedVideosClient _client;
  final YoutubeHttpClient _httpClient;

  /// Construct an instance of [RelatedVideosList]
  @internal
  RelatedVideosList(super.base, this._client, this._httpClient);

  /// Fetches the next batch of videos or returns null if there are no more
  /// results.
  @override
  Future<RelatedVideosList?> nextPage() async {
    final page = await _client.nextPage(_httpClient);
    if (page == null) {
      return null;
    }

    return RelatedVideosList(page.relatedVideos().toList(), page, _httpClient);
  }
}
