import 'package:collection/collection.dart';
import 'package:html/parser.dart' as parser;

import '../../../youtube_explode_dart.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';
import '../youtube_http_client.dart';

// The WEB client stops issuing continuation tokens after ~200 videos; WEB_REMIX does not.
const _musicContext = {
  'client': {
    'clientName': 'WEB_REMIX',
    'clientVersion': '1.20250922.03.00',
    'hl': 'en',
    'gl': 'US',
  },
};

class PlaylistPage extends YoutubePage<_InitialData> {
  final String playlistId;
  final String? _visitorData;
  final bool _useMusicClient;

  late final List<_Video> videos = initialData.playlistVideos;
  late final String? title = initialData.title;
  late final String? description = initialData.description;
  late final String? author = initialData.author;
  late final int? viewCount = initialData.viewCount;
  late final int? videoCount = initialData.videoCount;

  PlaylistPage.id(this.playlistId, _InitialData initialData,
      [this._visitorData, this._useMusicClient = false])
      : super.fromInitialData(initialData);

  PlaylistPage.parse(String raw, this.playlistId)
      : _visitorData = null,
        _useMusicClient = false,
        super(parser.parse(raw), (root) => _InitialData(root));

  Future<PlaylistPage?> nextPage(YoutubeHttpClient httpClient) async {
    final token = initialData.continuationToken;
    if (token == null || token.isEmpty) return null;

    final data = _useMusicClient
        ? await httpClient.sendPost('browse', {
            'context': _musicContext,
            'continuation': token,
          })
        : await httpClient.sendContinuation('browse', token, headers: {
            'x-youtube-client-name': '1',
            'x-goog-visitor-id': _visitorData ?? '',
          });

    final newInitialData = _InitialData(data);
    // Guard against infinite loops with a stuck token.
    if (newInitialData.continuationToken == token) return null;

    return PlaylistPage.id(
        playlistId, newInitialData, _visitorData, _useMusicClient);
  }

  /// Fetches the first page through the WEB_REMIX client, whose pagination is not capped.
  static Future<PlaylistPage> getViaMusicClient(
      YoutubeHttpClient httpClient, String id) {
    return retry(httpClient, () async {
      final data = await httpClient.sendPost('browse', {
        'context': _musicContext,
        'browseId': id.startsWith('VL') ? id : 'VL$id',
      });
      return PlaylistPage.id(id, _InitialData(data), null, true);
    });
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

    // Classic shape: continuationItemRenderer.
    final rendererItem =
        items.firstWhereOrNull((e) => e['continuationItemRenderer'] != null);
    if (rendererItem != null) {
      final endpoint = rendererItem
          .getJson<JsonMap>('continuationItemRenderer/continuationEndpoint');
      if (endpoint != null) {
        // Direct token.
        final token = endpoint.getJson<String>('continuationCommand/token');
        if (token != null) return token;

        // Some responses nest the token inside a commandExecutorCommand.
        final nested = endpoint
            .getJson<List<dynamic>>('commandExecutorCommand/commands')
            ?.cast<JsonMap>()
            .map((c) => c.getJson<String>('continuationCommand/token'))
            .nonNulls
            .firstOrNull;
        if (nested != null) return nested;
      }
    }

    // Newer shape: continuationItemViewModel (seen alongside lockupViewModel
    // rows). Token sits under continuationCommand -> innertubeCommand ->
    // continuationCommand -> token (yes, doubly nested).
    final viewModelItem =
        items.firstWhereOrNull((e) => e['continuationItemViewModel'] != null);
    if (viewModelItem != null) {
      final token = viewModelItem.getJson<String>(
          'continuationItemViewModel/continuationCommand/innertubeCommand/continuationCommand/token');
      if (token != null) return token;

      // Defensive fallback in case the double-nesting isn't present.
      return viewModelItem.getJson<String>(
          'continuationItemViewModel/continuationCommand/token');
    }

    return null;
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

    // Music client: the rows sit in a musicPlaylistShelfRenderer.
    final musicSections = root.getJson<List<dynamic>>(
        'contents/twoColumnBrowseResultsRenderer/secondaryContents/sectionListRenderer/contents');
    for (final section in musicSections?.cast<JsonMap>() ?? const <JsonMap>[]) {
      final contents =
          section.getJson<List<dynamic>>('musicPlaylistShelfRenderer/contents');
      if (contents != null) return contents.cast<JsonMap>();
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

        // Newer layout: the videos sit directly in itemSectionRenderer/contents
        // as lockupViewModel entries, with no playlistVideoListRenderer wrapper
        // at all. Confirmed against live playlists on 2026-09-27 (see
        // https://github.com/OrionZ43/youtube_explode_dart/commit/cf8f881).
        if (itemContents.any((e) =>
            e is Map &&
            (e.containsKey('lockupViewModel') ||
                e.containsKey('continuationItemRenderer')))) {
          return itemContents.cast<JsonMap>();
        }
      }
    }
    return null;
  }

  List<_Video> get playlistVideos {
    final items = _videoItems;
    if (items == null) return const [];

    final result = <_Video>[];
    for (final item in items) {
      final renderer = item['playlistVideoRenderer'] as JsonMap? ??
          item['richItemRenderer']?['content']?['playlistVideoRenderer']
              as JsonMap?;
      if (renderer != null) {
        result.add(_RendererVideo(renderer));
        continue;
      }

      // YouTube moved playlist rows (both on the initial page and on
      // continuation/pagination requests) to a component-based
      // `lockupViewModel` layout. Playlists also list channels and other
      // playlists this way, so only keep entries that are actually videos.
      final lockup = item['lockupViewModel'] as JsonMap?;
      if (lockup != null &&
          lockup['contentType'] == 'LOCKUP_CONTENT_TYPE_VIDEO') {
        result.add(_LockupVideo(lockup));
        continue;
      }

      final musicRow = item['musicResponsiveListItemRenderer'] as JsonMap?;
      if (musicRow != null) {
        final video = _MusicVideo(musicRow);
        // Rows for unavailable tracks carry no video id.
        if (video.id.isNotEmpty) result.add(video);
      }
    }
    return result;
  }
}

/// A single entry of a playlist page, in either of the two layouts YouTube
/// serves: the classic `playlistVideoRenderer` or the newer `lockupViewModel`.
abstract class _Video {
  String get id;
  String get author;
  String get channelId;
  String get title;
  String get description;
  Duration? get duration;
  int get viewCount;
  String? get uploadDateRaw;
}

/// The classic playlist row: `playlistVideoRenderer` (or the same, nested
/// inside `richItemRenderer`).
class _RendererVideo implements _Video {
  final JsonMap root;
  _RendererVideo(this.root);

  @override
  String get id => root.getT<String>('videoId')!;

  @override
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

  @override
  String get channelId =>
      root.getJson<String>(
          'ownerText/runs/0/navigationEndpoint/browseEndpoint/browseId') ??
      root.getJson<String>(
          'shortBylineText/runs/0/navigationEndpoint/browseEndpoint/browseId') ??
      root.getJson<String>(
          'shortBylineText/runs/0/navigationEndpoint/showDialogCommand/panelLoadingStrategy/inlineContent/dialogViewModel/customContent/listViewModel/listItems/0/listItemViewModel/rendererContext/commandContext/onTap/innertubeCommand/browseEndpoint/browseId') ??
      '';

  @override
  String get title =>
      root
          .getJson<List<dynamic>>('title/runs')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns() ??
      '';

  @override
  String get description =>
      root
          .getJson<List<dynamic>>('descriptionSnippet')
          ?.cast<Map<dynamic, dynamic>>()
          .parseRuns() ??
      '';

  @override
  Duration? get duration =>
      root.getJson<String>('lengthText/simpleText')?.toDuration();

  @override
  int get viewCount =>
      root.getJson<String>('viewCountText/simpleText').parseInt() ??
      _videoInfo?.split('•').elementAtSafe(0)?.stripNonDigits().parseInt() ??
      0;

  @override
  String? get uploadDateRaw => _videoInfo?.split('•').elementAtSafe(1);

  String? get _videoInfo => root
      .getJson<List<dynamic>>('videoInfo/runs')
      ?.cast<Map<dynamic, dynamic>>()
      .parseRuns();
}

/// The layout YouTube moved playlists to: every entry is a `lockupViewModel`
/// with a flat `contentId` and a `lockupMetadataViewModel` for the text.
class _LockupVideo implements _Video {
  final JsonMap root;
  _LockupVideo(this.root);

  JsonMap? get _metadata =>
      root.getJson<JsonMap>('metadata/lockupMetadataViewModel');

  @override
  String get id => root.getT<String>('contentId') ?? '';

  @override
  String get title =>
      _metadata?.getJson<String>('title/content') ??
      root.getJson<String>('metadata/lockupMetadataViewModel/title/content') ??
      '';

  /// The channel name is the first metadata row under the title.
  @override
  String get author =>
      _metadata?.getJson<String>(
          'metadata/contentMetadataViewModel/metadataRows/0/metadataParts/0/text/content') ??
      '';

  @override
  String get channelId =>
      _metadata?.getJson<String>('image/decoratedAvatarViewModel/avatar/avatarViewModel/rendererContext/commandContext/onTap/innertubeCommand/browseEndpoint/browseId') ??
      _metadata?.getJson<String>(
          'image/decoratedAvatarViewModel/rendererContext/commandContext/onTap/innertubeCommand/browseEndpoint/browseId') ??
      _metadata?.getJson<String>(
          'metadata/contentMetadataViewModel/metadataRows/0/metadataParts/0/text/commandRuns/0/onTap/innertubeCommand/browseEndpoint/browseId') ??
      '';

  @override
  String get description => '';

  /// Duration lives in the badge drawn over the thumbnail ("4:20").
  @override
  Duration? get duration {
    final overlays =
        root.getJson<List<dynamic>>('contentImage/thumbnailViewModel/overlays');
    if (overlays == null) return null;
    for (final overlay in overlays.cast<JsonMap>()) {
      final badges = overlay
          .getJson<List<dynamic>>('thumbnailBottomOverlayViewModel/badges');
      if (badges == null) continue;
      for (final badge in badges.cast<JsonMap>()) {
        final text = badge.getJson<String>('thumbnailBadgeViewModel/text');
        final parsed = text?.toDuration();
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Not served in this layout.
  @override
  int get viewCount => 0;

  @override
  String? get uploadDateRaw => null;
}

/// A row of the WEB_REMIX layout: `musicResponsiveListItemRenderer`.
class _MusicVideo implements _Video {
  final JsonMap root;
  _MusicVideo(this.root);

  List<Map<dynamic, dynamic>> _runs(int column) =>
      root
          .getJson<List<dynamic>>(
              'flexColumns/$column/musicResponsiveListItemFlexColumnRenderer/text/runs')
          ?.cast<Map<dynamic, dynamic>>() ??
      const [];

  @override
  String get id => root.getJson<String>('playlistItemData/videoId') ?? '';

  @override
  String get title => _runs(0).parseRuns();

  @override
  String get author => _runs(1).parseRuns();

  // Tracks without an artist page still need a syntactically valid channel id.
  @override
  String get channelId =>
      root.getJson<String>(
          'flexColumns/1/musicResponsiveListItemFlexColumnRenderer/text/runs/0/navigationEndpoint/browseEndpoint/browseId') ??
      'UC0000000000000000000000';

  @override
  String get description => '';

  @override
  Duration? get duration => root
      .getJson<String>(
          'fixedColumns/0/musicResponsiveListItemFixedColumnRenderer/text/runs/0/text')
      ?.toDuration();

  @override
  int get viewCount => 0;

  @override
  String? get uploadDateRaw => null;
}
