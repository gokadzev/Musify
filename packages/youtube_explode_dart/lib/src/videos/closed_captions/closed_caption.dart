import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'closed_caption_part.dart';

part 'closed_caption.g.dart';

/// Text that gets displayed at specific time during video playback,
/// as part of a [ClosedCaptionTrack]
@JsonSerializable()
class ClosedCaption {
  /// Text displayed by this caption.
  final String text;

  /// Time at which this caption starts being displayed.
  final Duration offset;

  /// Duration this caption is displayed.
  final Duration duration;

  /// Time at which this caption ends being displayed.
  Duration get end => offset + duration;

  /// Caption parts (usually individual words).
  /// May be empty because not all captions contain parts.
  final UnmodifiableListView<ClosedCaptionPart> parts;

  /// Initializes an instance of [ClosedCaption]
  ClosedCaption(
    this.text,
    this.offset,
    this.duration,
    Iterable<ClosedCaptionPart> parts,
  ) : parts = UnmodifiableListView(parts);

  /// Gets the caption part displayed at the specified point in time,
  /// relative to this caption's offset.
  /// Returns null if not found.
  /// Note that some captions may not have any parts at all.
  ClosedCaptionPart? getPartByTime(Duration offset) =>
      parts.firstWhereOrNull((e) => e.offset >= offset);

  @override
  String toString() => 'Text($offset): $text';

  ///
  factory ClosedCaption.fromJson(Map<String, dynamic> json) =>
      _$ClosedCaptionFromJson(json);

  ///
  Map<String, dynamic> toJson() => _$ClosedCaptionToJson(this);
}
