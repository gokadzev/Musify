// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: non_constant_identifier_names, require_trailing_commas

part of 'audio_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AudioTrack _$AudioTrackFromJson(Map<String, dynamic> json) => _AudioTrack(
      displayName: json['displayName'] as String,
      id: json['id'] as String,
      audioIsDefault: json['audioIsDefault'] as bool,
    );

Map<String, dynamic> _$AudioTrackToJson(_AudioTrack instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'id': instance.id,
      'audioIsDefault': instance.audioIsDefault,
    };
