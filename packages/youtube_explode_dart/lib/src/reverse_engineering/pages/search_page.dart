import 'package:collection/collection.dart';
import 'package:html/parser.dart' as parser;
import 'package:logging/logging.dart';

import '../../../youtube_explode_dart.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';

///
class SearchPage extends YoutubePage<_InitialData> {
  ///
  final String queryString;

  late final List<SearchResult> searchContent = initialData.searchContent;

  late final List<SearchResult> relatedVideos = initialData.relatedVideos;

  late final int estimatedResults = initialData.estimatedResults;

  /// InitialData
  SearchPage.id(this.queryString, _InitialData initialData)
      : super.fromInitialData(initialData);

  Future<SearchPage?> nextPage(YoutubeHttpClient httpClient) async {
    if (initialData.continuationToken?.isEmpty == null ||
        initialData.estimatedResults == 0) {
      return null;
    }

    final data = await httpClient.sendContinuation(
        'search', initialData.continuationToken!);
    return SearchPage.id(queryString, _InitialData(data));
  }

  ///
  static Future<SearchPage> get(
    YoutubeHttpClient httpClient,
    String queryString, {
    SearchFilter filter = const SearchFilter(''),
  }) {
    final url =
        'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(queryString)}&sp=${filter.value}';
    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      return SearchPage.parse(raw, queryString);
    });
    // ask for next page
  }

  ///
  SearchPage.parse(String raw, this.queryString)
      : super(parser.parse(raw), (root) => _InitialData(root));
}

class _InitialData extends InitialData {
  static final _logger = Logger('YoutubeExplode.Search.InitialData');

  _InitialData(super.root);

  List<JsonMap>? getContentContext() {
    if (root['contents'] != null) {
      final sectionContents = root.getJson<List<dynamic>>(
        'contents/twoColumnSearchResultsRenderer/primaryContents/sectionListRenderer/contents',
      );
      final firstSection = sectionContents?.firstOrNull as JsonMap?;
      return firstSection
          ?.getJson<List<dynamic>>('itemSectionRenderer/contents')
          ?.cast<JsonMap>();
    }
    if (root['onResponseReceivedCommands'] != null) {
      final commands =
          root.getJson<List<dynamic>>('onResponseReceivedCommands');
      final firstCmd = commands?.firstOrNull as JsonMap?;
      final continuationItems = firstCmd?.getJson<List<dynamic>>(
        'appendContinuationItemsAction/continuationItems',
      );
      final firstItem = continuationItems?.firstOrNull as JsonMap?;
      return firstItem
          ?.getJson<List<dynamic>>('itemSectionRenderer/contents')
          ?.cast<JsonMap>();
    }
    return null;
  }

  String? _getContinuationToken() {
    if (root['contents'] != null) {
      final contents = root.getJson<List<dynamic>>(
        'contents/twoColumnSearchResultsRenderer/primaryContents/sectionListRenderer/contents',
      );

      if (contents == null || contents.length <= 1) {
        return null;
      }
      return (contents.elementAtSafe(1) as JsonMap?)?.getJson<String>(
        'continuationItemRenderer/continuationEndpoint/continuationCommand/token',
      );
    }
    if (root['onResponseReceivedCommands'] != null) {
      final commands =
          root.getJson<List<dynamic>>('onResponseReceivedCommands');
      final firstCmd = commands?.firstOrNull as JsonMap?;
      final continuationItems = firstCmd?.getJson<List<dynamic>>(
        'appendContinuationItemsAction/continuationItems',
      );
      return (continuationItems?.elementAtSafe(1) as JsonMap?)?.getJson<String>(
        'continuationItemRenderer/continuationEndpoint/continuationCommand/token',
      );
    }
    return null;
  }

  // Contains only [SearchVideo] or [SearchPlaylist]
  late final List<SearchResult> searchContent =
      getContentContext()?.map(_parseContent).nonNulls.toList() ?? const [];

  List<SearchResult> get relatedVideos {
    final context = getContentContext();
    final shelf = context?.where((e) => e['shelfRenderer'] != null).firstOrNull;
    final items = shelf?.getJson<List<dynamic>>(
      'shelfRenderer/content/verticalListRenderer/items',
    );
    return items?.map((e) => _parseContent(e as JsonMap?)).nonNulls.toList() ??
        const [];
  }

  late final String? continuationToken = _getContinuationToken();

  late final int estimatedResults =
      int.parse(root.getT<String>('estimatedResults') ?? '0');

  String _getChannelId(Map<String, dynamic> renderer) {
    final navEndpoint = renderer
        .getJson<Map<String, dynamic>>('ownerText/runs/0/navigationEndpoint')!;

    if (navEndpoint['browseEndpoint'] != null) {
      return navEndpoint.getJson<String>('browseEndpoint/browseId')!;
    }
    if (navEndpoint['showDialogCommand'] != null) {
      return navEndpoint.getJson<String>(
          'showDialogCommand/panelLoadingStrategy/inlineContent/dialogViewModel/customContent/listViewModel/listItems/0/listItemViewModel/rendererContext/commandContext/onTap/innertubeCommand/browseEndpoint/browseId')!;
    }
    _logger.warning('Could not parse channelId from search result');
    return '';
  }

  SearchResult? _parseContent(JsonMap? content) {
    if (content == null) {
      return null;
    }
    if (content['videoRenderer'] != null) {
      final renderer = content.getJson<JsonMap>('videoRenderer')!;

      return SearchVideo(
          VideoId(renderer.getT<String>('videoId')!),
          renderer
              .getJson<List<dynamic>>('title/runs')!
              .cast<Map<dynamic, dynamic>>()
              .parseRuns(),
          renderer
              .getJson<List<dynamic>>('ownerText/runs')!
              .cast<Map<dynamic, dynamic>>()
              .parseRuns(),
          renderer
                  .getJson<List<dynamic>>(
                    'detailedMetadataSnippets/0/snippetText/runs',
                  )
                  ?.cast<Map<dynamic, dynamic>>()
                  .parseRuns() ??
              '',
          renderer.getJson<String>('lengthText/simpleText') ?? '',
          int.parse(
            renderer
                    .getJson<String>('viewCountText/simpleText')
                    ?.stripNonDigits()
                    .nullIfWhitespace ??
                renderer
                    .getJson<List<dynamic>>('viewCountText/runs')
                    ?.firstOrNull
                    ?.getT<String>('text')
                    ?.stripNonDigits()
                    .nullIfWhitespace ??
                '0',
          ),
          (renderer.getJson<List<dynamic>>('thumbnail/thumbnails') ?? const [])
              .map(
                (e) => Thumbnail(
                  Uri.parse((e as Map)['url'] as String),
                  (e)['height'],
                  (e)['width'],
                ),
              )
              .toList(),
          renderer.getJson<String>('publishedTimeText/simpleText'),
          renderer
                  .getJson<List<dynamic>>('viewCountText/runs')
                  ?.elementAtSafe(1)
                  ?.getT<String>('text')
                  ?.trim() ==
              'watching',
          _getChannelId(renderer));
    }

    if (content['radioRenderer'] != null ||
        content['playlistRenderer'] != null) {
      final renderer = content.getJson<JsonMap>('radioRenderer') ??
          content.getJson<JsonMap>('playlistRenderer')!;

      final thumbnails =
          renderer.getJson<List<dynamic>>('thumbnails/0/thumbnails') ??
              const [];
      return SearchPlaylist(
        PlaylistId(renderer.getT<String>('playlistId')!),
        renderer.getJson<String>('title/simpleText')!,
        renderer
                .getJson<List<dynamic>>('videoCountText/runs')
                ?.cast<Map<dynamic, dynamic>>()
                .parseRuns()
                .parseInt() ??
            0,
        thumbnails
            .map((e) => Thumbnail(
                  Uri.parse((e as Map)['url'] as String),
                  (e)['height'],
                  (e)['width'],
                ))
            .toList(),
      );
    }
    if (content['channelRenderer'] != null) {
      final renderer = content.getJson<JsonMap>('channelRenderer')!;

      return SearchChannel(
        ChannelId(renderer.getT<String>('channelId')!),
        renderer.getJson<String>('title/simpleText')!,
        renderer
                .getJson<List<dynamic>>('descriptionSnippet/runs')
                ?.cast<Map<dynamic, dynamic>>()
                .parseRuns() ??
            '',
        renderer
                .getJson<List<dynamic>>('videoCountText/runs')
                ?.first
                .getT<String>('text')
                .parseInt() ??
            -1,
        (renderer.getJson<List<dynamic>>('thumbnail/thumbnails') ?? const [])
            .map((e) => Thumbnail(Uri.parse('https:${(e as Map)['url']}'),
                (e)['height'], (e)['width']))
            .toList(),
      );
    }
    if (content['lockupViewModel'] != null) {
      final viewModel = content.getJson<JsonMap>('lockupViewModel')!;

      final type = viewModel.getT<String>('contentType');
      if (type != 'LOCKUP_CONTENT_TYPE_PLAYLIST') {
        return null;
      }

      final thumbnails = viewModel
          .getJson<List<dynamic>>(
              'contentImage/collectionThumbnailViewModel/primaryThumbnail/thumbnailViewModel/image/sources')!
          .cast<Map<String, dynamic>>();
      return SearchPlaylist(
          PlaylistId(viewModel.getT<String>('contentId')!),
          viewModel.getJson<String>(
              'metadata/lockupMetadataViewModel/title/content')!,
          viewModel
                  .getJson<String>(
                      'contentImage/collectionThumbnailViewModel/primaryThumbnail/thumbnailViewModel/overlays/0/thumbnailOverlayBadgeViewModel/thumbnailBadges/0/thumbnailBadgeViewModel/text')!
                  .parseInt() ??
              0,
          thumbnails
              .map((e) =>
                  Thumbnail(Uri.parse(e['url']), e['height'], e['width']))
              .toList());
    }
    // Here ignore 'horizontalCardListRenderer' & 'shelfRenderer'
    return null;
  }
}
