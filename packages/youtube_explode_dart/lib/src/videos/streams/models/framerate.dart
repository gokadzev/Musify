import 'package:freezed_annotation/freezed_annotation.dart';

part 'framerate.freezed.dart';
part 'framerate.g.dart';

/// Encapsulates framerate.
@freezed
abstract class Framerate with _$Framerate implements Comparable<Framerate> {
  /// Initialize an instance of [Framerate]
  const factory Framerate(
    /// Framerate as frames per second
    num framesPerSecond,
  ) = _Framerate;

  const Framerate._();

  factory Framerate.fromJson(Map<String, dynamic> json) =>
      _$FramerateFromJson(json);

  ///
  bool operator >(Framerate other) => framesPerSecond > other.framesPerSecond;

  ///
  bool operator <(Framerate other) => framesPerSecond < other.framesPerSecond;

  @override
  String toString() => '${framesPerSecond}fps';

  @override
  int compareTo(Framerate other) =>
      framesPerSecond.compareTo(other.framesPerSecond);
}
