import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_container.freezed.dart';
part 'stream_container.g.dart';

/// Stream container.
@freezed
abstract class StreamContainer with _$StreamContainer {
  /// Initializes an instance of [StreamContainer]
  const factory StreamContainer._internal(
    /// Container name.
    /// Can be used as file extension
    String name,
  ) = _StreamContainer;

  factory StreamContainer.fromJson(Map<String, dynamic> json) =>
      StreamContainer.parse(json['name'] as String);

  const StreamContainer._();

  /// MPEG-4 Part 14 (.mp4).
  static const StreamContainer mp4 = StreamContainer._internal('mp4');

  /// Web Media (.webm).
  static const StreamContainer webM = StreamContainer._internal('webm');

  /// 3rd Generation Partnership Project (.3gpp).
  static const StreamContainer tgpp = StreamContainer._internal('3gpp');

  /// M3U8 (.m3u8).
  static const StreamContainer m3u8 = StreamContainer._internal('m3u8');

  /// Parse a container from name.
  factory StreamContainer.parse(String name) {
    return switch (name.toLowerCase()) {
      'mp4' => StreamContainer.mp4,
      'webm' => StreamContainer.webM,
      '3gpp' => StreamContainer.tgpp,
      'm3u8' => StreamContainer.m3u8,
      _ => throw ArgumentError.value(
          name, 'name', 'Valid values: mp4, webm, 3gpp'),
    };
  }

  @override
  String toString() => name;
}
