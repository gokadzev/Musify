import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'raw_http.dart';
import 'service_harness.dart';

void main() {
  final h = SyncHarness();
  setUpAll(h.openStorage);
  setUp(() => h.start(bodyTimeout: const Duration(milliseconds: 600)));
  tearDown(h.stop);
  tearDownAll(h.closeStorage);

  Future<RawHttp> connect() async =>
      RawHttp(await Socket.connect('127.0.0.1', h.server.serverPort!));

  // The body of a request that decodes as JSON but is not an envelope.
  final notAnEnvelope = utf8.encode('{"apiVersion":3}');

  group('content type', () {
    test('every route refuses what is not JSON', () async {
      for (final path in [
        'pair-request',
        'pair-verify',
        'capabilities',
        'merge',
      ]) {
        final plain = await connect();
        plain.socket.add(
          utf8.encode(
            rawHead(
              path,
              device: SyncHarness.peerId,
              contentType: 'text/plain',
              length: notAnEnvelope.length,
            ),
          ),
        );
        plain.socket.add(notAnEnvelope);
        expect(await plain.awaitStatus(), 415, reason: '$path text/plain');

        final none = await connect();
        none.socket.add(
          utf8.encode(
            rawHead(
              path,
              device: SyncHarness.peerId,
              contentType: null,
              length: notAnEnvelope.length,
            ),
          ),
        );
        none.socket.add(notAnEnvelope);
        expect(await none.awaitStatus(), 415, reason: '$path without type');
      }
    });

    test('JSON with a charset is accepted, as the apps send it', () async {
      final raw = await connect();
      raw.socket.add(
        utf8.encode(
          rawHead(
            'capabilities',
            device: SyncHarness.peerId,
            contentType: 'application/json; charset=utf-8',
            length: notAnEnvelope.length,
          ),
        ),
      );
      raw.socket.add(notAnEnvelope);
      // Past the type check: the envelope is what fails.
      expect(await raw.awaitStatus(), 400);
    });

    test('other paths and methods stay 404', () async {
      final raw = await connect();
      raw.socket.add(
        utf8.encode('GET /api/sync/capabilities HTTP/1.1\r\nHost: x\r\n\r\n'),
      );
      expect(await raw.awaitStatus(), 404);
    });
  });

  group('body of a merge', () {
    test('without a length it is refused before it is read', () async {
      final raw = await connect();
      raw.socket
        ..add(
          utf8.encode(
            rawHead('merge', device: SyncHarness.peerId, chunked: true),
          ),
        )
        ..add(utf8.encode('${notAnEnvelope.length.toRadixString(16)}\r\n'))
        ..add(notAnEnvelope)
        ..add(utf8.encode('\r\n0\r\n\r\n'));
      expect(await raw.awaitStatus(), 411);
    });

    test('a declared length over the limit is refused unread', () async {
      final raw = await connect();
      raw.socket.add(
        utf8.encode(
          rawHead(
            'merge',
            device: SyncHarness.peerId,
            length: 70 * 1024 * 1024,
          ),
        ),
      );
      expect(await raw.awaitStatus(), 413);
      expect(await raw.awaitClosed(), true);
    });

    test('a stranger is turned away without reading anything', () async {
      final raw = await connect();
      raw.socket
        ..add(
          utf8.encode(rawHead('merge', device: 'stranger', length: 60000000)),
        )
        ..add(Uint8List(1024 * 1024));
      expect(await raw.awaitStatus(), 403);
      expect(await raw.awaitClosed(), true);
      // Still answering others.
      expect(
        (await h.post('capabilities', {}, device: 'stranger')).statusCode,
        403,
      );
    });

    test('a small route still takes a chunked body, up to its limit', () async {
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      Future<int> chunked(List<int> body) async {
        final request = await client.postUrl(h.url('capabilities'));
        request.headers
          ..contentType = ContentType.json
          ..set('x-musify-device', SyncHarness.peerId)
          ..chunkedTransferEncoding = true;
        request
          ..contentLength = -1
          ..add(body);
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      }

      expect(await chunked(notAnEnvelope), 400);
      expect(await chunked(Uint8List(70 * 1024)), 413);
    });

    test('only one large body is read at a time', () async {
      final first = await connect();
      first.socket
        ..add(
          utf8.encode(
            rawHead('merge', device: SyncHarness.peerId, length: 1000),
          ),
        )
        ..add(Uint8List(10));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final second = await connect();
      second.socket
        ..add(
          utf8.encode(
            rawHead(
              'merge',
              device: SyncHarness.peerId,
              length: notAnEnvelope.length,
            ),
          ),
        )
        ..add(notAnEnvelope);
      expect(await second.awaitStatus(), 429);

      // Other routes are not held up by it.
      expect((await h.secure('capabilities', {})).status, 200);

      // When the first one goes away the next is read.
      first.socket.destroy();
      var status = 0;
      for (var i = 0; i < 20 && status != 400; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final third = await connect();
        third.socket
          ..add(
            utf8.encode(
              rawHead(
                'merge',
                device: SyncHarness.peerId,
                length: notAnEnvelope.length,
              ),
            ),
          )
          ..add(notAnEnvelope);
        status = await third.awaitStatus();
      }
      expect(status, 400);
    });

    test(
      'a body that stalls is dropped at the timeout, and the slot is freed',
      () async {
        final slow = await connect();
        slow.socket
          ..add(
            utf8.encode(
              rawHead('merge', device: SyncHarness.peerId, length: 5000),
            ),
          )
          ..add(Uint8List(100));
        final started = DateTime.now();
        expect(await slow.awaitStatus(), 408);
        expect(
          DateTime.now().difference(started).inMilliseconds,
          lessThan(3000),
        );
        // The server hangs up: it does not wait for the rest of the body.
        expect(await slow.awaitClosed(), true);

        final next = await connect();
        next.socket
          ..add(
            utf8.encode(
              rawHead(
                'merge',
                device: SyncHarness.peerId,
                length: notAnEnvelope.length,
              ),
            ),
          )
          ..add(notAnEnvelope);
        expect(await next.awaitStatus(), 400);
      },
    );

    test('a body that trickles in is dropped at the timeout too', () async {
      final slow = await connect();
      slow.socket.add(
        utf8.encode(rawHead('merge', device: SyncHarness.peerId, length: 5000)),
      );
      var sent = 0;
      final trickle = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!slow.closed) {
          try {
            slow.socket.add([sent++ % 256]);
          } catch (_) {}
        }
      });
      addTearDown(trickle.cancel);
      expect(await slow.awaitStatus(), 408);
      trickle.cancel();
      expect(await slow.awaitClosed(), true);
      expect(sent, lessThan(20));
    });

    test('a refused body frees the slot', () async {
      for (var i = 0; i < 3; i++) {
        final response = await h.post('merge', {
          'apiVersion': 3,
          'encrypted': {'nonce': 'AA==', 'ciphertext': 'AA==', 'mac': 'AA=='},
        });
        expect(response.statusCode, 400, reason: 'attempt $i');
      }
      expect((await h.post('merge', {'apiVersion': 2})).statusCode, 426);
      expect((await h.post('merge', {'apiVersion': 3})).statusCode, 400);
    });
  });

  test('a large body does not freeze the isolate that serves it', () async {
    // Valid JSON that is not an envelope: the work is in decoding it.
    final numbers = Uint8List.fromList(
      utf8.encode('{"apiVersion":3,"padding":[${'1,' * 12000000}1]}'),
    );
    // What decoding it here would cost, on this machine, right now.
    final decoding = Stopwatch()..start();
    jsonDecode(utf8.decode(numbers));
    final decodeTime = decoding.elapsed;

    final raw = await connect();
    raw.socket.add(
      utf8.encode(
        rawHead('merge', device: SyncHarness.peerId, length: numbers.length),
      ),
    );
    var longest = Duration.zero;
    var last = Stopwatch()..start();
    final watch = Timer.periodic(const Duration(milliseconds: 5), (_) {
      if (last.elapsed > longest) longest = last.elapsed;
      last = Stopwatch()..start();
    });
    addTearDown(watch.cancel);
    raw.socket.add(numbers);
    expect(await raw.awaitStatus(const Duration(seconds: 60)), 400);
    watch.cancel();
    printOnFailure(
      'longest stall: ${longest.inMilliseconds} ms, '
      'decoding alone: ${decodeTime.inMilliseconds} ms',
    );
    // The body is decoded elsewhere: this isolate keeps running meanwhile.
    expect(longest * 3, lessThan(decodeTime));
  });
}
