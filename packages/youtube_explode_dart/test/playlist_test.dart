import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  YoutubeExplode? yt;
  setUpAll(() {
    yt = YoutubeExplode();
  });

  tearDownAll(() {
    yt?.close();
  });

  test('Get metadata of a playlist', () async {
    const playlistUrl =
        'https://www.youtube.com/playlist?list=PLxTcxOtc5WIPFIyrYAvGqGhfAOmKJB0V3';
    final playlist = await yt!.playlists.get(PlaylistId(playlistUrl));
    expect(playlist.id.value, 'PLxTcxOtc5WIPFIyrYAvGqGhfAOmKJB0V3');
    expect(playlist.url, playlistUrl);
    expect(playlist.title, 'Tutorial');
    expect(playlist.author, 'Hexah');
    expect(playlist.description, '');
    expect(playlist.engagement.viewCount, greaterThanOrEqualTo(2));
    expect(playlist.engagement.likeCount, isNull);
    expect(playlist.engagement.dislikeCount, isNull);
    expect(playlist.thumbnails.lowResUrl, isNotEmpty);
    expect(playlist.thumbnails.mediumResUrl, isNotEmpty);
    expect(playlist.thumbnails.highResUrl, isNotEmpty);
    expect(playlist.thumbnails.standardResUrl, isNotEmpty);
    expect(playlist.thumbnails.maxResUrl, isNotEmpty);
    expect(playlist.videoCount, greaterThanOrEqualTo(3));
  });
  group('Get metadata of any playlist', () {
    for (final val in {
      PlaylistId('PLI5YfMzCfRtZ8eV576YoY3vIYrHjyVm_e'),
      PlaylistId('RD1hu8-y6fKg0'),
      PlaylistId('RDMMU-ty-2B02VY'),
      PlaylistId('RDCLAK5uy_lf8okgl2ygD075nhnJVjlfhwp8NsUgEbs'),
      PlaylistId('PL601B2E69B03FAB9D'),
    }) {
      test('PlaylistID - ${val.value}', () async {
        final playlist = await yt!.playlists.get(val);
        expect(playlist.id.value, val.value);
      });
    }
  });

  test('Get more than 100 videos in a playlist', () async {
    final videos = await yt!.playlists
        .getVideos(
          PlaylistId(
            'https://www.youtube.com/playlist?list=PLUpIWHnoHbGwSEJlDFpo9c5v3wk2DXLqo',
          ),
        )
        .toList();
    expect(videos.length, greaterThan(100));
  });

  group('Get videos in any playlist', () {
    for (final val in {
      PlaylistId('PLI5YfMzCfRtZ8eV576YoY3vIYrHjyVm_e'),
      PlaylistId('PLWwAypAcFRgKFlxtLbn_u14zddtDJj3mk'),
      PlaylistId('OLAK5uy_mtOdjCW76nDvf5yOzgcAVMYpJ5gcW5uKU'),
      PlaylistId('RDCLAK5uy_lf8okgl2ygD075nhnJVjlfhwp8NsUgEbs'),
      PlaylistId('UUTMt7iMWa7jy0fNXIktwyLA'),
      PlaylistId('OLAK5uy_lLeonUugocG5J0EUAEDmbskX4emejKwcM'),
      PlaylistId('PL601B2E69B03FAB9D'),
    }) {
      test('PlaylistID - ${val.value}', () async {
        expect(yt!.playlists.getVideos(val), emits(isNotNull));
      });
    }
  });

  test('Get videos of YT music playlist', () async {
    final videos = await yt!.playlists
        .getVideos('RDCLAK5uy_m9Rw_g5eCJtMhuRgP1eqU3H-XW7UL6uWQ')
        .toList();
    expect(videos.length, greaterThan(100));
  });

  test('Get videos of playlist with collaborative video', () async {
    final videos = await yt!.playlists
        .getVideos('PLjp0AEEJ0-fGKG_3skl0e1FQlJfnx-TJz')
        .toList();
    expect(videos.any((v) => v.id.value == '32sPcsb9ClQ'), true);
  });
}
