import 'package:collection/collection.dart';
import 'package:html/parser.dart' as parser;

import '../../../youtube_explode_dart.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';

///
class ChannelAboutPage extends YoutubePage<_InitialData> {
  ///
  String? get description => initialData.description;

  ///
  int? get viewCount => initialData.viewCount;

  ///
  String? get joinDate => initialData.joinDate;

  ///
  String get title => initialData.title;

  ///
  List<JsonMap> get avatar => initialData.avatar;

  ///
  String? get country => initialData.country;

  ///
  List<ChannelLink> get channelLinks => initialData.channelLinks;

  ///
  ChannelAboutPage.parse(String raw)
      : super(parser.parse(raw), (root) => _InitialData(root));

  ///
  static Future<ChannelAboutPage> get(YoutubeHttpClient httpClient, String id) {
    final url = 'https://www.youtube.com/channel/$id/about?hl=en';

    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      final result = ChannelAboutPage.parse(raw);

      return result;
    });
  }

  ///
  static Future<ChannelAboutPage> getByUsername(
    YoutubeHttpClient httpClient,
    String username,
  ) {
    final url = 'https://www.youtube.com/user/$username/about?hl=en';

    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      final result = ChannelAboutPage.parse(raw);

      return result;
    });
  }
}

final _urlExp = RegExp(r'q=([^=]*)$');

class _InitialData extends InitialData {
  late final JsonMap content = _getContentContext();

  _InitialData(super.root);

  JsonMap _getContentContext() {
    final tabs = root.getJson<List<dynamic>>(
        'contents/twoColumnBrowseResultsRenderer/tabs')!;
    final tabWithContent =
        tabs.firstWhere((e) => e['tabRenderer']?['content'] != null) as JsonMap;
    final sectionContents = tabWithContent
        .getJson<JsonMap>('tabRenderer/content/sectionListRenderer')!
        .getJson<List<dynamic>>('contents')!;
    final firstSection = sectionContents.firstOrNull! as JsonMap;
    final itemContents =
        firstSection.getJson<List<dynamic>>('itemSectionRenderer/contents')!;
    final firstItem = itemContents.firstOrNull! as JsonMap;
    return firstItem.getJson<JsonMap>('channelAboutFullMetadataRenderer')!;
  }

  late final String? description =
      content.getJson<String>('description/simpleText');

  late final List<ChannelLink> channelLinks = content
          .getJson<List<dynamic>>('primaryLinks')
          ?.map(
            (e) => ChannelLink(
              (e as JsonMap).getJson<String>('title/simpleText') ?? '',
              extractUrl(
                (e).getJson<String>(
                      'navigationEndpoint/commandMetadata/webCommandMetadata/url',
                    ) ??
                    (e).getJson<String>(
                      'navigationEndpoint/urlEndpoint/url',
                    ) ??
                    '',
              ),
              Uri.parse(
                ((e).getJson<List<dynamic>>('icon/thumbnails')?.firstOrNull
                            as JsonMap?)
                        ?.getT<String>('url') ??
                    '',
              ),
            ),
          )
          .toList() ??
      content
          .getJson<List<dynamic>>('links')
          ?.map((e) => e['channelExternalLinkViewModel'])
          .nonNulls
          .cast<Map<String, dynamic>>()
          .map((e) {
        return ChannelLink(
          e.getJson<String>('title/content') ?? '',
          Uri.parse('https://${e.getJson<String>('link/content')!}'),
          // Youtube doesn't provide icons anymore.
          Uri(),
        );
      }).toList() ??
      [];

  late final int? viewCount =
      content.getJson<String>('viewCountText/simpleText').parseInt();

  late final String? joinDate = content
      .getJson<List<dynamic>>('joinedDateText/runs')?[1]
      .getT<String>('text');

  late final String title = content.getJson<String>('title/simpleText')!;

  late final List<JsonMap> avatar =
      content.getJson<List<dynamic>>('avatar/thumbnails')!.cast<JsonMap>();

  late final String? country = content.getJson<String>('country/simpleText');

  Uri extractUrl(String text) =>
      Uri.parse(Uri.decodeFull(_urlExp.firstMatch(text)?.group(1) ?? ''));
}
