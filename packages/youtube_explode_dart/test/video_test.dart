import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'data.dart';
import 'skip_gh.dart';

void main() {
  YoutubeExplode? yt;
  setUpAll(() {
    yt = YoutubeExplode();
  });

  tearDownAll(() {
    yt?.close();
  });

  test('Get metadata of a video', () async {
    const videoUrl = 'https://www.youtube.com/watch?v=TW_yxPcodhk';
    final video = await yt!.videos.get(VideoId(videoUrl));
    expect(video.id.value, 'TW_yxPcodhk');
    expect(video.url, videoUrl);
    expect(video.title, 'HexRedirect');
    expect(video.channelId.value, 'UCqKbtOLx4NCBh5KKMSmbX0g');
    expect(video.author, 'Hexah');
    final rangeMs = DateTime(2018, 12, 09).millisecondsSinceEpoch;
    // 1day margin since the uploadDate could differ from timezones
    expect(
      video.uploadDate!.millisecondsSinceEpoch,
      inInclusiveRange(rangeMs - 86400000, rangeMs + 86400000),
    );
    expect(
      video.publishDate!.millisecondsSinceEpoch,
      inInclusiveRange(rangeMs - 86400000, rangeMs + 86400000),
    );
    expect(
      video.description,
      contains('Get it here: https://github.com/Hexer10/HexRedirect'),
    );
    expect(video.duration!.inSeconds, 33);
    expect(video.thumbnails.lowResUrl, isNotEmpty);
    expect(video.thumbnails.mediumResUrl, isNotEmpty);
    expect(video.thumbnails.highResUrl, isNotEmpty);
    expect(video.thumbnails.standardResUrl, isNotEmpty);
    expect(video.thumbnails.maxResUrl, isNotEmpty);
    expect(
      video.keywords,
      containsAll([
        'sourcemod',
        'plugin',
        'csgo',
        'redirect',
      ]),
    );
    expect(video.engagement.viewCount, greaterThanOrEqualTo(3000));
    expect(video.engagement.likeCount, greaterThanOrEqualTo(5));
    expect(video.engagement.dislikeCount, greaterThanOrEqualTo(0));
  }, skip: skipGH);

  group('Get metadata of any video', () {
    for (final videoId in VideoIdData.valid) {
      test('VideoId - $videoId', () async {
        final video = await yt!.videos.get(videoId.id);
        expect(video.id.value, videoId.id);

        expect(video.uploadDate, isNotNull);
        expect(video.publishDate, isNotNull);
      });
    }
  }, skip: skipGH);

  group('Get metadata of invalid videos throws VideoUnplayableException', () {
    for (final val in VideoIdData.invalid) {
      test('VideoId - $val', () {
        expect(
          () async => yt!.videos.get(val.id),
          throwsA(const TypeMatcher<VideoUnplayableException>()),
        );
      });
    }
  });

  group('Get related videos of a video', () {
    for (final val in VideoIdData.validWatchpage) {
      test('VideoId - $val', () async {
        final video = await yt!.videos.get(val.id);
        final relatedVideos = await yt!.videos.getRelatedVideos(video);
        expect(relatedVideos, isNotNull);
        expect(relatedVideos, isNotEmpty);
      });
    }
  }, skip: skipGH);

  test('Get multiple pages of related videos', () async {
    final video = await yt!.videos.get(VideoIdData.withHighQualityStreams.id);
    var relatedVideos = await yt!.videos.getRelatedVideos(video);
    expect(relatedVideos, isNotNull);
    expect(relatedVideos, isNotEmpty);
    relatedVideos = await relatedVideos!.nextPage();
    expect(relatedVideos, isNotNull);
    expect(relatedVideos, isNotEmpty);
  }, skip: skipGH);

  test('Get music data of music video', () async {
    final video = await yt!.videos.get(VideoIdData.music.id);

    expect(video.musicData.length, 2);
    final musicData = video.musicData.first;
    expect(musicData.song, 'Hello (Single Edit) (Single Edit)');
    expect(musicData.artist, 'Martin Solveig, Dragonette');
    expect(musicData.album, 'Smash');
    expect(musicData.image, isNotNull);
  });
}
