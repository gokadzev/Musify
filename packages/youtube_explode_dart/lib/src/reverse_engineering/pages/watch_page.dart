import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import '../../../youtube_explode_dart.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';
import '../player/player_response.dart';
import 'player_config_base.dart';

///
class WatchPage extends YoutubePage<WatchPageInitialData> {
  final VideoId videoId;

  static final RegExp _videoLikeExp =
      RegExp(r'"label"\s*:\s*"([\d,\.]+) likes"');
  static final RegExp _videoDislikeExp =
      RegExp(r'"label"\s*:\s*"([\d,\.]+) dislikes"');

  @override
  // Overridden to be non-nullable.
  // ignore: overridden_fields
  final Document root;

  /// Cookies linked to this webpage
  final Map<String, String> cookies;

  String get cookieString =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  ///
  String? get sourceUrl {
    final url = root
        .querySelectorAll('script')
        .map((e) => e.attributes['src'])
        .nonNulls
        .firstWhereOrNull((e) =>
            (e.contains('player_ias') || e.contains('player_es6')) &&
            e.endsWith('.js'));
    if (url == null) {
      return null;
    }
    return 'https://youtube.com$url';
  }

  ///
  bool get isOk => root.body?.querySelector('#player') != null;

  ///
  bool get isVideoAvailable =>
      root.querySelector('meta[property="og:url"]') != null;

  ///
  int get videoLikeCount =>
      initialData.likesCount ??
      int.parse(
        _videoLikeExp
                .firstMatch(root.outerHtml)
                ?.group(1)
                ?.stripNonDigits()
                .nullIfWhitespace ??
            root
                .querySelector('.like-button-renderer-like-button')
                ?.text
                .stripNonDigits()
                .nullIfWhitespace ??
            '0',
      );

  ///
  int get videoDislikeCount =>
      initialData.disLikesCount ??
      int.parse(
        _videoDislikeExp
                .firstMatch(root.outerHtml)
                ?.group(1)
                ?.stripNonDigits()
                .nullIfWhitespace ??
            root
                .querySelector('.like-button-renderer-dislike-button')
                ?.text
                .stripNonDigits()
                .nullIfWhitespace ??
            '0',
      );

  static final _playerConfigExp = RegExp(r'ytplayer\.config\s*=\s*(\{.*\})');

  late final WatchPlayerConfig? playerConfig = getPlayerConfig();

  late final PlayerResponse? playerResponse = getInitialPlayerResponse();

  late final Map<String, dynamic> ytCfg = _getYtCfg();

  Map<String, dynamic> _getYtCfg() {
    return json.decode(RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;')
        .firstMatch(root.outerHtml)!
        .group(1)!);
  }

  ///
  WatchPlayerConfig? getPlayerConfig() {
    final jsonMap = _playerConfigExp
        .firstMatch(root.getElementsByTagName('html').first.text)
        ?.group(1)
        ?.extractJson();
    if (jsonMap == null) {
      return null;
    }
    return WatchPlayerConfig(jsonMap);
  }

  PlayerResponse? getInitialPlayerResponse() {
    final scriptText = root
        .querySelectorAll('script')
        .map((e) => e.text)
        .toList(growable: false);
    //TODO: Implement player response extraction from PlayerConfig if extracting from the script fails.
    return scriptText.extractGenericData(
      ['var ytInitialPlayerResponse = '],
      (root) => PlayerResponse(root),
      () => TransientFailureException(
        'Failed to retrieve initial player response, please report this to the project GitHub page.',
      ),
    );
  }

  ///
  WatchPage.parse(String raw, this.videoId, this.cookies)
      : root = parser.parse(raw),
        super(parser.parse(raw), (root) => WatchPageInitialData(root));

  ///
  static Future<WatchPage> get(YoutubeHttpClient httpClient, String videoId) {
    final url = Uri.parse(
      'https://www.youtube.com/watch?v=$videoId&bpctr=9999999999&has_verified=1&hl=en',
    );
    const defaultCookies = 'PREF=hl=en&tz=UTC; SOCS=CAI; GPS=1';
    const headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-us,en;q=0.5',
      'Sec-Fetch-Mode': 'navigate',
      'Cookie': defaultCookies,
    };

    final cookiesExp = RegExp(r'(?:^|,)(\w.+?)=(.*?);');

    return retry(httpClient, () async {
      final req = await httpClient.get(url, headers: headers, validate: true);

      final cookieHeader = req.headers['set-cookie']!;
      final matches = cookiesExp.allMatches(cookieHeader);
      final cookies = Map.fromEntries(
          matches.map((e) => MapEntry(e.group(1)!, e.group(2)!)))
        ..addAll({'PREF': 'hl=en', 'SOCS': 'CAI', 'GPS': '1'});

      final result = WatchPage.parse(req.body, VideoId(videoId), cookies);

      if (!result.isOk) {
        throw TransientFailureException('Video watch page is broken.');
      }

      if (!result.isVideoAvailable) {
        throw VideoUnavailableException.unavailable(VideoId(videoId));
      }
      return result;
    });
  }
}

/// Used internally
class WatchPlayerConfig implements PlayerConfigBase {
  @override
  final JsonMap root;

  ///
  WatchPlayerConfig(this.root);

  @override
  late final String sourceUrl =
      'https://youtube.com${root.get('assets')!.getT<String>('js')}';

  ///
  late final PlayerResponse playerResponse =
      PlayerResponse.parse(root.get('args')!.getT<String>('playerResponse')!);
}

class WatchPageInitialData extends InitialData {
  WatchPageInitialData(super.root);

  late final int? likesCount = _getLikes();
  late final int? disLikesCount = _getDislikes();

  int? _getLikes() {
    if (root['contents'] != null) {
      final topLevelButtons = root
          .get('contents')
          ?.get('twoColumnWatchNextResults')
          ?.get('results')
          ?.get('results')
          ?.getList('contents')
          ?.firstWhereOrNull((e) => e['videoPrimaryInfoRenderer'] != null)
          ?.get('videoPrimaryInfoRenderer')
          ?.get('videoActions')
          ?.get('menuRenderer')
          ?.getList('topLevelButtons');

      if (topLevelButtons == null) {
        return null;
      }

      final likes = topLevelButtons
              .elementAtOrNull(0)
              ?.get('segmentedLikeDislikeButtonViewModel')
              ?.get('likeButtonViewModel')
              ?.get('likeButtonViewModel')
              ?.get('toggleButtonViewModel')
              ?.get('toggleButtonViewModel')
              ?.get('defaultButtonViewModel')
              ?.get('buttonViewModel')
              ?.getT<String>('accessibilityText') ??
          topLevelButtons
              .firstWhereOrNull((e) => e['toggleButtonRenderer'] != null)
              ?.get('toggleButtonRenderer')
              ?.get('defaultText')
              ?.get('accessibility')
              ?.get('accessibilityData')
              ?.getT<String>('label');

      return likes.parseInt();
    }
    return null;
  }

  int? _getDislikes() {
    if (root['contents'] != null) {
      final likes = root
          .get('contents')
          ?.get('twoColumnWatchNextResults')
          ?.get('results')
          ?.get('results')
          ?.getList('contents')
          ?.firstWhereOrNull((e) => e['videoPrimaryInfoRenderer'] != null)
          ?.get('videoPrimaryInfoRenderer')
          ?.get('videoActions')
          ?.get('menuRenderer')
          ?.getList('topLevelButtons')
          ?.where((e) => e['toggleButtonRenderer'] != null)
          .elementAtSafe(1)
          ?.get('toggleButtonRenderer')
          ?.get('defaultText')
          ?.get('accessibility')
          ?.get('accessibilityData')
          ?.getT<String>('label');

      return likes.parseInt();
    }
    return null;
  }

  List<MusicData>? getMusicData() {
    return root
        .getList('engagementPanels')
        ?.firstWhereOrNull((e) =>
            e['engagementPanelSectionListRenderer'] != null &&
            e['engagementPanelSectionListRenderer']['panelIdentifier'] ==
                'engagement-panel-structured-description')
        ?.get('engagementPanelSectionListRenderer')
        ?.get('content')
        ?.get('structuredDescriptionContentRenderer')
        ?.getList('items')
        ?.firstWhereOrNull((e) => e['horizontalCardListRenderer'] != null)
        ?.get('horizontalCardListRenderer')
        ?.getList('cards')
        ?.map((e) => e.get('videoAttributeViewModel'))
        .nonNulls
        .map((e) => (
              song: e.getT<String>('title'),
              artist: e.getT<String>('subtitle'),
              album: e.getJson<String>('secondarySubtitle/content'),
              image: e.getJson<String>('image/sources/0/url')?.toUri()
            ))
        .toList();
  }
}
