import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musify/services/library_merge_service.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/local_sync/sync_pairing.dart';
import 'package:musify/services/local_sync/sync_security.dart';
import 'package:musify/services/local_sync_service.dart';

/// A [LocalSyncService] on loopback with one paired fixture device, for tests
/// that talk to its HTTP server as another device would.
class SyncHarness {
  static const peerId = 'trusted-fixture';
  static const boxes = ['user', 'userNoBackup', 'settings', 'cache'];

  late Directory directory;
  late LocalSyncService server;
  late String ownId;
  late String secret;
  var sequence = 0;
  DateTime pairingClock = DateTime(2026, 11, 3);

  Future<void> openStorage() async {
    directory = await Directory.systemTemp.createTemp('musify_sync_harness');
    Hive.init(directory.path);
    for (final name in boxes) {
      await Hive.openBox(name);
    }
  }

  Future<void> closeStorage() async {
    await Hive.close();
    await directory.delete(recursive: true);
  }

  Future<void> start({
    Duration? replyTimeout,
    Duration? bodyTimeout,
    Future<void> Function()? beforePairingReply,
  }) async {
    pairingClock = DateTime(2026, 11, 3);
    listeningStatsService.reload();
    for (final name in boxes) {
      await Hive.box(name).clear();
    }
    server = LocalSyncService.forTesting(
      pairingNow: () => pairingClock,
      replyTimeout: replyTimeout,
      bodyTimeout: bodyTimeout,
    )..beforePairingReply = beforePairingReply;
    await server.startServer();
    ownId = LibraryMergeService.deviceId;
    secret = SyncSecurity.randomToken();
    sequence = 0;
    await server.savePairedDevice(
      PairedSyncDevice(deviceId: peerId, name: 'Fixture', secret: secret),
    );
  }

  Future<void> stop() => server.dispose();

  /// The same service again, as after the app was closed and opened.
  Future<void> restart() async {
    await server.dispose();
    server = LocalSyncService.forTesting(pairingNow: () => pairingClock);
    await server.startServer();
  }

  Uri url(String path) =>
      Uri.parse('http://127.0.0.1:${server.serverPort}/api/sync/$path');

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    String? device = peerId,
  }) => http.post(
    url(path),
    headers: {
      'Content-Type': 'application/json',
      if (device != null) 'x-musify-device': device,
    },
    body: jsonEncode(body),
  );

  Future<Map<String, dynamic>> envelope(
    String path,
    Map<String, dynamic> body,
  ) async => {
    'apiVersion': 3,
    'encrypted': await SyncSecurity.seal(secret, {
      ...body,
      'requestId': SyncSecurity.randomToken(24),
      'sequence': ++sequence,
    }, 'api/sync/$path|$peerId|$ownId'),
  };

  Future<({int status, Map<String, dynamic> body})> secure(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await post(path, await envelope(path, body));
    final raw = jsonDecode(response.body) as Map;
    final clear = raw['encrypted'] is Map
        ? await SyncSecurity.open(
            secret,
            raw['encrypted'],
            'api/sync/$path|$ownId|$peerId',
          )
        : Map<String, dynamic>.from(raw);
    return (status: response.statusCode, body: clear);
  }

  /// Asks to pair as [clientId] and builds the proof for the PIN on screen,
  /// or for another PIN when [wrongPin] is set.
  Future<
    ({String session, PinPairingClient client, Map<String, dynamic> proof})
  >
  pair({String clientId = peerId, bool wrongPin = false}) async {
    final response = jsonDecode(
      (await post('pair-request', {
        'apiVersion': 3,
        'clientId': clientId,
        'clientName': 'New fixture',
      }, device: null)).body,
    );
    final session = response['session'] as String;
    final pin = server.incomingPairingRequest.value!.pin;
    final client = await PinPairingClient.create(
      response['challenge'],
      '$clientId|$ownId|$session',
      wrongPin ? (pin == '000000' ? '000001' : '000000') : pin,
    );
    return (session: session, client: client, proof: client.proof());
  }
}
