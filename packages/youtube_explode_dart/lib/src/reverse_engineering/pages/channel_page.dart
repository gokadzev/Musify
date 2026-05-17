import 'package:html/parser.dart' as parser;

import '../../exceptions/exceptions.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';
import '../youtube_http_client.dart';

///
class ChannelPage extends YoutubePage<_InitialData> {
  ///
  bool get isOk => root!.querySelector('meta[property="og:url"]') != null;

  ///
  String get channelUrl =>
      root!.querySelector('meta[property="og:url"]')?.attributes['content'] ??
      '';

  ///
  String get channelId => channelUrl.substringAfter('channel/');

  ///
  String get channelTitle =>
      root!.querySelector('meta[property="og:title"]')?.attributes['content'] ??
      '';

  ///
  String get channelLogoUrl =>
      root!.querySelector('meta[property="og:image"]')?.attributes['content'] ??
      '';

  String get channelBannerUrl => initialData.bannerUrl ?? '';

  int? get subscribersCount => initialData.subscribersCount;

  ///
  ChannelPage.parse(String raw)
      : super(parser.parse(raw), (root) => _InitialData(root));

  ///
  static Future<ChannelPage> get(YoutubeHttpClient httpClient, String id) {
    final url = 'https://www.youtube.com/channel/$id?hl=en';

    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      final result = ChannelPage.parse(raw);

      if (!result.isOk) {
        throw TransientFailureException('Channel page is broken');
      }
      return result;
    });
  }

  ///
  static Future<ChannelPage> getByUsername(
    YoutubeHttpClient httpClient,
    String username,
  ) {
    var url = 'https://www.youtube.com/user/$username?hl=en';

    return retry(httpClient, () async {
      try {
        final raw = await httpClient.getString(url);
        final result = ChannelPage.parse(raw);

        if (!result.isOk) {
          throw TransientFailureException('Channel page is broken');
        }
        return result;
      } on FatalFailureException catch (e) {
        if (e.statusCode != 404) {
          rethrow;
        }
        url = 'https://www.youtube.com/c/$username?hl=en';
      }
      throw FatalFailureException('', 0);
    });
  }

  ///
  static Future<ChannelPage> getByHandle(
    YoutubeHttpClient httpClient,
    String handle,
  ) {
    final url = 'https://www.youtube.com/$handle?hl=en';

    return retry(httpClient, () async {
      try {
        final raw = await httpClient.getString(url);
        final result = ChannelPage.parse(raw);

        if (!result.isOk) {
          throw TransientFailureException('Channel page is broken');
        }
        return result;
      } on FatalFailureException catch (e) {
        if (e.statusCode != 404) {
          rethrow;
        }
      }
      throw FatalFailureException('', 0);
    });
  }
}

class _InitialData extends InitialData {
  static final RegExp _subCountExp = RegExp(r'(\d+(?:\.\d+)?)(K|M|\s)');

  _InitialData(super.root);

  int? get subscribersCount {
    final renderer = root.getJson<JsonMap>('header/c4TabbedHeaderRenderer');
    if (renderer?['subscriberCountText'] == null) {
      return null;
    }
    final subText = renderer?.getJson<String>('subscriberCountText/simpleText');
    if (subText == null) {
      return null;
    }
    final match = _subCountExp.firstMatch(subText);
    if (match == null) {
      return null;
    }
    if (match.groupCount != 2) {
      return null;
    }

    final count = double.tryParse(match.group(1) ?? '');
    if (count == null) {
      return null;
    }

    final multiplierText = match.group(2);
    if (multiplierText == null) {
      return null;
    }

    var multiplier = 1;
    if (multiplierText == 'K') {
      multiplier = 1000;
    } else if (multiplierText == 'M') {
      multiplier = 1000000;
    }

    return (count * multiplier).toInt();
  }

  String? get bannerUrl => (root
          .getJson<List<dynamic>>(
            'header/c4TabbedHeaderRenderer/banner/thumbnails',
          )
          ?.first as JsonMap?)
      ?.getT<String>('url');
}
