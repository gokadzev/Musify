import '../../youtube_explode_dart.dart';
import '../reverse_engineering/pages/search_page.dart';

///
class SearchQuery {
  final YoutubeHttpClient _httpClient;

  /// Search query
  final String searchQuery;

  final SearchPage _page;

  /// Initializes a SearchQuery
  SearchQuery(this._httpClient, this.searchQuery, this._page);

  /// Search a video.
  static Future<SearchQuery> search(
    YoutubeHttpClient httpClient,
    String searchQuery, {
    SearchFilter filter = const SearchFilter(''),
  }) async {
    final page = await SearchPage.get(httpClient, searchQuery, filter: filter);
    return SearchQuery(httpClient, searchQuery, page);
  }

  /// Get the data of the next page.
  /// Returns null if there is no next page.
  Future<SearchQuery?> nextPage() async {
    final page = await _page.nextPage(_httpClient);
    if (page == null) {
      return null;
    }
    return SearchQuery(_httpClient, searchQuery, page);
  }

  /// Content of this search.
  /// Contains either [SearchVideo], [SearchPlaylist] or [SearchChannel]
  List<SearchResult> get content => _page.searchContent;

  /// Videos related to this search.
  /// Contains either [SearchVideo] or [SearchPlaylist]
  List<SearchResult> get relatedVideos => _page.relatedVideos;

  /// Returns the estimated search result count.
  int get estimatedResults => _page.estimatedResults;
}
