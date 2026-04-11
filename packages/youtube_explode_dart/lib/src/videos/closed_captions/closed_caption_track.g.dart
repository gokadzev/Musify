// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: non_constant_identifier_names, require_trailing_commas

part of 'closed_caption_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClosedCaptionTrack _$ClosedCaptionTrackFromJson(Map<String, dynamic> json) =>
    ClosedCaptionTrack(
      (json['captions'] as List<dynamic>)
          .map((e) => ClosedCaption.fromJson(e as Map<String, dynamic>)),
    );

Map<String, dynamic> _$ClosedCaptionTrackToJson(ClosedCaptionTrack instance) =>
    <String, dynamic>{
      'captions': instance.captions,
    };
