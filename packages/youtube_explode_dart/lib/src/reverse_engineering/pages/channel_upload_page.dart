import 'package:collection/collection.dart';
import 'package:html/parser.dart' as parser;

import '../../channels/channel_video.dart';
import '../../channels/video_type.dart';
import '../../exceptions/exceptions.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../../videos/videos.dart';
import '../models/initial_data.dart';
import '../models/youtube_page.dart';
import '../youtube_http_client.dart';

///
class ChannelUploadPage extends YoutubePage<_InitialData> {
  ///
  final String channelId;

  final VideoType type;

  late final List<ChannelVideo> uploads = initialData.uploads;

  /// InitialData
  ChannelUploadPage.id(this.channelId, this.type, super.initialData)
      : super.fromInitialData();

  ///
  Future<ChannelUploadPage?> nextPage(YoutubeHttpClient httpClient) async {
    if (initialData.token.isEmpty) {
      return null;
    }

    final data = await httpClient.sendContinuation('browse', initialData.token);
    return ChannelUploadPage.id(channelId, type, _InitialData(data, type));
  }

  ///
  static Future<ChannelUploadPage> get(
    YoutubeHttpClient httpClient,
    String channelId,
    String sorting,
    VideoType type,
  ) {
    final url =
        'https://www.youtube.com/channel/$channelId/${type.name}?view=0&sort=$sorting&flow=grid';
    return retry(httpClient, () async {
      final raw = await httpClient.getString(url);
      return ChannelUploadPage.parse(raw, channelId, type);
    });
  }

  ///
  ChannelUploadPage.parse(String raw, this.channelId, this.type)
      : super(parser.parse(raw), (root) => _InitialData(root, type));
}

class _InitialData extends InitialData {
  _InitialData(super.root, this.type);

  final VideoType type;

  late final JsonMap? continuationContext = getContinuationContext();

  late final String token = continuationContext?.getT<String>('token') ??
      continuationContext?.getT<String>('continuation') ??
      '';

  late final List<ChannelVideo> uploads = _getUploads();

  List<ChannelVideo> _getUploads() {
    final content = getContentContext();
    if (content.isEmpty) {
      return const <ChannelVideo>[];
    }
    return content.map(_parseContent).nonNulls.toList();
  }

  List<JsonMap> getContentContext() {
    List<JsonMap>? context;
    if (root.containsKey('contents')) {
      final tabs = root.getJson<List<dynamic>>(
        'contents/twoColumnBrowseResultsRenderer/tabs',
      );
      final selectedTab = tabs
          ?.map((e) => e['tabRenderer'])
          .cast<JsonMap>()
          .firstWhereOrNull((e) => e['selected'] as bool? ?? false);
      var render = selectedTab?.getJson<JsonMap>('content');

      if (render != null) {
        if (render.containsKey('sectionListRenderer')) {
          final sectionContents = render.getJson<List<dynamic>>(
            'sectionListRenderer/contents',
          );
          final firstSection = sectionContents?.firstOrNull as JsonMap?;
          render = firstSection
              ?.getJson<List<dynamic>>(
                'itemSectionRenderer/contents',
              )
              ?.firstOrNull as JsonMap?;

          if (render?.containsKey('gridRenderer') ?? false) {
            context = render
                ?.getJson<List<dynamic>>('gridRenderer/items')
                ?.cast<JsonMap>();
          } else if (render?.containsKey('messageRenderer') ?? false) {
            // Workaround for no-videos.
            context = const [];
          }
        } else if (render.containsKey('richGridRenderer')) {
          context = render
                  .getJson<List<dynamic>>('richGridRenderer/contents')
                  ?.cast<JsonMap>() ??
              const [];
        }
      }
    }
    if (context == null && root.containsKey('onResponseReceivedActions')) {
      final firstAction = root
          .getJson<List<dynamic>>('onResponseReceivedActions')
          ?.firstOrNull as JsonMap?;
      context = firstAction
          ?.getJson<List<dynamic>>(
              'appendContinuationItemsAction/continuationItems')
          ?.cast<JsonMap>();
    }
    if (context == null) {
      throw FatalFailureException('Failed to get initial data context.', 0);
    }
    return context;
  }

  JsonMap? getContinuationContext() {
    final contentContext = getContentContext();
    final continuationItem = contentContext
        .firstWhereOrNull((e) => e['continuationItemRenderer'] != null);
    final continuationItemRenderer =
        continuationItem?.getJson<JsonMap>('continuationItemRenderer');
    if (continuationItemRenderer != null) {
      final command = continuationItemRenderer.getJson<JsonMap>(
        'continuationEndpoint/continuationCommand',
      );
      if (command != null) {
        return command;
      }
    }
    if (root.containsKey('contents')) {
      final tabs = root.getJson<List<dynamic>>(
        'contents/twoColumnBrowseResultsRenderer/tabs',
      );
      final selectedTab = tabs
          ?.map((e) => e['tabRenderer'])
          .cast<JsonMap>()
          .firstWhereOrNull((e) => e['selected'] as bool? ?? false);
      final sectionContents = selectedTab?.getJson<List<dynamic>>(
        'content/sectionListRenderer/contents',
      );
      final firstSection = sectionContents?.firstOrNull as JsonMap?;
      final firstContentBlock = firstSection
          ?.getJson<List<dynamic>>(
            'itemSectionRenderer/contents',
          )
          ?.firstOrNull as JsonMap?;
      final items =
          firstContentBlock?.getJson<List<dynamic>>('gridRenderer/items');
      final continuationItemFromGrid =
          items?.firstWhereOrNull((e) => e['continuationItemRenderer'] != null)
              as JsonMap?;
      return continuationItemFromGrid?.getJson<JsonMap>(
        'continuationItemRenderer/continuationEndpoint/continuationCommand',
      );
    }
    if (root.containsKey('onResponseReceivedActions')) {
      final firstAction = root
          .getJson<List<dynamic>>('onResponseReceivedActions')
          ?.firstOrNull as JsonMap?;
      final continuationItems = firstAction?.getJson<List<dynamic>>(
        'appendContinuationItemsAction/continuationItems',
      );
      final continuationItemFromAction = continuationItems?.firstWhereOrNull(
          (e) => e['continuationItemRenderer'] != null) as JsonMap?;
      return continuationItemFromAction?.getJson<JsonMap>(
        'continuationItemRenderer/continuationEndpoint/continuationCommand',
      );
    }
    return null;
  }

  ChannelVideo? _parseContent(JsonMap? content) {
    if (content == null) {
      return null;
    }

    Map<String, dynamic>? video;
    bool isLockup = false;
    if (content.containsKey('gridVideoRenderer')) {
      video = content.getJson<JsonMap>('gridVideoRenderer');
    } else if (content.containsKey('richItemRenderer')) {
      video = content.getJson<JsonMap>(
        'richItemRenderer/content/${type.youtubeRenderText}',
      );
      if (video == null && type == VideoType.normal) {
        video = content
            .getJson<JsonMap>('richItemRenderer/content/lockupViewModel');
        if (video != null &&
            video['contentType'] == 'LOCKUP_CONTENT_TYPE_VIDEO') {
          isLockup = true;
        } else {
          video = null;
        }
      }
      if (type == VideoType.shorts && video != null) {
        return ChannelVideo(
            VideoId(video.getJson<String>(
                'onTap/innertubeCommand/reelWatchEndpoint/videoId')!),
            video.getJson<String>('overlayMetadata/primaryText/content')!,
            Duration.zero,
            video.getJson<String>('thumbnail/sources/0/url') ??
                video.getJson<String>(
                    'thumbnailViewModel/thumbnailViewModel/image/sources/0/url') ??
                '',
            '',
            video
                    .getJson<String>('overlayMetadata/secondaryText/content')
                    .parseInt() ??
                0);
      }
    }

    if (video == null) {
      return null;
    }

    if (isLockup) {
      return ChannelVideo(
        VideoId(video.getJson<String>(
            'rendererContext/commandContext/onTap/innertubeCommand/watchEndpoint/videoId')!),
        video.getJson<String>('metadata/primaryText/content') ?? '',
        video
                .getJson<String>(
                    'imageOverlays/0/thumbnailOverlayTimeStatusRenderer/text/simpleText')
                ?.toDuration() ??
            Duration.zero,
        video.getJson<String>(
                'thumbnailViewModel/thumbnailViewModel/image/sources/0/url') ??
            '',
        video.getJson<String>('metadata/metadataParts/1/text/content') ?? '',
        video.getJson<String>('metadata/metadataText/content').parseInt() ?? 0,
      );
    }

    return ChannelVideo(
      VideoId(video.getT<String>('videoId')!),
      video.getJson<String>('title/simpleText') ??
          video
              .getJson<List<dynamic>>('title/runs')
              ?.map((e) => (e as Map)['text'])
              .join() ??
          '',
      (video.getJson<List<dynamic>>('thumbnailOverlays')?.firstOrNull
                  as JsonMap?)
              ?.getJson<String>(
                'thumbnailOverlayTimeStatusRenderer/text/simpleText',
              )
              ?.toDuration() ??
          Duration.zero,
      (video.getJson<List<dynamic>>('thumbnail/thumbnails')?.last as JsonMap?)
              ?.getT<String>('url') ??
          '',
      video.getJson<String>('publishedTimeText/simpleText') ?? '',
      video.getJson<String>('viewCountText/simpleText').parseInt() ?? 0,
    );
  }
}

//
