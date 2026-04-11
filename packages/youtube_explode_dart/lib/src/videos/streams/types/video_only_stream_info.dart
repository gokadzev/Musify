import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../youtube_explode_dart.dart';
import '../../../reverse_engineering/models/fragment.dart';
import '../mixins/stream_info.dart';

part 'video_only_stream_info.g.dart';

/// YouTube media stream that only contains video.
@JsonSerializable()
class VideoOnlyStreamInfo with StreamInfo, VideoStreamInfo {
  @override
  final VideoId videoId;

  @override
  final int tag;

  @override
  final Uri url;

  @override
  final StreamContainer container;

  @override
  final FileSize size;

  @override
  final Bitrate bitrate;

  @override
  final String videoCodec;

  @override
  final String qualityLabel;

  @override
  String get videoQualityLabel => qualityLabel;

  @override
  final VideoQuality videoQuality;

  @override
  final VideoResolution videoResolution;

  @override
  final Framerate framerate;

  @override
  final List<Fragment> fragments;

  @override
  @JsonKey(toJson: mediaTypeToJson, fromJson: mediaTypeFromJson)
  final MediaType codec;

  VideoOnlyStreamInfo(
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
    this.fragments,
    this.codec,
  );

  @override
  String toString() =>
      'Video-only ($tag | ${videoResolution}p${framerate.framesPerSecond} | $container)';

  factory VideoOnlyStreamInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoOnlyStreamInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$VideoOnlyStreamInfoToJson(this);
}
