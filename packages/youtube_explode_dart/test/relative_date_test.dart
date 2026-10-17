import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:youtube_explode_dart/src/extensions/helpers_extension.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/clients/related_videos_client.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  final cases = <String, Duration>{
    '3 years ago': const Duration(days: 1095),
    'Streamed 3 years ago': const Duration(days: 1095),
    'Streamed live 2 days ago': const Duration(days: 2),
    '3y ago': const Duration(days: 1095),
    'Streamed 3y ago': const Duration(days: 1095),
    'Premiered 2 hours ago': const Duration(hours: 2),
    'Premiered 2h ago': const Duration(hours: 2),
    '  Streamed   3y\tago  ': const Duration(days: 1095),
    '0 seconds ago': Duration.zero,
    '1 second ago': const Duration(seconds: 1),
    '2s ago': const Duration(seconds: 2),
    '2 minutes ago': const Duration(minutes: 2),
    '2m ago': const Duration(minutes: 2),
    '2 min ago': const Duration(minutes: 2),
    '2h ago': const Duration(hours: 2),
    '2 days ago': const Duration(days: 2),
    '2d ago': const Duration(days: 2),
    '2 weeks ago': const Duration(days: 14),
    '2w ago': const Duration(days: 14),
    '2 months ago': const Duration(days: 60),
    '2mo ago': const Duration(days: 60),
  };

  for (final entry in cases.entries) {
    test('parses "${entry.key}"', () {
      final before = DateTime.now().subtract(entry.value);
      final parsed = entry.key.toDateTime();
      final after = DateTime.now().subtract(entry.value);
      expect(parsed, isNotNull);
      expect(parsed!.isBefore(before), isFalse);
      expect(parsed.isAfter(after), isFalse);
    });
  }

  for (final input in <String?>[
    null,
    '',
    'Live now',
    'Streamed yesterday',
    'Streamed 2 days',
    '1 century ago',
    'Streamed a year ago',
    '3 unknown ago',
    'Streamed 3q ago',
    'há 3 anos',
    '-1 years ago',
    '3 years from now',
    '999999999999999999999999999 years ago',
    '9000000000000000000 years ago',
  ]) {
    test('unknown date "$input" does not throw', () {
      expect(input.toDateTime(), isNull);
    });
  }

  test('related videos keep unfamiliar publication dates', () {
    final fixtures = ['Streamed 2 days', '3 years ago'].map((date) {
      final video = _video(date)['videoRenderer'] as Map<String, dynamic>;
      video['title'] = {'simpleText': 'Test video'};
      video['longBylineText'] = video.remove('ownerText');
      return {'compactVideoRenderer': video};
    }).toList();
    final videos = RelatedVideosClient(fixtures).relatedVideos().toList();
    expect(videos, hasLength(2));
    expect(videos.first.uploadDate, isNull);
    expect(videos.last.uploadDate, isNotNull);
  });

  test('search preserves all videos across pages with unfamiliar dates',
      () async {
    final client = YoutubeExplode(
      httpClient: YoutubeHttpClient(
        MockClient((request) async {
          final videos = [
            _video('Streamed 3y ago'),
            _video('Streamed a year ago'),
            _video('3 years ago'),
          ];
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({
                'estimatedResults': '3',
                'onResponseReceivedCommands': [
                  {
                    'appendContinuationItemsAction': {
                      'continuationItems': [
                        {
                          'itemSectionRenderer': {'contents': videos},
                        },
                      ],
                    },
                  },
                ],
              }),
              200,
              request: request,
            );
          }
          final data = {
            'estimatedResults': '6',
            'contents': {
              'twoColumnSearchResultsRenderer': {
                'primaryContents': {
                  'sectionListRenderer': {
                    'contents': [
                      {
                        'itemSectionRenderer': {'contents': videos},
                      },
                      {
                        'continuationItemRenderer': {
                          'continuationEndpoint': {
                            'continuationCommand': {'token': 'next-page'},
                          },
                        },
                      },
                    ],
                  },
                },
              },
            },
          };
          return http.Response(
            '<html><script>var ytInitialData = ${jsonEncode(data)};</script></html>',
            200,
            request: request,
          );
        }),
      ),
    );
    addTearDown(client.close);

    final firstPage = await client.search.search('test');
    final nextPage = await firstPage.nextPage();
    for (final page in [firstPage, nextPage!]) {
      expect(page, hasLength(3));
      expect(page[0].uploadDate, isNotNull);
      expect(page[1].uploadDate, isNull);
      expect(page[2].uploadDate, isNotNull);
    }
  });
}

Map<String, dynamic> _video(String date) => {
      'videoRenderer': {
        'videoId': 'jNQXAC9IVRw',
        'title': {
          'runs': [
            {'text': 'Test video'},
          ],
        },
        'ownerText': {
          'runs': [
            {
              'text': 'Test channel',
              'navigationEndpoint': {
                'browseEndpoint': {'browseId': 'UC4QobU6STFB0P71PMvOGN5A'},
              },
            },
          ],
        },
        'lengthText': {'simpleText': '3:00'},
        'viewCountText': {'simpleText': '100 views'},
        'publishedTimeText': {'simpleText': date},
      },
    };
