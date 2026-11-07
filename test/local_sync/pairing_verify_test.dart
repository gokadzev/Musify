import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:musify/services/local_sync/sync_pairing.dart';

import 'service_harness.dart';

void main() {
  final h = SyncHarness();
  setUpAll(h.openStorage);
  // Lets a test act between "trusted" and "reply sent".
  Future<void> Function()? gate;
  setUp(() {
    gate = null;
    return h.start(
      replyTimeout: const Duration(seconds: 1),
      beforePairingReply: () => gate?.call() ?? Future.value(),
    );
  });
  tearDown(h.stop);
  tearDownAll(h.closeStorage);

  /// Fails the storage under the server, whatever happens in the test.
  Future<void> breakStorage() async {
    addTearDown(() async {
      if (!Hive.isBoxOpen('userNoBackup')) await Hive.openBox('userNoBackup');
    });
    await Hive.box('userNoBackup').close();
  }

  Future<http.Response> verify(
    ({String session, PinPairingClient client, Map<String, dynamic> proof})
    attempt,
  ) => h.post('pair-verify', {
    'session': attempt.session,
    'proof': attempt.proof,
  });

  test('a failing proof is a wrong PIN', () async {
    final attempt = await h.pair(clientId: 'newcomer', wrongPin: true);
    final completed = h.server.incomingPairingRequest.value!.completed;
    final response = await verify(attempt);
    expect(response.statusCode, 403);
    expect(jsonDecode(response.body)['error'], 'incorrect_pin');
    expect(await completed, false);
    expect(Hive.box('userNoBackup').get('localSyncPairFailures'), 1);
    expect(h.server.isDevicePaired('newcomer'), false);
  });

  test('a storage failure after the right PIN is not a wrong PIN', () async {
    final attempt = await h.pair(clientId: 'newcomer');
    final completed = h.server.incomingPairingRequest.value!.completed;
    // The storage fails after the PIN was proven right.
    await breakStorage();
    final response = await verify(attempt);
    await Hive.openBox('userNoBackup');

    expect(response.statusCode, 500);
    expect(jsonDecode(response.body)['error'], 'pairing_failed');
    expect(await completed, false);
    expect(Hive.box('userNoBackup').get('localSyncPairFailures'), isNull);
    expect(Hive.box('userNoBackup').get('localSyncPairBlockedUntil'), isNull);
    expect(h.server.isDevicePaired('newcomer'), false);
    expect(h.server.incomingPairingRequest.value, isNull);
    // Nothing is blocked: the next attempt is not told to wait.
    h.pairingClock = h.pairingClock.add(const Duration(seconds: 4));
    final again = await h.pair(clientId: 'newcomer');
    expect((await verify(again)).statusCode, 200);
    expect(h.server.isDevicePaired('newcomer'), true);
  });

  test('a storage failure leaves the old trust of the same device', () async {
    final attempt = await h.pair();
    await breakStorage();
    final response = await verify(attempt);
    await Hive.openBox('userNoBackup');
    expect(response.statusCode, 500);
    expect(h.server.pairedDevices.value.single.secret, h.secret);
  });

  /// Sends the proof and resets the connection once the server has trusted
  /// the device but not yet answered (SO_LINGER with a zero timeout makes the
  /// close a reset, which is what fails the server's write).
  Future<void> sendAndHangUp(
    ({String session, PinPairingClient client, Map<String, dynamic> proof})
    attempt,
  ) async {
    final trusted = Completer<void>();
    final release = Completer<void>();
    gate = () {
      trusted.complete();
      return release.future;
    };
    final body = utf8.encode(
      jsonEncode({'session': attempt.session, 'proof': attempt.proof}),
    );
    final socket = await Socket.connect('127.0.0.1', h.server.serverPort!);
    socket
      ..add(
        utf8.encode(
          'POST /api/sync/pair-verify HTTP/1.1\r\n'
          'Host: 127.0.0.1\r\n'
          'Content-Type: application/json\r\n'
          'Content-Length: ${body.length}\r\n\r\n',
        ),
      )
      ..add(body);
    await socket.flush();
    await trusted.future;
    socket
      ..setRawOption(
        RawSocketOption(
          1, // SOL_SOCKET
          13, // SO_LINGER
          Uint8List.fromList([1, 0, 0, 0, 0, 0, 0, 0]),
        ),
      )
      ..destroy();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    release.complete();
  }

  test(
    'a confirmation that cannot be delivered leaves no trust behind',
    () async {
      final attempt = await h.pair(clientId: 'newcomer');
      final completed = h.server.incomingPairingRequest.value!.completed;
      await sendAndHangUp(attempt);

      expect(await completed.timeout(const Duration(seconds: 10)), false);
      expect(h.server.isDevicePaired('newcomer'), false);
      final stored =
          Hive.box('userNoBackup').get('localSyncPairedDevices') as List;
      expect(stored.map((d) => d['deviceId']), isNot(contains('newcomer')));
    },
  );

  test(
    'a confirmation that cannot be delivered keeps the old secret and counters',
    () async {
      expect((await h.secure('capabilities', {})).status, 200);
      final counters = {
        for (final key in Hive.box('userNoBackup').keys.whereType<String>())
          if (key.startsWith('localSyncReceived:'))
            key: Hive.box('userNoBackup').get(key),
      };
      expect(counters, isNotEmpty);

      final attempt = await h.pair();
      final completed = h.server.incomingPairingRequest.value!.completed;
      await sendAndHangUp(attempt);

      expect(await completed.timeout(const Duration(seconds: 10)), false);
      expect(h.server.pairedDevices.value.single.secret, h.secret);
      final restored = {
        for (final key in Hive.box('userNoBackup').keys.whereType<String>())
          if (key.startsWith('localSyncReceived:'))
            key: Hive.box('userNoBackup').get(key),
      };
      expect(restored, counters);
      // The old key still works.
      expect((await h.secure('capabilities', {})).status, 200);
    },
  );

  test('a delivered confirmation completes the pairing', () async {
    final attempt = await h.pair(clientId: 'newcomer');
    final completed = h.server.incomingPairingRequest.value!.completed;
    final response = await verify(attempt);
    expect(response.statusCode, 200);
    expect(await completed, true);
    expect(h.server.isDevicePaired('newcomer'), true);
  });

  group('wrong PIN policy', () {
    int now() => h.pairingClock.millisecondsSinceEpoch;
    Object? stored(String key) => Hive.box('userNoBackup').get(key);
    int wait() => (stored('localSyncPairBlockedUntil') as int) - now();

    /// One wrong PIN, `gap` after the last request.
    Future<void> wrongPin({Duration gap = const Duration(seconds: 4)}) async {
      h.pairingClock = h.pairingClock.add(gap);
      final attempt = await h.pair(wrongPin: true);
      expect((await verify(attempt)).statusCode, 403);
    }

    Future<int> request() async {
      h.pairingClock = h.pairingClock.add(const Duration(seconds: 4));
      final response = await h.post('pair-request', {
        'apiVersion': 3,
        'clientId': SyncHarness.peerId,
        'clientName': 'Fixture',
      }, device: null);
      return response.statusCode;
    }

    test('four wrong PINs are free, the fifth waits five minutes', () async {
      for (var i = 0; i < 4; i++) {
        await wrongPin();
        expect(stored('localSyncPairBlockedUntil'), isNull, reason: 'try $i');
      }
      await wrongPin();
      expect(wait(), const Duration(minutes: 5).inMilliseconds);
    });

    test('the wait doubles and stops at fifteen minutes', () async {
      final waits = <int>[];
      for (var i = 0; i < 9; i++) {
        await wrongPin(
          gap: i < 5
              ? const Duration(seconds: 4)
              : Duration(minutes: waits.last + 1),
        );
        if (i >= 4) waits.add(wait() ~/ 60000);
      }
      expect(waits, [5, 10, 15, 15, 15]);
    });

    test('the wait is kept to the minute while it lasts', () async {
      for (var i = 0; i < 4; i++) {
        await wrongPin();
      }
      await wrongPin();
      await wrongPin(gap: const Duration(minutes: 6));
      await wrongPin(gap: const Duration(minutes: 11));
      expect(wait(), const Duration(minutes: 15).inMilliseconds);
      h.pairingClock = h.pairingClock.add(const Duration(minutes: 14));
      expect(await request(), 429);
      h.pairingClock = h.pairingClock.add(
        const Duration(minutes: 1, seconds: 1),
      );
      expect(await request(), 200);
    });

    test('a day without a mistake clears the count', () async {
      for (var i = 0; i < 4; i++) {
        await wrongPin();
      }
      await wrongPin(gap: const Duration(hours: 25));
      expect(stored('localSyncPairFailures'), 1);
      expect(stored('localSyncPairBlockedUntil'), isNull);
      expect(await request(), 200);
    });

    test('less than a day later the count goes on', () async {
      for (var i = 0; i < 4; i++) {
        await wrongPin();
      }
      await wrongPin(gap: const Duration(hours: 23));
      expect(stored('localSyncPairFailures'), 5);
      expect(wait(), const Duration(minutes: 5).inMilliseconds);
    });

    test('the count and the wait survive a restart', () async {
      for (var i = 0; i < 4; i++) {
        await wrongPin();
      }
      await wrongPin();
      await h.restart();
      expect(await request(), 429);
      await wrongPin(gap: const Duration(minutes: 6));
      expect(stored('localSyncPairFailures'), 6);
      expect(wait(), const Duration(minutes: 10).inMilliseconds);
    });

    test('the state an older version left is still understood', () async {
      // Seven mistakes and no record of when: kept, not cleared.
      await Hive.box('userNoBackup').put('localSyncPairFailures', 7);
      await wrongPin(gap: const Duration(days: 3));
      expect(stored('localSyncPairFailures'), 8);
      expect(wait(), const Duration(minutes: 15).inMilliseconds);
    });

    test('a right PIN clears everything', () async {
      for (var i = 0; i < 5; i++) {
        await wrongPin();
      }
      h.pairingClock = h.pairingClock.add(const Duration(minutes: 6));
      final attempt = await h.pair();
      expect((await verify(attempt)).statusCode, 200);
      expect(stored('localSyncPairFailures'), isNull);
      expect(stored('localSyncPairLastFailure'), isNull);
      expect(stored('localSyncPairBlockedUntil'), isNull);
    });
  });
}
