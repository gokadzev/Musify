// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: non_constant_identifier_names, require_trailing_commas

part of 'hls_muxed_stream_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HlsMuxedStreamInfo _$HlsMuxedStreamInfoFromJson(Map<String, dynamic> json) =>
    HlsMuxedStreamInfo(
      VideoId.fromJson(json['videoId'] as Map<String, dynamic>),
      (json['tag'] as num).toInt(),
      Uri.parse(json['url'] as String),
      StreamContainer.fromJson(json['container'] as Map<String, dynamic>),
      FileSize.fromJson(json['size'] as Map<String, dynamic>),
      Bitrate.fromJson(json['bitrate'] as Map<String, dynamic>),
      json['audioCodec'] as String,
      json['videoCodec'] as String,
      json['qualityLabel'] as String,
      $enumDecode(_$VideoQualityEnumMap, json['videoQuality']),
      VideoResolution.fromJson(json['videoResolution'] as Map<String, dynamic>),
      Framerate.fromJson(json['framerate'] as Map<String, dynamic>),
      mediaTypeFromJson(json['codec'] as String),
    );

Map<String, dynamic> _$HlsMuxedStreamInfoToJson(HlsMuxedStreamInfo instance) =>
    <String, dynamic>{
      'videoId': instance.videoId,
      'tag': instance.tag,
      'url': instance.url.toString(),
      'container': instance.container,
      'size': instance.size,
      'bitrate': instance.bitrate,
      'audioCodec': instance.audioCodec,
      'videoCodec': instance.videoCodec,
      'videoQuality': _$VideoQualityEnumMap[instance.videoQuality]!,
      'videoResolution': instance.videoResolution,
      'framerate': instance.framerate,
      'codec': mediaTypeToJson(instance.codec),
      'qualityLabel': instance.qualityLabel,
    };

const _$VideoQualityEnumMap = {
  VideoQuality.unknown: 'unknown',
  VideoQuality.low144: 'low144',
  VideoQuality.low240: 'low240',
  VideoQuality.medium360: 'medium360',
  VideoQuality.medium480: 'medium480',
  VideoQuality.high720: 'high720',
  VideoQuality.high1080: 'high1080',
  VideoQuality.high1440: 'high1440',
  VideoQuality.high2160: 'high2160',
  VideoQuality.high2880: 'high2880',
  VideoQuality.high3072: 'high3072',
  VideoQuality.high4320: 'high4320',
};
