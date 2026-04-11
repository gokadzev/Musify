import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../reverse_engineering/models/fragment.dart';
import '../../../video_id.dart';
import '../../mixins/hls_stream_info.dart';
import '../../streams.dart';
import '../../mixins/stream_info.dart';

part 'hls_video_stream_info.g.dart';

/// YouTube media stream that contains both audio and video, in HLS format.
/// This is not directly downloadable but returns a file with a list of the video fragments urls.
@JsonSerializable()
class HlsVideoStreamInfo with StreamInfo, VideoStreamInfo, HlsStreamInfo {
  @override
  final VideoId videoId;

  @override
  final int tag;

  @override
  final Uri url;

  @override
  final StreamContainer container;

  /// For HLS streams this is an approximation.
  @override
  final FileSize size;

  /// For HLS streams this is an approximation.
  @override
  final Bitrate bitrate;

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

  @override
  final int? audioItag;

  /// Initializes an instance of [HlsVideoStreamInfo]
  HlsVideoStreamInfo(
      this.videoId,
      this.tag,
      this.url,
      this.container,
      this.size,
      this.bitrate,
      this.videoCodec,
      this.qualityLabel,
      this.videoQuality,
      this.videoResolution,
      this.framerate,
      this.codec,
      this.audioItag);

  @override
  String toString() =>
      '[HLS] Video-only ($tag | ${videoResolution}p${framerate.framesPerSecond} | $container)';

  factory HlsVideoStreamInfo.fromJson(Map<String, dynamic> json) =>
      _$HlsVideoStreamInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HlsVideoStreamInfoToJson(this);
}
