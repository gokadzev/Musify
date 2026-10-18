import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/reverse_engineering/clients/related_videos_client.dart';

const _channel = 'UC38IQsAvIsxxjztdMZQtwHA';
const _id = 'dQw4w9WgXcQ';

Map<String, dynamic> _compact(String? views) => {
  'compactVideoRenderer': {
    'videoId': _id,
    'title': {'simpleText': 'Song'},
    'longBylineText': {
      'runs': [
        {
          'text': 'Artist',
          'navigationEndpoint': {
            'browseEndpoint': {'browseId': _channel},
          },
        },
      ],
    },
    'publishedTimeText': {'simpleText': '1 day ago'},
    'lengthText': {'simpleText': '3:30'},
    'viewCountText': {'simpleText': views},
  },
};

Map<String, dynamic> _lockup(String? views) => {
  'lockupViewModel': {
    'rendererContext': {
      'commandContext': {
        'onTap': {
          'innertubeCommand': {
            'watchEndpoint': {'videoId': _id},
          },
        },
      },
    },
    'metadata': {
      'lockupMetadataViewModel': {
        'title': {'content': 'Song'},
        'image': {
          'decoratedAvatarViewModel': {
            'rendererContext': {
              'commandContext': {
                'onTap': {
                  'innertubeCommand': {
                    'browseEndpoint': {'browseId': _channel},
                  },
                },
              },
            },
          },
        },
        'metadata': {
          'contentMetadataViewModel': {
            'metadataRows': [
              {
                'metadataParts': [
                  {
                    'text': {'content': 'Artist'},
                  },
                ],
              },
              {
                'metadataParts': [
                  {
                    if (views != null) 'text': {'content': views},
                  },
                  {
                    'text': {'content': '1 day ago'},
                  },
                ],
              },
            ],
          },
        },
      },
    },
  },
};

void main() {
  for (final renderer in {'compact': _compact, 'lockup': _lockup}.entries) {
    test('${renderer.key} keeps related videos with unknown view counts', () {
      final videos = RelatedVideosClient([
        renderer.value('No views'),
        renderer.value(''),
        renderer.value('123 views'),
      ]).relatedVideos().toList();
      expect(videos, hasLength(3));
      expect(videos.map((video) => video.engagement.viewCount), [0, 0, 123]);
      expect(videos.every((video) => video.title == 'Song'), true);
    });

    test('${renderer.key} preserves numeric and abbreviated view counts', () {
      for (final sample in {
        '0 views': 0,
        '1 view': 1,
        '1,234 views': 1234,
        '1.5K views': 1500,
        '2.3M views': 2300000,
      }.entries) {
        final video = RelatedVideosClient([renderer.value(sample.key)])
            .relatedVideos()
            .single;
        expect(video.engagement.viewCount, sample.value, reason: sample.key);
      }
    });
  }

  test('lockup keeps a video without view count metadata', () {
    final video = RelatedVideosClient([_lockup(null)]).relatedVideos().single;
    expect(video.engagement.viewCount, 0);
    expect(video.title, 'Song');
  });
}
