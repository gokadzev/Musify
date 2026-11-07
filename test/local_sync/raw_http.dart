import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// What the server answered on a raw connection.
class RawHttp {
  RawHttp(this.socket) {
    // A server that hangs up on a body it will not read resets the connection.
    socket.done.then((_) {}, onError: (_) {});
    socket.listen(
      (chunk) {
        _received.add(chunk);
        if (!_data.isCompleted) _data.complete();
      },
      onDone: () {
        closed = true;
        if (!_data.isCompleted) _data.complete();
        if (!_closed.isCompleted) _closed.complete();
      },
      onError: (_) {
        closed = true;
        if (!_data.isCompleted) _data.complete();
        if (!_closed.isCompleted) _closed.complete();
      },
    );
  }

  final Socket socket;
  final _received = BytesBuilder();
  final _closed = Completer<void>();
  var _data = Completer<void>();
  var closed = false;

  String get text => latin1.decode(_received.toBytes());
  int? get status {
    final match = RegExp(r'^HTTP/1\.[01] (\d{3})').firstMatch(text);
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// The body of the reply, with the framing of a chunked one removed.
  String get body {
    final end = text.indexOf('\r\n\r\n');
    if (end < 0) return '';
    final rest = text.substring(end + 4);
    if (!text.toLowerCase().contains('transfer-encoding: chunked')) return rest;
    final out = StringBuffer();
    var at = 0;
    while (at < rest.length) {
      final lineEnd = rest.indexOf('\r\n', at);
      if (lineEnd < 0) break;
      final size = int.tryParse(rest.substring(at, lineEnd), radix: 16) ?? 0;
      if (size == 0) break;
      out.write(rest.substring(lineEnd + 2, lineEnd + 2 + size));
      at = lineEnd + 2 + size + 2;
    }
    return out.toString();
  }

  /// Waits until a status line has arrived.
  Future<int> awaitStatus([
    Duration limit = const Duration(seconds: 10),
  ]) async {
    final stop = DateTime.now().add(limit);
    while (status == null) {
      if (DateTime.now().isAfter(stop) || closed) break;
      _data = Completer<void>();
      await _data.future.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {},
      );
    }
    return status ?? -1;
  }

  Future<bool> awaitClosed([Duration limit = const Duration(seconds: 10)]) =>
      _closed.future.timeout(limit).then((_) => true, onError: (_) => false);
}

/// The head of a POST to the sync API.
String rawHead(
  String path, {
  String? device,
  String? contentType = 'application/json',
  int? length,
  bool chunked = false,
}) =>
    'POST /api/sync/$path HTTP/1.1\r\n'
    'Host: 127.0.0.1\r\n'
    '${device == null ? '' : 'x-musify-device: $device\r\n'}'
    '${contentType == null ? '' : 'Content-Type: $contentType\r\n'}'
    '${chunked ? 'Transfer-Encoding: chunked\r\n' : ''}'
    '${length == null ? '' : 'Content-Length: $length\r\n'}'
    '\r\n';
