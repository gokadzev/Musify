import 'package:meta/meta.dart';

/// Parent class for domain exceptions thrown by [YoutubeExplode]
class YoutubeExplodeException implements Exception {
  /// Generic message.
  final String message;

  /// Addition exceptions thrown.
  final List<YoutubeExplodeException> _others = [];

  /// Add another exception to the stack.
  void combine(YoutubeExplodeException e) => _others.add(e);

  ///
  YoutubeExplodeException(this.message);

  @override
  @nonVirtual
  String toString() {
    if (_others.isEmpty) {
      return '$runtimeType: $message';
    }
    final buffer = StringBuffer('$runtimeType: $message\n\n');
    buffer.writeln('Additionally these exceptions where thrown in the stack');
    for (final e in _others) {
      buffer.writeln('---');
      buffer.writeln(e.toString());
      buffer.writeln('---');
    }

    return buffer.toString();
  }
}
