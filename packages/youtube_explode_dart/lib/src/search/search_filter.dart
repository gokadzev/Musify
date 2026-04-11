class SearchFilter {
  /// The value fo the 'sp' argument.
  final String value;

  const SearchFilter(this.value);
}

class FeatureFilters {
  const FeatureFilters._();

  /// Live video.
  static const SearchFilter live = SearchFilter('EgJAAQ%253D%253D');

  /// 4K video.
  static const SearchFilter v4k = SearchFilter('EgJwAQ%253D%253D');

  /// HD video.
  static const SearchFilter hd = SearchFilter('EgIgAQ%253D%253D');

  /// Subtitled video.
  static const SearchFilter subTitles = SearchFilter('EgIoAQ%253D%253D');

  /// Creative comments video.
  static const SearchFilter creativeCommons = SearchFilter('EgIwAQ%253D%253D');

  /// 360° video.
  static const SearchFilter v360 = SearchFilter('EgJ4AQ%253D%253D');

  /// VR 180° video.
  static const SearchFilter vr180 = SearchFilter('EgPQAQE%253D');

  /// 3D video.
  static const SearchFilter v3D = SearchFilter('EgI4AQ%253D%253D');

  /// HDR video.
  static const SearchFilter hdr = SearchFilter('EgPIAQE%253D');

  /// Video with location.
  static const SearchFilter location = SearchFilter('EgO4AQE%253D');

  /// Purchased video.
  static const SearchFilter purchased = SearchFilter('EgJIAQ%253D%253D');
}

class UploadDateFilter {
  const UploadDateFilter._();

  /// Videos uploaded in the last hour.
  static const SearchFilter lastHour = SearchFilter('EgIIAQ%253D%253D');

  /// Videos uploaded today.
  static const SearchFilter today = SearchFilter('EgIIAg%253D%253D');

  /// Videos uploaded in the last week.
  static const SearchFilter lastWeek = SearchFilter('EgIIAw%253D%253D');

  /// Videos uploaded in the last month.
  static const SearchFilter lastMonth = SearchFilter('EgIIBA%253D%253D');

  /// Videos uploaded in the last year.
  static const SearchFilter lastYear = SearchFilter('EgIIBQ%253D%253D');
}

class TypeFilters {
  const TypeFilters._();

  /// Videos.
  static const SearchFilter video = SearchFilter('EgIQAQ%253D%253D');

  /// Channels.
  static const SearchFilter channel = SearchFilter('EgIQAg%253D%253D');

  /// Playlists.
  static const SearchFilter playlist = SearchFilter('EgIQAw%253D%253D');

  /// Movies.
  static const SearchFilter movie = SearchFilter('EgIQBA%253D%253D');

  /// Shows.
  static const SearchFilter show = SearchFilter('EgIQBQ%253D%253D');
}

class DurationFilters {
  const DurationFilters._();

  /// Short videos, < 4 minutes.
  static const SearchFilter short = SearchFilter('EgIYAQ%253D%253D');

  /// Long videos, > 20 minutes.
  static const SearchFilter long = SearchFilter('EgIYAg%253D%253D');
}

class SortFilters {
  const SortFilters._();

  /// Sort by relevance (default).
  static const SearchFilter relevance = SearchFilter('CAASAhAB');

  /// Sort by upload date (default).
  static const SearchFilter uploadDate = SearchFilter('CAI%253D');

  /// Sort by view count (default).
  static const SearchFilter viewCount = SearchFilter('CAM%253D');

  /// Sort by rating (default).
  static const SearchFilter rating = SearchFilter('CAE%253D');
}
