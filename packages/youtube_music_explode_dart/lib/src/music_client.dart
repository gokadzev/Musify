import 'package:youtube_explode_dart/youtube_explode_dart.dart';

typedef _JsonMap = Map<String, dynamic>;

/// A canonical YouTube Music artist result.
class MusicArtist {
  const MusicArtist({required this.id, required this.name, this.thumbnailUrl});

  /// Canonical `UC...` artist channel id.
  final String id;

  /// Display name returned by YouTube Music.
  final String name;

  /// Artist avatar URL, when YouTube Music exposes one.
  final String? thumbnailUrl;
}

/// Kind of a release listed on a YouTube Music artist page.
enum MusicReleaseType { album, single, ep, other }

/// A release (album, single or EP) as listed on a YouTube Music artist page.
class MusicAlbum {
  const MusicAlbum(
    this.id,
    this.title, {
    this.thumbnailUrl,
    this.type = MusicReleaseType.other,
    this.year,
  });

  /// Browse id of the release, e.g. `MPREb_...`.
  final String id;

  /// Display title of the release.
  final String title;

  /// Release artwork URL, when YouTube Music exposes one.
  final String? thumbnailUrl;

  /// Whether YouTube Music lists this release as a single or an EP. Album
  /// shelves only label their entries in the full grid, so an unlabelled
  /// release is [MusicReleaseType.other].
  final MusicReleaseType type;

  /// Release year, when YouTube Music exposes one.
  final String? year;

  @override
  String toString() => 'MusicAlbum($id, $title)';
}

/// A YouTube Music release page: the release itself plus its tracks.
class MusicReleasePage {
  const MusicReleasePage({
    required this.id,
    required this.title,
    this.artist,
    this.artistId,
    this.thumbnailUrl,
    this.year,
    this.tracks = const [],
  });

  /// Browse id of the release, e.g. `MPREb_...`.
  final String id;

  /// Display title of the release.
  final String title;

  /// Artist credited for the release, when YouTube Music exposes one.
  final String? artist;

  /// Channel id of that artist, when its name links to its page.
  final String? artistId;

  /// Release artwork URL, when YouTube Music exposes one.
  final String? thumbnailUrl;

  /// Release year, when YouTube Music exposes one.
  final String? year;

  /// The tracks of the release, in order.
  final List<Video> tracks;
}

/// A track of the artist page "Top songs" shelf.
class MusicTopSong {
  const MusicTopSong(this.video, this.playCount);

  /// The track itself.
  final Video video;

  /// Play count as displayed by YouTube Music, e.g. `1.2B plays`, when the
  /// shelf lists one.
  final String? playCount;
}

/// A YouTube Music artist page.
class MusicArtistProfile {
  const MusicArtistProfile({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.description,
    this.monthlyListeners,
    this.topSongs = const [],
    this.releases = const [],
    this.relatedArtists = const [],
  });

  /// Canonical `UC...` artist channel id, not necessarily the one the page was
  /// asked for: see [MusicClient.getArtistProfile].
  final String id;

  /// Display name returned by YouTube Music.
  final String name;

  /// Header artwork URL, when YouTube Music exposes one.
  final String? thumbnailUrl;

  /// Artist biography, when YouTube Music exposes one.
  final String? description;

  /// Monthly listeners as displayed by YouTube Music, e.g.
  /// `331M monthly audience`.
  final String? monthlyListeners;

  /// The tracks of the artist page "Top songs" shelf.
  final List<MusicTopSong> topSongs;

  /// Every release of the artist: albums, singles and EPs.
  final List<MusicAlbum> releases;

  /// Artists the "Fans might also like" shelf points to.
  final List<MusicArtist> relatedArtists;
}

/// Queries the YouTube Music (`WEB_REMIX`) browse endpoints.
class MusicClient {
  /// Initializes an instance of [MusicClient].
  const MusicClient(this._httpClient);

  final YoutubeHttpClient _httpClient;

  static const _remixContext = {
    'client': {
      'clientName': 'WEB_REMIX',
      'clientVersion': '1.20240101.01.00',
      'hl': 'en',
    },
  };

  /// Search filter that restricts results to artists only.
  static const _artistsSearchParams = 'EgWKAQIgAWoMEA4QChADEAQQCRAF';

  /// Search filter that restricts results to the dedicated "Songs" shelf
  /// (same encoding as [_artistsSearchParams], `II` in place of `Ig`).
  /// Scored candidates only, no cross-category noise from videos/albums/
  /// artists sharing the query — which is also what keeps a query like
  /// "Bad Michael Jackson" from surfacing a live recording or a
  /// differently-titled track above the actual song.
  static const _songsSearchParams = 'EgWKAQIIAWoMEA4QChADEAQQCRAF';

  static const _artistPageType = 'MUSIC_PAGE_TYPE_ARTIST';

  /// Stands in for the channel of a track whose artist page is unknown.
  static const _unknownChannelId = 'UC0000000000000000000000';

  /// Matches the play count of a top song, e.g. `1.2B plays`. The client asks
  /// for `hl: en`, so the wording is stable.
  static final _playCountPattern = RegExp(
    r'^[\d.,]+\s?[KMB]?\s+plays$',
    caseSensitive: false,
  );

  /// Searches YouTube Music for canonical artist entries matching [query].
  Future<List<MusicArtist>> searchArtists(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return [];

    final root = await _httpClient.sendPost('search', {
      'context': _remixContext,
      'query': normalizedQuery,
      'params': _artistsSearchParams,
    });

    final results = <MusicArtist>[];
    final seen = <String>{};
    for (final item in _findRenderers(
      root,
      'musicResponsiveListItemRenderer',
    )) {
      final endpoint = item
          .getMap('navigationEndpoint')
          ?.getMap('browseEndpoint');
      final id = endpoint?.getValue<String>('browseId');
      if (id == null || !id.startsWith('UC') || !seen.add(id)) continue;

      final pageType = endpoint
          ?.getMap('browseEndpointContextSupportedConfigs')
          ?.getMap('browseEndpointContextMusicConfig')
          ?.getValue<String>('pageType');
      if (pageType != _artistPageType) continue;

      final name = _flexColumnText(item, 0) ?? '';
      if (name.trim().isEmpty) continue;

      results.add(
        MusicArtist(
          id: id,
          name: name.trim(),
          thumbnailUrl: _thumbnailUrl(item, 'thumbnail'),
        ),
      );
    }
    return results;
  }

  /// Searches YouTube Music's dedicated "Songs" shelf for a track matching
  /// [query] and returns the best match, or `null` if nothing resolves to a
  /// playable video.
  ///
  /// Goes through the same `WEB_REMIX` browse/search endpoints as
  /// [getArtistProfile] instead of the public search results page, which is
  /// what keeps this from tripping YouTube's anti-scraping rate limiting the
  /// way scraping `youtube.com/results` repeatedly does. Filtering to the
  /// Songs shelf specifically (rather than the general mixed search) also
  /// keeps videos/albums/artists sharing the query from crowding out the
  /// actual song candidates.
  ///
  /// Every row in this shelf is already a song, so unlike a general search
  /// result its subtitle is `Artist • Album • Duration`, with no leading
  /// type label to skip.
  ///
  /// [expectedArtist] and [expectedTitle], when given, reject any row whose
  /// credited artist or title doesn't loosely match them (see
  /// [_looselyMatch]) instead of trusting YouTube Music's top result
  /// blindly. This matters for callers matching a known (title, artist)
  /// pair — e.g. a Spotify CSV import — where a viral cover/remix of a
  /// common title can otherwise rank above the original (wrong artist,
  /// matching title), and checking the artist alone isn't enough either:
  /// the next-best same-artist result can just as easily be a completely
  /// different song by them (matching artist, wrong title). A CSV row that
  /// itself asks for a specific recording (its title says "Live" or
  /// "Remix") still gets it, since that's now part of the expected title
  /// being matched against.
  Future<Video?> searchSong(
    String query, {
    String? expectedArtist,
    String? expectedTitle,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return null;

    final root = await _httpClient.sendPost('search', {
      'context': _remixContext,
      'query': normalizedQuery,
      'params': _songsSearchParams,
    }, validate: true);

    final isValidating = expectedArtist != null || expectedTitle != null;
    Video? fallback;
    for (final item in _findRenderers(
      root,
      'musicResponsiveListItemRenderer',
    )) {
      final videoId = _trackVideoId(item);
      if (videoId == null) continue;

      final title = _flexColumnText(item, 0);
      if (title == null || title.isEmpty) continue;

      final subtitleParts = _splitBullets(_flexColumnText(item, 1));
      final artist = subtitleParts.isNotEmpty ? subtitleParts.first : '';

      final video = _trackVideo(item, videoId, title, artist, null);
      fallback ??= video;

      if (expectedArtist != null && !_looselyMatch(artist, expectedArtist)) {
        continue;
      }
      if (expectedTitle != null && !_looselyMatch(title, expectedTitle)) {
        continue;
      }

      return video;
    }

    // Without anything to validate, preserve the original behavior: fall
    // back to the first result. With validation requested, a mismatched
    // top result is worse than no result, so don't fall back to it.
    return isValidating ? null : fallback;
  }

  /// Splits a `Song • Artist • Album` style subtitle line on its bullet
  /// separators.
  List<String> _splitBullets(String? text) {
    if (text == null) return const [];
    return text
        .split('•')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  /// Loose match used to reject a search row whose title or credited artist
  /// clearly isn't the one being searched for. Compares the two as *sets*
  /// of normalized words rather than as ordered text, so it doesn't care
  /// about word order or connector words — only whether the shorter side's
  /// words are all present on the longer side. That one rule is what makes
  /// "Arctic Monkeys" match "Arctic Monkeys", "Sia" match a row crediting
  /// "Sia & Diplo", a comma-joined CSV artist list ("Queen,David Bowie")
  /// match YouTube Music's own "Queen & David Bowie" or "Hugo e Guilherme"
  /// (Portuguese) credit for the same track, and a title with a
  /// differently-placed qualifier ("love nwantiti (Remix) (feat. ...)" vs
  /// "love nwantiti (feat. ...) - Remix") still match — without hand-coding
  /// each connector word or language. An empty/unparseable side doesn't
  /// block a match, since that just means the row didn't carry a usable
  /// string to check in the first place.
  bool _looselyMatch(String candidate, String expected) {
    final a = _wordsForMatch(candidate);
    final b = _wordsForMatch(expected);
    if (a.isEmpty || b.isEmpty) return true;
    final shorter = a.length <= b.length ? a : b;
    final longer = identical(shorter, a) ? b : a;
    return shorter.every(longer.contains);
  }

  Set<String> _wordsForMatch(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toSet();

  /// Returns a YouTube Music artist page: header details, top songs, the full
  /// discography and the artists it points to.
  ///
  /// [channelId] does not have to be the channel of the artist itself: the
  /// channel that uploads its videos — a label, a VEVO channel — answers with
  /// a partial page of the same artist, whose header still points at the
  /// canonical channel. [MusicArtistProfile.id] holds that one, so a caller
  /// that asked with an uploader can tell and read the real page instead.
  Future<MusicArtistProfile> getArtistProfile(dynamic channelId) async {
    final id = ChannelId.fromString(channelId).value;
    final root = await _browse(id);

    final header =
        _firstRenderer(root, 'musicImmersiveHeaderRenderer') ??
        _firstRenderer(root, 'musicVisualHeaderRenderer');
    final name = (_runsText(header?.getMap('title')) ?? '').trim();
    final canonicalId = _headerChannelId(header) ?? id;

    return MusicArtistProfile(
      id: canonicalId,
      name: name,
      thumbnailUrl: _thumbnailUrl(header, 'thumbnail'),
      description: _runsText(header?.getMap('description')),
      monthlyListeners: _runsText(header?.getMap('monthlyListenerCount')),
      topSongs: _parseTopSongs(root, channelId: canonicalId, author: name),
      releases: await _collectDiscography(root),
      relatedArtists: _collectRelatedArtists(
        root,
      ).where((artist) => artist.id != canonicalId).toList(),
    );
  }

  /// Channel the subscribe button of a page header subscribes to, which is the
  /// artist itself even on the page of a channel that only uploads for it.
  String? _headerChannelId(_JsonMap? header) {
    final channelId = header
        ?.getMap('subscriptionButton')
        ?.getMap('subscribeButtonRenderer')
        ?.getValue<String>('channelId');
    return (channelId != null && channelId.startsWith('UC')) ? channelId : null;
  }

  /// Returns a release with its tracks, credited to the artist its own header
  /// names.
  Future<MusicReleasePage> getAlbum(String albumBrowseId) async {
    final root = await _browse(albumBrowseId);
    final header =
        _firstRenderer(root, 'musicResponsiveHeaderRenderer') ??
        _firstRenderer(root, 'musicDetailHeaderRenderer');
    final albumArtist = _runsText(header?.getMap('straplineTextOne'))?.trim();
    final albumArtistId = _straplineChannelId(header);

    final videos = <Video>[];
    final seen = <String>{};
    for (final item in _findRenderers(
      root,
      'musicResponsiveListItemRenderer',
    )) {
      final videoId = _trackVideoId(item);
      if (videoId == null || !seen.add(videoId)) continue;

      final title = _flexColumnText(item, 0);
      if (title == null || title.isEmpty) continue;

      videos.add(
        _trackVideo(item, videoId, title, albumArtist ?? '', albumArtistId),
      );
    }

    return MusicReleasePage(
      id: albumBrowseId,
      title: _runsText(header?.getMap('title'))?.trim() ?? '',
      artist: albumArtist,
      artistId: albumArtistId,
      thumbnailUrl: _thumbnailUrl(header, 'thumbnail'),
      year: _releaseYearOf(_subtitleParts(header)),
      tracks: videos,
    );
  }

  /// Channel id behind the artist name of a release header, when it links to
  /// the page of that artist.
  String? _straplineChannelId(_JsonMap? header) {
    final runs = header?.getMap('straplineTextOne')?.getList('runs');
    for (final run in runs?.whereType<Map>() ?? const <Map>[]) {
      final browseId = run
          .cast<String, dynamic>()
          .getMap('navigationEndpoint')
          ?.getMap('browseEndpoint')
          ?.getValue<String>('browseId');
      if (browseId != null && browseId.startsWith('UC')) return browseId;
    }
    return null;
  }

  Future<_JsonMap> _browse(String browseId, {String? params}) {
    return _httpClient.sendPost('browse', {
      'context': _remixContext,
      'browseId': browseId,
      if (params != null) 'params': params,
    });
  }

  /// Every release of the artist page: the grid behind each shelf's "More"
  /// button, plus the entries only shown inline.
  Future<List<MusicAlbum>> _collectDiscography(_JsonMap root) async {
    final grids = await Future.wait([
      for (final more in _collectMoreReleaseBrowses(root))
        _browse(
          more.$1,
          params: more.$2,
        ).catchError((_) => <String, dynamic>{}),
    ]);

    // Grids first: they label the release type, the inline previews of an
    // album shelf do not, and [_collectReleases] keeps the first entry seen.
    final releases = <String, MusicAlbum>{};
    for (final grid in grids) {
      _collectReleases(grid, releases);
    }
    _collectReleases(root, releases);
    return releases.values.toList();
  }

  List<MusicTopSong> _parseTopSongs(
    _JsonMap root, {
    required String channelId,
    required String author,
  }) {
    final shelf = _firstRenderer(root, 'musicShelfRenderer');
    if (shelf == null) return const [];

    final songs = <MusicTopSong>[];
    final seen = <String>{};
    for (final item in _findRenderers(
      shelf,
      'musicResponsiveListItemRenderer',
    )) {
      final videoId = _trackVideoId(item);
      if (videoId == null || !seen.add(videoId)) continue;

      final title = _flexColumnText(item, 0);
      if (title == null || title.isEmpty) continue;

      final trackAuthor = _flexColumnText(item, 1);
      songs.add(
        MusicTopSong(
          _trackVideo(
            item,
            videoId,
            title,
            (trackAuthor == null || trackAuthor.isEmpty) ? author : trackAuthor,
            channelId,
          ),
          _playCountText(item),
        ),
      );
    }

    return songs;
  }

  /// One track row of a shelf or of a release, as a [Video]. Only the fields
  /// YouTube Music lists in a row are known, the rest is left empty.
  Video _trackVideo(
    _JsonMap item,
    String videoId,
    String title,
    String author,
    String? channelId,
  ) {
    return Video(
      VideoId(videoId),
      title,
      author,
      ChannelId.fromString(channelId ?? _unknownChannelId),
      null,
      null,
      null,
      '',
      _parseDuration(_fixedColumnText(item)),
      ThumbnailSet(videoId),
      null,
      const Engagement(0, null, null),
      false,
    );
  }

  /// The play count column of a top song, when the shelf lists one. Its
  /// position varies, so every column after the title is probed.
  String? _playCountText(_JsonMap item) {
    for (var index = 1; index < 4; index++) {
      final text = _flexColumnText(item, index);
      if (text != null && _playCountPattern.hasMatch(text)) return text;
    }
    return null;
  }

  void _collectReleases(dynamic root, Map<String, MusicAlbum> into) {
    for (final item in _findRenderers(root, 'musicTwoRowItemRenderer')) {
      final browseId = item
          .getMap('navigationEndpoint')
          ?.getMap('browseEndpoint')
          ?.getValue<String>('browseId');
      if (browseId == null || !browseId.startsWith('MPRE')) continue;

      final title = _runsText(item.getMap('title'));
      // `Album • 2019`, `Single • 2021`, or just the year when the entry is an
      // inline preview.
      final subtitle = _subtitleParts(item);
      into.putIfAbsent(
        browseId,
        () => MusicAlbum(
          browseId,
          title?.trim() ?? '',
          thumbnailUrl: _thumbnailUrl(item, 'thumbnailRenderer'),
          type: _releaseTypeOf(subtitle),
          year: _releaseYearOf(subtitle),
        ),
      );
    }
  }

  /// Collects the artists of the "Fans might also like" shelf. They sit in the
  /// same rows as the releases, told apart by their channel browse id.
  List<MusicArtist> _collectRelatedArtists(dynamic root) {
    final artists = <String, MusicArtist>{};
    for (final item in _findRenderers(root, 'musicTwoRowItemRenderer')) {
      final endpoint = item
          .getMap('navigationEndpoint')
          ?.getMap('browseEndpoint');
      final browseId = endpoint?.getValue<String>('browseId');
      if (browseId == null || !browseId.startsWith('UC')) continue;

      final pageType = endpoint
          ?.getMap('browseEndpointContextSupportedConfigs')
          ?.getMap('browseEndpointContextMusicConfig')
          ?.getValue<String>('pageType');
      if (pageType != _artistPageType) continue;

      final name = _runsText(item.getMap('title'))?.trim();
      if (name == null || name.isEmpty) continue;

      artists.putIfAbsent(
        browseId,
        () => MusicArtist(
          id: browseId,
          name: name,
          thumbnailUrl: _thumbnailUrl(item, 'thumbnailRenderer'),
        ),
      );
    }
    return artists.values.toList();
  }

  List<(String, String?)> _collectMoreReleaseBrowses(_JsonMap root) {
    final result = <(String, String?)>[];
    for (final header in _findRenderers(
      root,
      'musicCarouselShelfBasicHeaderRenderer',
    )) {
      final endpoint = header
          .getMap('moreContentButton')
          ?.getMap('buttonRenderer')
          ?.getMap('navigationEndpoint')
          ?.getMap('browseEndpoint');
      final browseId = endpoint?.getValue<String>('browseId');
      if (browseId == null || !browseId.startsWith('MPAD')) continue;
      result.add((browseId, endpoint?.getValue<String>('params')));
    }
    return result;
  }

  List<String> _subtitleParts(_JsonMap? item) {
    final subtitle = _runsText(item?.getMap('subtitle'));
    if (subtitle == null) return const [];
    return subtitle
        .split('•')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  MusicReleaseType _releaseTypeOf(List<String> subtitleParts) {
    for (final part in subtitleParts) {
      switch (part.toLowerCase()) {
        case 'album':
          return MusicReleaseType.album;
        case 'single':
          return MusicReleaseType.single;
        case 'ep':
          return MusicReleaseType.ep;
      }
    }
    return MusicReleaseType.other;
  }

  String? _releaseYearOf(List<String> subtitleParts) {
    for (final part in subtitleParts) {
      if (RegExp(r'^(19|20)\d{2}$').hasMatch(part)) return part;
    }
    return null;
  }

  String? _trackVideoId(_JsonMap item) {
    return item
        .getMap('overlay')
        ?.getMap('musicItemThumbnailOverlayRenderer')
        ?.getMap('content')
        ?.getMap('musicPlayButtonRenderer')
        ?.getMap('playNavigationEndpoint')
        ?.getMap('watchEndpoint')
        ?.getValue<String>('videoId');
  }

  String? _flexColumnText(_JsonMap item, int index) {
    final columns = item.getList('flexColumns');
    if (columns == null || columns.length <= index) return null;
    final column = columns[index];
    if (column is! Map) return null;
    return _runsText(
      column
          .cast<String, dynamic>()
          .getMap('musicResponsiveListItemFlexColumnRenderer')
          ?.getMap('text'),
    );
  }

  String? _runsText(_JsonMap? node) {
    final runs = node?.getList('runs')?.whereType<Map>().parseRuns();
    return (runs == null || runs.isEmpty) ? null : runs;
  }

  String? _fixedColumnText(_JsonMap item) {
    final columns = item.getList('fixedColumns');
    if (columns == null || columns.isEmpty) return null;
    final lastColumn = columns.last;
    if (lastColumn is! Map) return null;
    return lastColumn
        .cast<String, dynamic>()
        .getMap('musicResponsiveListItemFixedColumnRenderer')
        ?.getMap('text')
        ?.getList('runs')
        ?.whereType<Map>()
        .parseRuns();
  }

  /// The largest artwork URL under [key], which holds a thumbnail renderer:
  /// `thumbnail` on headers and list items, `thumbnailRenderer` on shelf rows.
  String? _thumbnailUrl(_JsonMap? node, String key) {
    final thumbnails = node
        ?.getMap(key)
        ?.getMap('musicThumbnailRenderer')
        ?.getMap('thumbnail')
        ?.getList('thumbnails');
    if (thumbnails == null || thumbnails.isEmpty) return null;
    final thumbnail = thumbnails.last;
    if (thumbnail is! Map) return null;
    return thumbnail.cast<String, dynamic>().getValue<String>('url');
  }

  Duration? _parseDuration(String? value) {
    if (value == null) return null;
    final parts = value.trim().split(':');
    if (parts.isEmpty || parts.length > 3) return null;

    var seconds = 0;
    for (final part in parts) {
      final n = int.tryParse(part.trim());
      if (n == null) return null;
      seconds = seconds * 60 + n;
    }
    return Duration(seconds: seconds);
  }

  _JsonMap? _firstRenderer(dynamic node, String rendererKey) {
    for (final renderer in _findRenderers(node, rendererKey)) {
      return renderer;
    }
    return null;
  }

  Iterable<_JsonMap> _findRenderers(dynamic node, String rendererKey) sync* {
    if (node is Map) {
      final match = node[rendererKey];
      if (match is Map) yield match.cast<String, dynamic>();
      for (final value in node.values) {
        yield* _findRenderers(value, rendererKey);
      }
    } else if (node is List) {
      for (final value in node) {
        yield* _findRenderers(value, rendererKey);
      }
    }
  }
}

extension _MapReader on Map<String, dynamic> {
  Map<String, dynamic>? getMap(String key) {
    final value = this[key];
    return value is Map ? value.cast<String, dynamic>() : null;
  }

  List<dynamic>? getList(String key) {
    final value = this[key];
    return value is List ? value : null;
  }

  T? getValue<T>(String key) {
    final value = this[key];
    return value is T ? value : null;
  }
}

extension _RunsParser on Iterable<Map<dynamic, dynamic>> {
  String parseRuns() {
    return map((run) => run['text']?.toString() ?? '').join();
  }
}
