import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../reverse_engineering/models/fragment.dart';
import '../../../video_id.dart';
import '../../mixins/hls_stream_info.dart';
import '../../models/audio_track.dart';
import '../../streams.dart';
import '../../mixins/stream_info.dart';

part 'hls_muxed_stream_info.g.dart';

/// YouTube media stream that contains both audio and video, in HLS format.
/// This is not directly downloadable but returns a file with a list of the video fragments urls.
@JsonSerializable()
class HlsMuxedStreamInfo
    with StreamInfo, AudioStreamInfo, VideoStreamInfo, HlsStreamInfo {
  @override
  final VideoId videoId;

  @override
  final int tag;

  @override
  final Uri url;

  @override
  final StreamContainer container;

  @override

  /// For HLS streams this is an approximation.
  final FileSize size;

  @override

  /// For HLS streams this is an approximation.
  final Bitrate bitrate;

  @override
  final String audioCodec;

  @override
  final String videoCodec;

  /// Video quality label, as seen on YouTube.
  @Deprecated('Use qualityLabel')
  @override
  String get videoQualityLabel => qualityLabel;

  /// Video quality.
  @override
  final VideoQuality videoQuality;

  /// Video resolution.
  @override
  final VideoResolution videoResolution;

  /// Video framerate.
  @override
  final Framerate framerate;

  /// Always empty.
  @override
  List<Fragment> get fragments => const [];

  /// Stream codec.
  @override
  @JsonKey(toJson: mediaTypeToJson, fromJson: mediaTypeFromJson)
  final MediaType codec;

  /// Stream codec.
  @override
  final String qualityLabel;

  /// Initializes an instance of [HlsMuxedStreamInfo]
  HlsMuxedStreamInfo(
    this.videoId,
    this.tag,
    this.url,
    this.container,
    this.size,
    this.bitrate,
    this.audioCodec,
    this.videoCodec,
    this.qualityLabel,
    this.videoQuality,
    this.videoResolution,
    this.framerate,
    this.codec,
  );

  @override
  String toString() =>
      '[HLS] Muxed ($tag | ${videoResolution}p${framerate.framesPerSecond} | $container)';

  factory HlsMuxedStreamInfo.fromJson(Map<String, dynamic> json) =>
      _$HlsMuxedStreamInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HlsMuxedStreamInfoToJson(this);

  /// Hls streams do not provide info about the language.
  @override
  AudioTrack? get audioTrack => null;

  @override
  int? get audioItag => null;
}
