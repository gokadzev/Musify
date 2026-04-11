import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';

import 'models/stream_info_provider.dart';

typedef VideoInfo = ({String url, Map<String, String> params});
typedef SegmentInfo = ({String url, double duration});

@internal
class HlsManifest {
  static final _logger = Logger('YoutubeExplode.HLSManifest');
  final List<VideoInfo> videos;

  const HlsManifest(this.videos);

  /// [hlsFile] is the content of the HLS file with lines separated by '\n'
  static HlsManifest parse(String hlsFile) {
    final lines = hlsFile.trim().split('\n');
    assert(lines[0] == '#EXTM3U');
    var idx = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].startsWith('#EXT-X-INDEPENDENT-SEGMENTS')) {
        idx = i;
        break;
      }
    }
    assert(idx != -1, 'Could not find #EXT-X-INDEPENDENT-SEGMENTS section');
    final videos = <VideoInfo>[];
    final expr = RegExp('([^,]+)=("[^"]*"|[^,]*)');
    for (var i = idx + 1; i < lines.length; i += 1) {
      final line = lines[i];
      final params = {
        for (final match in expr.allMatches(line, line.indexOf(':') + 1))
          match.group(1)!: match.group(2)!,
      };
      if (line.startsWith('#EXT-X-MEDIA:')) {
        final url = params['URI']!;
        // Trim the quotes
        videos.add((url: url.substring(1, url.length - 1), params: params));
        continue;
      }
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        final url = lines[i + 1];
        videos.add((url: url, params: params));
        i++;
        continue;
      }
      _logger.warning('Unknown HLS line: $line');
    }
    return HlsManifest(videos);
  }

  List<_StreamInfo> get streams {
    final streams = <_StreamInfo>[];
    for (final video in videos) {
      final type = video.params['TYPE'];
      if (type != null && type != 'AUDIO') {
        // TODO: type 'SUBTITLES' not supported.
        continue;
      }
      // The tag is the number after the /itag/ segment in the url
      final videoParts = video.url.split('/');
      final itag = int.parse(videoParts[videoParts.indexOf('itag') + 1]);

      var bandwidth = int.tryParse(video.params['BANDWIDTH'] ?? '');
      final codecs = video.params['CODECS']?.replaceAll('"', '').split(',');
      final audioCodec = codecs?.first;
      final videoCodec = codecs?.last;
      final resolution = video.params['RESOLUTION']?.split('x');
      final videoWidth = int.tryParse(resolution?[0] ?? '');
      final videoHeight = int.tryParse(resolution?[1] ?? '');
      final framerate = int.tryParse(video.params['FRAME-RATE'] ?? '');
      final audioItag = int.tryParse(video.params['AUDIO']?.trimQuotes() ?? '');

      // To find the file size look for the segments after the sgoap and sgovp parameters (audio + video)
      // Then URL decode the value and find the clen= parameter
      String? sgoap;
      String? sgovp;
      final sgoapIndex = videoParts.indexOf('sgoap');
      final sgovpIndex = videoParts.indexOf('sgovp');
      if (sgoapIndex != -1) {
        sgoap = Uri.decodeFull(videoParts[sgoapIndex + 1]);
      }
      if (sgovpIndex != -1) {
        sgovp = Uri.decodeFull(videoParts[sgovpIndex + 1]);
      }

      int? audioClen;
      int? videoClen;
      if (sgoap != null) {
        audioClen =
            int.parse(RegExp(r'clen=(\d+)').firstMatch(sgoap)!.group(1)!);
        if (bandwidth == null) {
          final dur = double.parse(
              RegExp(r'dur=(\d+\.\d+)').firstMatch(sgoap)!.group(1)!);
          bandwidth = (audioClen / dur).round() * 8;
        }
      }
      if (sgovp != null) {
        videoClen =
            int.parse(RegExp(r'clen=(\d+)').firstMatch(sgovp)!.group(1)!);
      }

      streams.add(
        _StreamInfo(
          itag,
          video.url,
          audioCodec,
          videoCodec,
          resolution != null ? '${videoWidth}x$videoHeight' : null,
          videoWidth,
          videoHeight,
          framerate,
          (audioClen ?? 0) + (videoClen ?? 0),
          bandwidth ?? 0,
          videoClen == null,
          audioClen == null,
          audioItag,
        ),
      );
    }
    return streams;
  }

  static List<SegmentInfo> parseVideoSegments(String hlsFile) {
    final lines = hlsFile.trim().split('\n');
    assert(lines[0] == '#EXTM3U');
    assert(lines[1].startsWith('#EXT-X-VERSION:'));
    final extXVersion = int.parse(lines[1].substring('#EXT-X-VERSION:'.length));
    if (extXVersion != 3 && extXVersion != 6) {
      throw Exception('Unsupported HLS version: $extXVersion');
    }
    assert(lines[2] == '#EXT-X-PLAYLIST-TYPE:VOD');
    final segments = <SegmentInfo>[];
    for (var i = 3; i < lines.length; i++) {
      if (lines[i] == '#EXT-X-ENDLIST') {
        break;
      }
      if (lines[i].startsWith('#EXT-X-MAP') ||
          lines[i].startsWith('#EXT-X-TARGETDURATION')) {
        continue;
      }
      final duration = double.parse(
          lines[i].substring('#EXTINF:'.length, lines[i].length - 1));
      final url = lines[i + 1];
      segments.add((url: url, duration: duration));
      i++;
    }
    return segments;
  }
}

class _StreamInfo extends StreamInfoProvider {
  @override
  final int tag;

  @override
  final String url;

  @override
  String get container => 'm3u8';

  @override
  final String? audioCodec;

  @override
  final String? videoCodec;

  @override
  final MediaType codec;

  @override
  final String? qualityLabel;

  @override
  final int? videoWidth;

  @override
  final int? videoHeight;

  @override
  final int? framerate;

  @override
  final int contentLength;

  @override
  final int bitrate;

  @override
  final bool audioOnly;

  @override
  final bool videoOnly;

  @override
  final int? audioItag;

  _StreamInfo(
    this.tag,
    this.url,
    this.audioCodec,
    this.videoCodec,
    this.qualityLabel,
    this.videoWidth,
    this.videoHeight,
    this.framerate,
    this.contentLength,
    this.bitrate,
    this.audioOnly,
    this.videoOnly,
    this.audioItag,
  ) : codec = MediaType('application', 'vnd.apple.mpegurl', {
          'codecs': [
            if (audioCodec != null) audioCodec,
            if (videoCodec != null) videoCodec,
          ].join(',')
        });

  @override
  StreamSource get source => StreamSource.hls;
}

extension on String {
  String trimQuotes() => substring(1, length - 1);
}
