import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_pairing.dart';
import 'package:musify/services/local_sync/sync_security.dart';
import 'package:musify/services/local_sync_service.dart';

import 'local_sync/fixtures.dart';

void main() {
  late Directory directory;
  late LocalSyncService server;
  late String ownId;
  late String secret;
  const peerId = 'trusted-fixture';
  var sequence = 0;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp(
      'musify_secure_transport',
    );
    Hive.init(directory.path);
    for (final name in ['user', 'userNoBackup', 'settings', 'cache']) {
      await Hive.openBox(name);
    }
  });
  setUp(() async {
    listeningStatsService.reload();
    for (final name in ['user', 'userNoBackup', 'settings', 'cache']) {
      await Hive.box(name).clear();
    }
    server = LocalSyncService.forTesting();
    await server.startServer();
    final info = jsonDecode(
      (await http.get(
        Uri.parse('http://127.0.0.1:${server.serverPort}/api/sync/info'),
      )).body,
    );
    ownId = info['deviceId'];
    secret = SyncSecurity.randomToken();
    sequence = 0;
    await server.savePairedDevice(
      PairedSyncDevice(
        deviceId: peerId,
        name: 'Fixture',
        ip: '127.0.0.1',
        port: 1,
        secret: secret,
      ),
    );
  });
  tearDown(() async {
    await server.dispose();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<http.Response> post(String path, Map<String, dynamic> body) =>
      http.post(
        Uri.parse('http://127.0.0.1:${server.serverPort}/api/sync/$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
  Future<Map<String, dynamic>> envelope(
    String path,
    Map<String, dynamic> body,
  ) async => {
    'apiVersion': 2,
    'clientId': peerId,
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

  Future<
    ({String session, PinPairingClient client, Map<String, dynamic> proof})
  >
  pair({bool wrongPin = false}) async {
    final response = jsonDecode(
      (await post('pair-request', {
        'apiVersion': 2,
        'pairingVersion': 3,
        'clientId': peerId,
        'clientName': 'New fixture',
        'clientPort': 1,
      })).body,
    );
    final session = response['session'] as String;
    final pin = server.incomingPairingRequest.value!.pin;
    final client = await PinPairingClient.create(
      response['challenge'],
      '$peerId|$ownId|$session',
      wrongPin ? (pin == '000000' ? '000001' : '000000') : pin,
    );
    return (session: session, client: client, proof: client.proof());
  }

  test(
    'declaring a trusted id without its key cannot read or mutate data',
    () async {
      await Hive.box('user').put('likedSongs', [song('private')]);
      final response = await post('merge', {
        'clientId': peerId,
        'library': {
          'likedSongs': [song('injected')],
        },
      });
      expect(response.statusCode, 403);
      expect(response.body, isNot(contains('private')));
      expect(
        (Hive.box('user').get('likedSongs') as List).single['ytid'],
        'private',
      );
      final forged = await post('capabilities', {
        'apiVersion': 2,
        'clientId': peerId,
        'encrypted': await SyncSecurity.seal(SyncSecurity.randomToken(), {
          'requestId': 'wrong',
        }, 'api/sync/capabilities|$peerId|$ownId'),
      });
      expect(forged.statusCode, 403);
    },
  );

  test(
    'authenticated capabilities are encrypted and replays rejected',
    () async {
      final request = await envelope('capabilities', {});
      final first = await post('capabilities', request);
      expect(first.statusCode, 200);
      expect(first.body, isNot(contains('categories')));
      expect((await post('capabilities', request)).statusCode, 403);
    },
  );

  test('a valid key does not bypass schema validation or selection', () async {
    await Hive.box('user').put('likedSongs', [song('keep')]);
    final invalid = await secure('merge', {
      'categories': ['favourites'],
      'library': {'schemaVersion': 999},
    });
    expect(invalid.status, 400);
    await server.setCategories({SyncCategory.recap});
    final excluded = await secure('merge', {
      'categories': ['favourites'],
      'library': payload(
        document({
          'likedSongs': [song('remote')],
        }),
        categories: {SyncCategory.favourites},
      ),
    });
    expect(excluded.status, 409);
    expect((Hive.box('user').get('likedSongs') as List).single['ytid'], 'keep');
  });

  test('receiver records success only after an authenticated receipt acknowledgement', () async {
    final result = await secure('merge', {
      'categories': ['favourites'],
      'library': payload(
        document({
          'likedSongs': [song('new')],
        }),
        categories: {SyncCategory.favourites},
      ),
    });
    expect(result.status, 200);
    expect(Hive.box('settings').get('localSyncLastSyncedAt'), null);
    expect(
      (await secure('confirm', {
        'receipt': result.body['receipt'],
        'digest': 'wrong',
      })).status,
      409,
    );
    expect(Hive.box('settings').get('localSyncLastSyncedAt'), null);
    final confirmation = await secure('confirm', {
      'receipt': result.body['receipt'],
      'digest': syncDigest(result.body['library']),
    });
    expect(confirmation.status, 200);
    expect(confirmation.body['confirmed'], true);
    expect(Hive.box('settings').get('localSyncLastSyncedAt'), isNotNull);
  });

  test(
    're-pairing replaces old trust only after the correct PIN proof',
    () async {
      final attempt = await pair();
      expect(server.pairedDevices.value.single.secret, secret);
      final response = await post('pair-verify', {
        'session': attempt.session,
        'proof': attempt.proof,
      });
      expect(response.statusCode, 200);
      final raw = jsonDecode(response.body);
      expect(
        server.pairedDevices.value.single.secret,
        await attempt.client.verify(raw['proof']),
      );
    },
  );

  test(
    'an incorrect PIN leaves old trust intact and closes the attempt',
    () async {
      final attempt = await pair(wrongPin: true);
      final completed = server.incomingPairingRequest.value!.completed;
      expect(
        (await post('pair-verify', {
          'session': attempt.session,
          'proof': attempt.proof,
        })).statusCode,
        403,
      );
      expect(await completed, false);
      expect(server.pairedDevices.value.single.secret, secret);
    },
  );

  test(
    'rejecting a request preserves existing trust and completes the dialog',
    () async {
      final attempt = await pair();
      final completed = server.incomingPairingRequest.value!.completed;
      server.rejectIncomingPairing();
      expect(await completed, false);
      expect(
        (await post('pair-verify', {
          'session': attempt.session,
          'proof': attempt.proof,
        })).statusCode,
        403,
      );
      expect(server.pairedDevices.value.single.secret, secret);
    },
  );

  test('turning sync off cancels a pending pairing', () async {
    await pair();
    final completed = server.incomingPairingRequest.value!.completed;
    await server.stopServer();
    expect(await completed, false);
    expect(server.serverRunning.value, false);
    expect(server.pairedDevices.value.single.secret, secret);
  });
  test(
    'embedded playlist covers larger than one MiB survive encrypted HTTP sync',
    () async {
      final image = 'data:image/png;base64,${List.filled(3700000, 'A').join()}';
      final incoming = payload(
        document({
          'customPlaylists': [
            {
              ...playlist('cover', ['a']),
              'image': image,
            },
          ],
        }),
      );
      final result = await secure('merge', {
        'categories': incoming['categories'],
        'library': incoming,
      });
      expect(result.status, 200);
      expect(Hive.box('user').get('customPlaylists')[0]['image'], image);
      // A second request reads the persisted document, the failing path in the report.
      final repeated = await secure('merge', {
        'categories': incoming['categories'],
        'library': incoming,
      });
      expect(repeated.status, 200);
      expect(
        repeated.body['library']['document'],
        result.body['library']['document'],
      );
    },
  );
}
