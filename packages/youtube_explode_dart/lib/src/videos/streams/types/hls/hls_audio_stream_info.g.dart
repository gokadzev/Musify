// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: non_constant_identifier_names, require_trailing_commas

part of 'hls_audio_stream_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HlsAudioStreamInfo _$HlsAudioStreamInfoFromJson(Map<String, dynamic> json) =>
    HlsAudioStreamInfo(
      VideoId.fromJson(json['videoId'] as Map<String, dynamic>),
      (json['tag'] as num).toInt(),
      Uri.parse(json['url'] as String),
      StreamContainer.fromJson(json['container'] as Map<String, dynamic>),
      FileSize.fromJson(json['size'] as Map<String, dynamic>),
      Bitrate.fromJson(json['bitrate'] as Map<String, dynamic>),
      json['audioCodec'] as String,
      json['qualityLabel'] as String,
      mediaTypeFromJson(json['codec'] as String),
    );

Map<String, dynamic> _$HlsAudioStreamInfoToJson(HlsAudioStreamInfo instance) =>
    <String, dynamic>{
      'videoId': instance.videoId,
      'tag': instance.tag,
      'url': instance.url.toString(),
      'container': instance.container,
      'size': instance.size,
      'bitrate': instance.bitrate,
      'audioCodec': instance.audioCodec,
      'codec': mediaTypeToJson(instance.codec),
      'qualityLabel': instance.qualityLabel,
    };
