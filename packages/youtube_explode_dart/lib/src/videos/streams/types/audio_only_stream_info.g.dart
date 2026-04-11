// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: non_constant_identifier_names, require_trailing_commas

part of 'audio_only_stream_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioOnlyStreamInfo _$AudioOnlyStreamInfoFromJson(Map<String, dynamic> json) =>
    AudioOnlyStreamInfo(
      VideoId.fromJson(json['videoId'] as Map<String, dynamic>),
      (json['tag'] as num).toInt(),
      Uri.parse(json['url'] as String),
      StreamContainer.fromJson(json['container'] as Map<String, dynamic>),
      FileSize.fromJson(json['size'] as Map<String, dynamic>),
      Bitrate.fromJson(json['bitrate'] as Map<String, dynamic>),
      json['audioCodec'] as String,
      json['qualityLabel'] as String,
      (json['fragments'] as List<dynamic>)
          .map((e) => Fragment.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaTypeFromJson(json['codec'] as String),
      json['audioTrack'] == null
          ? null
          : AudioTrack.fromJson(json['audioTrack'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AudioOnlyStreamInfoToJson(
        AudioOnlyStreamInfo instance) =>
    <String, dynamic>{
      'videoId': instance.videoId,
      'tag': instance.tag,
      'url': instance.url.toString(),
      'container': instance.container,
      'size': instance.size,
      'bitrate': instance.bitrate,
      'audioCodec': instance.audioCodec,
      'codec': mediaTypeToJson(instance.codec),
      'fragments': instance.fragments,
      'qualityLabel': instance.qualityLabel,
      'audioTrack': instance.audioTrack,
    };
