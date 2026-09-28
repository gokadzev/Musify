import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http_parser/http_parser.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const _videoId = 'aBcDeFgHiJk';

AudioOnlyStreamInfo _audioOnly(int tag, String url, {int bitrate = 130000}) {
  return AudioOnlyStreamInfo(
    VideoId(_videoId),
    tag,
    Uri.parse(url),
    StreamContainer.parse('mp4'),
    const FileSize(3000000),
    Bitrate(bitrate),
    'mp4a.40.2',
    'medium',
    const [],
    MediaType.parse('audio/mp4; codecs="mp4a.40.2"'),
    null,
  );
}

MuxedStreamInfo _muxed(int tag, String url, {int bitrate = 354000}) {
  return MuxedStreamInfo(
    VideoId(_videoId),
    tag,
    Uri.parse(url),
    StreamContainer.parse('mp4'),
    const FileSize(8000000),
    Bitrate(bitrate),
    'mp4a.40.2',
    'avc1.42001E',
    '360p',
    VideoQuality.medium360,
    const VideoResolution(640, 360),
    const Framerate(25),
    MediaType.parse('video/mp4; codecs="avc1.42001E, mp4a.40.2"'),
  );
}

void main() {
  // selectAudioStreamForQuality reads the quality setting, which lives in
  // Hive; an empty box is enough to get its default.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('musify_test').path);
    await Hive.openBox('settings');
  });

  group('playableAudioSources', () {
    test('keeps audio-only streams when they carry a URL', () {
      final manifest = StreamManifest([
        _audioOnly(140, 'https://rr1---sn-x.googlevideo.com/videoplayback?a=1'),
        _muxed(18, 'https://rr1---sn-x.googlevideo.com/videoplayback?a=2'),
      ]);

      final sources = playableAudioSources(manifest);

      expect(sources, hasLength(1));
      expect(sources.single.tag, 140);
    });

    test('falls back to muxed when every audio-only URL is empty', () {
      // What the android client answers with: a full, plausible-looking list
      // of audio-only formats whose URLs are all empty strings, next to one
      // muxed stream that actually resolves.
      final manifest = StreamManifest([
        _audioOnly(139, ''),
        _audioOnly(140, ''),
        _audioOnly(251, ''),
        _muxed(18, 'https://rr1---sn-x.googlevideo.com/videoplayback?a=3'),
      ]);

      final sources = playableAudioSources(manifest);

      expect(sources, hasLength(1));
      expect(sources.single.tag, 18);
    });

    test('falls back to muxed when there is no audio-only stream at all', () {
      final manifest = StreamManifest([
        _muxed(18, 'https://rr1---sn-x.googlevideo.com/videoplayback?a=4'),
      ]);

      expect(playableAudioSources(manifest).single.tag, 18);
    });

    test('returns nothing when no stream carries a URL', () {
      final manifest = StreamManifest([_audioOnly(140, ''), _muxed(18, '')]);

      expect(playableAudioSources(manifest), isEmpty);
    });
  });

  group('selectAudioStreamForQuality', () {
    test('picks a muxed stream when that is all it is given', () {
      final muxed = _muxed(
        18,
        'https://rr1---sn-x.googlevideo.com/videoplayback?ratebypass=yes',
      );

      expect(selectAudioStreamForQuality([muxed]), same(muxed));
    });

    test('returns null for an empty selection', () {
      expect(selectAudioStreamForQuality([]), isNull);
    });
  });
}
