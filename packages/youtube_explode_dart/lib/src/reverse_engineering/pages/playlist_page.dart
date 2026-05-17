import 'package:collection/collection.dart';
import 'package:html/parser.dart' as parser;

import '../../../youtube_explode_dart.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';
import '../youtube_http_client.dart';

class PlaylistPage extends YoutubePage<_InitialData> {
  final String playlistId;
  final String? _visitorData;

  late final List<_Video> videos = initialData.playlistVideos;
  late final String? title = initialData.title;
  late final String? description = initialData.description;
  late final String? author = initialData.author;
  late final int? viewCount = initialData.viewCount;
  late final int? videoCount = initialData.videoCount;

  PlaylistPage.id(this.playlistId, _InitialData initialData,
      [this._visitorData])
      : super.fromInitialData(initialData);

  PlaylistPage.parse(String raw, this.playlistId)
      : _visitorData = null,
        super(parser.parse(raw), (root) => _InitialData(root));

  Future<PlaylistPage?> nextPage(YoutubeHttpClient httpClient) async {
    final token = initialData.continuationToken;
    if (token == null || token.isEmpty) return null;

    final data = await httpClient.sendContinuation('browse', token, headers: {
      'x-youtube-client-name': '1',
      'x-goog-visitor-id': _visitorData ?? '',
    });

    final newInitialData = _InitialData(data);
    // Guard against infinite loops with a stuck token.
    if (newInitialData.continuationToken == token) return null;

    return PlaylistPage.id(playlistId, newInitialData, _visitorData);
  }

  static Future<PlaylistPage> get(YoutubeHttpClient httpClient, String id) {
    final url = 'https://www.youtube.com/playlist?list=$id&hl=en&persist_hl=1';
    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      final page = PlaylistPage.parse(raw, id);
      if (page.initialData.exists && page.videos.isNotEmpty) return page;

      // Fallback: fetch via the browse API. Needed for Mixes and YT Music playlists
      // whose initial HTML page doesn't embed the video list.
      try {
        final data = await httpClient.sendPost('browse', {
          'browseId': page.initialData.browseId ?? id,
        }, headers: {
          'x-youtube-client-name': '1',
          'x-goog-visitor-id': page.initialData.visitorData ?? '',
        });
        final browsePage = PlaylistPage.id(
            id, _InitialData(data), page.initialData.visitorData);
        if (browsePage.videos.isNotEmpty) return browsePage;
      } catch (_) {
        // Browse failed — fall through and return what we have.
      }
      return page;
    });
  }
}

class _InitialData extends InitialData {
  _InitialData(super.root);

  String? get visitorData => root.getJson<String>(
      'responseContext/webResponseContextExtensionData/ytConfigData/visitorData');

  String? get browseId {
    final params =
        root.getJson<List<dynamic>>('responseContext/serviceTrackingParams');
    final gfeedback = params
        ?.firstWhereOrNull((e) => e['service'] == 'GFEEDBACK') as JsonMap?;
    final paramList = gfeedback?.getJson<List<dynamic>>('params');
    return (paramList?.firstWhereOrNull((e) => e['key'] == 'browse_id')
            as JsonMap?)
        ?.getT<String>('value');
  }

  bool get exists =>
      root.getJson<String>('alerts/0/alertRenderer/type') != 'ERROR';

  late final String? title =
      root.getJson<String>('metadata/playlistMetadataRenderer/title');

  late final String? description =
      root.getJson<String>('metadata/playlistMetadataRenderer/description');

  late final String? author = (root
          .getJson<List<dynamic>>('sidebar/playlistSidebarRenderer/items')
          ?.elementAtSafe(1) as JsonMap?)
      ?.getJson<List<dynamic>>(
        'playlistSidebarSecondaryInfoRenderer/videoOwner/videoOwnerRenderer/title/runs',
      )
      ?.cast<Map<dynamic, dynamic>>()
      .parseRuns();

  late final int? viewCount = ((root
              .getJson<List<dynamic>>('sidebar/playlistSidebarRenderer/items')
              ?.firstOrNull as JsonMap?)
          ?.getJson<List<dynamic>>('playlistSidebarPrimaryInfoRenderer/stats')
          ?.elementAtSafe(1) as JsonMap?)
      ?.getJson<String>('simpleText')
      .parseInt();

  late final int? videoCount = () {
    final stats = (root
                .getJson<List<dynamic>>('sidebar/playlistSidebarRenderer/items')
                ?.firstWhereOrNull(
                    (e) => e['playlistSidebarPrimaryInfoRenderer'] != null)
            as JsonMap?)
        ?.getJson<List<dynamic>>('playlistSidebarPrimaryInfoRenderer/stats');
    if (stats == null) return null;

    for (final stat in stats.cast<JsonMap>()) {
      final text = stat.getJson<String>('runs/0/text');
      final suffix = stat.getJson<String>('runs/1/text');
      if (text != null && suffix != null && suffix.contains('video')) {
        return text.parseInt();
      }
    }
    // Fallback: use the first stat if none was labelled "video".
    final first = stats.firstOrNull;
    return first is Map
        ? (first as JsonMap).getJson<String>('runs/0/text').parseInt()
        : null;
  }();

  String? get continuationToken {
    final items = _videoItems;
    if (items == null) return null;

    final endpoint = items
        .firstWhereOrNull((e) => e['continuationItemRenderer'] != null)
        ?.getJson<JsonMap>('continuationItemRenderer/continuationEndpoint');
    if (endpoint == null) return null;

    // Direct token.
    final token = endpoint.getJson<String>('continuationCommand/token');
    if (token != null) return token;

    // Some responses nest the token inside a commandExecutorCommand.
    return endpoint
        .getJson<List<dynamic>>('commandExecutorCommand/commands')
        ?.cast<JsonMap>()
        .map((c) => c.getJson<String>('continuationCommand/token'))
        .nonNulls
        .firstOrNull;
  }

  /// The flat list of items (videos + continuation marker) for the current page.
  /// Handles both continuation responses and initial page loads.
  List<JsonMap>? get _videoItems {
    // Continuation responses arrive under onResponseReceivedActions/Commands.
    final actions = root.getJson<List<dynamic>>('onResponseReceivedActions') ??
        root.getJson<List<dynamic>>('onResponseReceivedCommands');
    if (actions != null) {
      for (final action in actions.cast<JsonMap>()) {
        final items = action.getJson<List<dynamic>>(
                'appendContinuationItemsAction/continuationItems') ??
            action.getJson<List<dynamic>>(
                'reloadContinuationItemsCommand/continuationItems');
        if (items != null) return items.cast<JsonMap>();
      }
    }

    // Initial page: tabs → sectionList → itemSection → playlistVideoListRenderer.
    final tabs = root
        .getJson<List<dynamic>>('contents/twoColumnBrowseResultsRenderer/tabs');
    if (tabs == null) return null;

    for (final tab in tabs.cast<JsonMap>()) {
      final sections = tab.getJson<List<dynamic>>(
          'tabRenderer/content/sectionListRenderer/contents');
      if (sections == null) continue;

      for (final section in sections.cast<JsonMap>()) {
        final itemContents =
            section.getJson<List<dynamic>>('itemSectionRenderer/contents');
        if (itemContents == null) continue;

        for (final item in itemContents.cast<JsonMap>()) {
          final contents =
              item.getJson<List<dynamic>>('playlistVideoListRenderer/contents');
          if (contents != null) return contents.cast<JsonMap>();
        }
      }
    }
    return null;
  }

  List<_Video> get playlistVideos {
    final items = _videoItems;
    if (items == null) return const [];

    return items
        .map((item) =>
            item['playlistVideoRenderer'] as JsonMap? ??
            item['richItemRenderer']?['content']?['playlistVideoRenderer']
                as JsonMap?)
        .nonNulls
        .map(_Video.new)
        .toList();
  }
}

class _Video {
  final JsonMap root;
  _Video(this.root);

  String get id => root.getT<String>('videoId')!;

  String get author =>
      root
          .getJson<List<dynamic>>('ownerText/runs')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns() ??
      root
          .getJson<List<dynamic>>('shortBylineText/runs')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns() ??
      '';

  String get channelId =>
      root.getJson<String>(
          'ownerText/runs/0/navigationEndpoint/browseEndpoint/browseId') ??
      root.getJson<String>(
          'shortBylineText/runs/0/navigationEndpoint/browseEndpoint/browseId') ??
      root.getJson<String>(
          'shortBylineText/runs/0/navigationEndpoint/showDialogCommand/panelLoadingStrategy/inlineContent/dialogViewModel/customContent/listViewModel/listItems/0/listItemViewModel/rendererContext/commandContext/onTap/innertubeCommand/browseEndpoint/browseId') ??
      '';

  String get title =>
      root
          .getJson<List<dynamic>>('title/runs')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns() ??
      '';

  String get description =>
      root
          .getJson<List<dynamic>>('descriptionSnippet')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns() ??
      '';

  Duration? get duration =>
      root.getJson<String>('lengthText/simpleText')?.toDuration();

  int get viewCount =>
      root.getJson<String>('viewCountText/simpleText').parseInt() ??
      _videoInfo?.split('•').elementAtSafe(0)?.stripNonDigits().parseInt() ??
      0;

  String? get uploadDateRaw => _videoInfo?.split('•').elementAtSafe(1);

  String? get _videoInfo => root
      .getJson<List<dynamic>>('videoInfo/runs')
      ?.cast<Map<dynamic, dynamic>>()
      .parseRuns();
}
