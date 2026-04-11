import 'package:json_annotation/json_annotation.dart';

part 'closed_caption_format.g.dart';

/// SubTiles format.
@JsonSerializable()
class ClosedCaptionFormat {
  /// .srv format(1).
  static const ClosedCaptionFormat srv1 = ClosedCaptionFormat('srv1');

  /// .srv format(2).
  static const ClosedCaptionFormat srv2 = ClosedCaptionFormat('srv2');

  /// .srv format(3).
  static const ClosedCaptionFormat srv3 = ClosedCaptionFormat('srv3');

  /// .ttml format.
  static const ClosedCaptionFormat ttml = ClosedCaptionFormat('ttml');

  /// .vtt format.
  static const ClosedCaptionFormat vtt = ClosedCaptionFormat('vtt');

  /// List of all sub titles format.
  static const List<ClosedCaptionFormat> values = [srv1, srv2, srv3, ttml, vtt];

  /// Format code as string.
  final String formatCode;

  ///
  const ClosedCaptionFormat(this.formatCode);

  ///
  factory ClosedCaptionFormat.fromJson(Map<String, dynamic> json) =>
      _$ClosedCaptionFormatFromJson(json);

  ///
  Map<String, dynamic> toJson() => _$ClosedCaptionFormatToJson(this);
}
