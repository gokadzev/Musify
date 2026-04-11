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
    return root
        .get('contents')!
        .get('twoColumnBrowseResultsRenderer')!
        .getList('tabs')!
        .firstWhere((e) => e['tabRenderer']?['content'] != null)
        .get('tabRenderer')!
        .get('content')!
        .get('sectionListRenderer')!
        .getList('contents')!
        .firstOrNull!
        .get('itemSectionRenderer')!
        .getList('contents')!
        .firstOrNull!
        .get('channelAboutFullMetadataRenderer')!;
  }

  late final String? description =
      content.get('description')?.getT<String>('simpleText');

  late final List<ChannelLink> channelLinks = content
          .getList('primaryLinks')
          ?.map(
            (e) => ChannelLink(
              e.get('title')?.getT<String>('simpleText') ?? '',
              extractUrl(
                e
                        .get('navigationEndpoint')
                        ?.get('commandMetadata')
                        ?.get('webCommandMetadata')
                        ?.getT<String>('url') ??
                    e
                        .get('navigationEndpoint')
                        ?.get('urlEndpoint')
                        ?.getT<String>('url') ??
                    '',
              ),
              Uri.parse(
                e
                        .get('icon')
                        ?.getList('thumbnails')
                        ?.firstOrNull
                        ?.getT<String>('url') ??
                    '',
              ),
            ),
          )
          .toList() ??
      content
          .getList('links')
          ?.map((e) => e['channelExternalLinkViewModel'])
          .nonNulls
          .cast<Map<String, dynamic>>()
          .map((e) {
        return ChannelLink(
          e.get('title')?.getT<String>('content') ?? '',
          Uri.parse('https://${e.get('link')!.getT<String>('content')!}'),
          // Youtube doesn't provide icons anymore.
          Uri(),
        );
      }).toList() ??
      [];

  late final int? viewCount =
      content.get('viewCountText')?.getT<String>('simpleText').parseInt();

  late final String? joinDate =
      content.get('joinedDateText')?.getList('runs')?[1].getT<String>('text');

  late final String title = content.get('title')!.getT<String>('simpleText')!;

  late final List<JsonMap> avatar =
      content.get('avatar')!.getList('thumbnails')!;

  late final String? country =
      content.get('country')?.getT<String>('simpleText');

  Uri extractUrl(String text) =>
      Uri.parse(Uri.decodeFull(_urlExp.firstMatch(text)?.group(1) ?? ''));
}
