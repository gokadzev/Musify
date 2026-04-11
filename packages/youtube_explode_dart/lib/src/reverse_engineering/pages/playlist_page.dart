import 'package:collection/collection.dart';
import 'package:html/parser.dart' as parser;

import '../../../youtube_explode_dart.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';
import '../youtube_http_client.dart';

///
class PlaylistPage extends YoutubePage<_InitialData> {
  ///
  final String playlistId;

  final String? _visitorData;

  late final List<_Video> videos = initialData.playlistVideos;

  late final String? title = initialData.title;

  late final String? description = initialData.description;

  late final String? author = initialData.author;

  late final int? viewCount = initialData.viewCount;

  late final int? videoCount = initialData.videoCount;

  /// InitialData
  PlaylistPage.id(this.playlistId, _InitialData initialData,
      [this._visitorData])
      : super.fromInitialData(initialData);

  ///
  Future<PlaylistPage?> nextPage(YoutubeHttpClient httpClient) async {
    if (initialData.continuationToken?.isEmpty ?? true) {
      return null;
    }

    final data = await httpClient.sendContinuation(
        'browse', initialData.continuationToken!, headers: {
      'x-youtube-client-name': '1',
      'x-goog-visitor-id': _visitorData ?? ''
    });
    final newInitialData = _InitialData(data);
    if (newInitialData.continuationToken != null &&
        newInitialData.continuationToken == initialData.continuationToken) {
      // Avoid sending always the same request.
      return null;
    }

    return PlaylistPage.id(playlistId, _InitialData(data), _visitorData);
  }

  ///
  static Future<PlaylistPage> get(
    YoutubeHttpClient httpClient,
    String id,
  ) async {
    final url = 'https://www.youtube.com/playlist?list=$id&hl=en&persist_hl=1';
    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      final page = PlaylistPage.parse(raw, id);
      if (page.initialData.exists) {
        return page;
      }

      // Try to fetch using the browse API
      final data = await httpClient.sendPost('browse', {
        'browseId': page.initialData.browseId!,
      }, headers: {
        'x-youtube-client-name': '1',
        'x-goog-visitor-id': page.initialData.visitorData ?? '',
      });
      return PlaylistPage.id(
          id, _InitialData(data), page.initialData.visitorData);
    });
  }

  ///
  PlaylistPage.parse(String raw, this.playlistId)
      : _visitorData = null,
        super(parser.parse(raw), (root) => _InitialData(root));
}

class _InitialData extends InitialData {
  _InitialData(super.root);

  String? get visitorData => root
      .get('responseContext')
      ?.get('webResponseContextExtensionData')
      ?.get('ytConfigData')
      ?.getT<String>('visitorData');

  String? get browseId => root
      .get('responseContext')
      ?.getList('serviceTrackingParams')
      ?.firstWhereOrNull((e) => e['service'] == 'GFEEDBACK')
      ?.getList('params')
      ?.firstWhereOrNull((e) => e['key'] == 'browse_id')
      ?.getT<String>('value');

  bool get exists =>
      root
          .getList('alerts')
          ?.firstOrNull
          ?.get('alertRenderer')
          ?.getT<String>('type') !=
      'ERROR';

  late final String? title = root
      .get('metadata')
      ?.get('playlistMetadataRenderer')
      ?.getT<String>('title');

  late final String? author = root
      .get('sidebar')
      ?.get('playlistSidebarRenderer')
      ?.getList('items')
      ?.elementAtSafe(1)
      ?.get('playlistSidebarSecondaryInfoRenderer')
      ?.get('videoOwner')
      ?.get('videoOwnerRenderer')
      ?.get('title')
      ?.getT<List<dynamic>>('runs')
      ?.cast<Map<dynamic, dynamic>>()
      .parseRuns();

  late final String? description = root
      .get('metadata')
      ?.get('playlistMetadataRenderer')
      ?.getT<String>('description');

  late final int? viewCount = root
      .get('sidebar')
      ?.get('playlistSidebarRenderer')
      ?.getList('items')
      ?.firstOrNull
      ?.get('playlistSidebarPrimaryInfoRenderer')
      ?.getList('stats')
      ?.elementAtSafe(1)
      ?.getT<String>('simpleText')
      .parseInt();

  // sidebar.playlistSidebarRenderer.items[0].playlistSidebarPrimaryInfoRenderer.stats
  late final int? videoCount = root
      .get('sidebar')
      ?.get('playlistSidebarRenderer')
      ?.getList('items')
      ?.firstOrNull
      ?.get('playlistSidebarPrimaryInfoRenderer')
      ?.getList('stats')
      ?.elementAtSafe(0)
      ?.getList('runs')
      ?.firstOrNull
      ?.getT<String>('text')
      .parseInt();

  String? get continuationToken {
    final continuationEndpoint = (videosContent ?? playlistVideosContent)
        ?.firstWhereOrNull((e) => e['continuationItemRenderer'] != null)
        ?.get('continuationItemRenderer')
        ?.get('continuationEndpoint');

    return continuationEndpoint
            ?.get('continuationCommand')
            ?.getT<String>('token') ??
        continuationEndpoint
            ?.get('commandExecutorCommand')
            ?.getList('commands')
            ?.firstWhereOrNull((e) => e['continuationCommand'] != null)
            ?.get('continuationCommand')
            ?.getT<String>('token');
  }

  List<JsonMap>? get playlistVideosContent =>
      root
          .getList('onResponseReceivedActions')
          ?.firstOrNull
          ?.get('appendContinuationItemsAction')
          ?.getList('continuationItems') ??
      root
          .get('contents')
          ?.get('twoColumnBrowseResultsRenderer')
          ?.getList('tabs')
          ?.firstOrNull
          ?.get('tabRenderer')
          ?.get('content')
          ?.get('sectionListRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('itemSectionRenderer')
          ?.getList('contents')
          ?.firstOrNull
          ?.get('playlistVideoListRenderer')
          ?.getList('contents');

  late final List<JsonMap>? videosContent = root
          .get('contents')
          ?.get('twoColumnSearchResultsRenderer')
          ?.get('primaryContents')
          ?.get('sectionListRenderer')
          ?.getList('contents') ??
      root
          .getList('onResponseReceivedCommands')
          ?.firstOrNull
          ?.get('appendContinuationItemsAction')
          ?.getList('continuationItems');

  List<_Video> get playlistVideos =>
      playlistVideosContent
          ?.where((e) => e['playlistVideoRenderer'] != null)
          .map((e) => _Video(e['playlistVideoRenderer']))
          .toList() ??
      const [];

/*  List<_Video> get videos =>
      videosContent?.firstOrNull
          ?.get('itemSectionRenderer')
          ?.getList('contents')
          ?.where((e) => e['videoRenderer'] != null)
          .map((e) => _Video(e))
          .toList() ??
      const [];*/
}

class _Video {
  // Json parsed map
  final JsonMap root;

  _Video(this.root);

  String get id => root.getT<String>('videoId')!;

  String get author =>
      root
          .get('ownerText')
          ?.getT<List<dynamic>>('runs')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns() ??
      root
          .get('shortBylineText')
          ?.getT<List<dynamic>>('runs')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns() ??
      '';

  String get channelId {
    return root
            .get('ownerText')
            ?.getList('runs')
            ?.firstOrNull
            ?.get('navigationEndpoint')
            ?.get('browseEndpoint')
            ?.getT<String>('browseId') ??
        root
            .get('shortBylineText')
            ?.getList('runs')
            ?.firstOrNull
            ?.get('navigationEndpoint')
            ?.get('browseEndpoint')
            ?.getT<String>('browseId') ??
        root
            .get('shortBylineText')
            ?.getList('runs')
            ?.firstOrNull
            ?.get('navigationEndpoint')
            ?.get('showDialogCommand')
            ?.get('panelLoadingStrategy')
            ?.get('inlineContent')
            ?.get('dialogViewModel')
            ?.get('customContent')
            ?.get('listViewModel')
            ?.getList('listItems')
            ?.firstOrNull
            ?.get('listItemViewModel')
            ?.get('rendererContext')
            ?.get('commandContext')
            ?.get('onTap')
            ?.get('innertubeCommand')
            ?.get('browseEndpoint')
            ?.getT<String>('browseId') ??
        '';
  }

  String get title => root.get('title')?.getList('runs')?.parseRuns() ?? '';

  String get description =>
      root.getList('descriptionSnippet')?.parseRuns() ?? '';

  Duration? get duration =>
      root.get('lengthText')?.getT<String>('simpleText')?.toDuration();

  int get viewCount =>
      root.get('viewCountText')?.getT<String>('simpleText').parseInt() ??
      _videoInfo?.split('•').elementAtSafe(0)?.stripNonDigits().parseInt() ??
      0;

  String? get uploadDateRaw => _videoInfo?.split('•').elementAtSafe(1);

  String? get _videoInfo => root
      .get('videoInfo')
      ?.getT<List<dynamic>>('runs')!
      .cast<Map<dynamic, dynamic>>()
      .parseRuns();
}
