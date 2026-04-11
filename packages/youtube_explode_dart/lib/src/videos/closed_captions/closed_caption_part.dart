import 'package:json_annotation/json_annotation.dart';

part 'closed_caption_part.g.dart';

/// Part of a closed caption (usually a single word).
@JsonSerializable()
class ClosedCaptionPart {
  /// Text displayed by this caption part.
  final String text;

  /// Time at which this caption part starts being displayed
  /// (relative to the caption's own offset).
  final Duration offset;

  /// Initializes an instance of [ClosedCaptionPart]
  ClosedCaptionPart(this.text, this.offset);

  @override
  String toString() => text;

  ///
  factory ClosedCaptionPart.fromJson(Map<String, dynamic> json) =>
      _$ClosedCaptionPartFromJson(json);

  ///
  Map<String, dynamic> toJson() => _$ClosedCaptionPartToJson(this);
}
