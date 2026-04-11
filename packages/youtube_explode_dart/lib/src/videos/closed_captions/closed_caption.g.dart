// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: non_constant_identifier_names, require_trailing_commas

part of 'closed_caption.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClosedCaption _$ClosedCaptionFromJson(Map<String, dynamic> json) =>
    ClosedCaption(
      json['text'] as String,
      Duration(microseconds: (json['offset'] as num).toInt()),
      Duration(microseconds: (json['duration'] as num).toInt()),
      (json['parts'] as List<dynamic>)
          .map((e) => ClosedCaptionPart.fromJson(e as Map<String, dynamic>)),
    );

Map<String, dynamic> _$ClosedCaptionToJson(ClosedCaption instance) =>
    <String, dynamic>{
      'text': instance.text,
      'offset': instance.offset.inMicroseconds,
      'duration': instance.duration.inMicroseconds,
      'parts': instance.parts,
    };
