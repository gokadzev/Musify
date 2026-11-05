import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musify/services/library_merge_service.dart';
import 'package:musify/services/listening_stats_service.dart';
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
  late DateTime pairingClock;
  setUp(() async {
    pairingClock = DateTime(2026, 11, 3);
    listeningStatsService.reload();
    for (final name in ['user', 'userNoBackup', 'settings', 'cache']) {
      await Hive.box(name).clear();
    }
    server = LocalSyncService.forTesting(pairingNow: () => pairingClock);
    await server.startServer();
    ownId = LibraryMergeService.deviceId;
    secret = SyncSecurity.randomToken();
    sequence = 0;
    await server.savePairedDevice(
      PairedSyncDevice(deviceId: peerId, name: 'Fixture', secret: secret),
    );
  });
  tearDown(() async {
    await server.dispose();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    String? device = peerId,
  }) => http.post(
    Uri.parse('http://127.0.0.1:${server.serverPort}/api/sync/$path'),
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

  Future<
    ({String session, PinPairingClient client, Map<String, dynamic> proof})
  >
  pair({bool wrongPin = false}) async {
    final response = jsonDecode(
      (await post('pair-request', {
        'apiVersion': 3,
        'clientId': peerId,
        'clientName': 'New fixture',
      }, device: null)).body,
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
      final forgedMerge = await post('merge', {
        'apiVersion': 3,
        'encrypted': await SyncSecurity.seal(SyncSecurity.randomToken(), {
          'requestId': SyncSecurity.randomToken(24),
          'sequence': 1,
          'library': {
            'likedSongs': [song('injected')],
          },
        }, 'api/sync/merge|$peerId|$ownId'),
      });
      expect(forgedMerge.statusCode, 403);
      expect(forgedMerge.body, isNot(contains('private')));
      expect(
        (Hive.box('user').get('likedSongs') as List).single['ytid'],
        'private',
      );
      final stranger = await post('merge', {}, device: 'stranger');
      expect(stranger.statusCode, 403);
      final forged = await post('capabilities', {
        'apiVersion': 3,
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
    expect(invalid.status, 426);
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

  test('an authenticated merge replies with the merged library', () async {
    expect(Hive.box('settings').get('localSyncLastSyncedAt'), null);
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
    expect(result.body['changed'], contains('likedSongs'));
    expect(
      (result.body['library']['document']['records'] as Map).keys.join(),
      contains('new'),
    );
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
    'repeated incorrect PINs are rate limited even after a restart',
    () async {
      for (var i = 0; i < 5; i++) {
        pairingClock = pairingClock.add(const Duration(seconds: 4));
        final attempt = await pair(wrongPin: true);
        expect(
          (await post('pair-verify', {
            'session': attempt.session,
            'proof': attempt.proof,
          })).statusCode,
          403,
        );
      }
      pairingClock = pairingClock.add(const Duration(seconds: 4));
      final request = {
        'apiVersion': 3,
        'clientId': peerId,
        'clientName': 'Fixture',
      };
      expect(
        (await post('pair-request', request, device: null)).statusCode,
        429,
      );
      await server.dispose();
      server = LocalSyncService.forTesting(pairingNow: () => pairingClock);
      await server.startServer();
      expect(
        (await post('pair-request', request, device: null)).statusCode,
        429,
      );
      pairingClock = pairingClock.add(const Duration(minutes: 6));
      expect(
        (await post('pair-request', request, device: null)).statusCode,
        200,
      );
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

  test('changing categories waits for an incoming merge to finish', () async {
    await server.setCategories({SyncCategory.favourites});
    Future<void>? change;
    LibraryMergeService.fault = (stage) async {
      if (stage == 'prepared') {
        change = server.setCategories({});
        await Future<void>.delayed(Duration.zero);
        expect(server.selectedCategories, contains(SyncCategory.favourites));
      }
    };
    addTearDown(() => LibraryMergeService.fault = null);
    final incoming = payload(
      document({
        'likedSongs': [song('remote')],
      }),
      categories: {SyncCategory.favourites},
    );
    final response = await secure('merge', {
      'categories': ['favourites'],
      'library': incoming,
    });
    expect(response.status, 200);
    expect(change, isNotNull);
    await change;
    expect(server.selectedCategories, isEmpty);
  });

  test('forgetting a device also drops its replay counters', () async {
    expect((await secure('capabilities', {})).status, 200);
    bool hasCounters() =>
        Hive.box('userNoBackup').keys
            .any((key) => key.toString().contains(':$peerId:'));
    expect(hasCounters(), isTrue);
    await server.forgetDevice(peerId);
    expect(hasCounters(), isFalse);
    expect((await secure('capabilities', {})).status, 403);
  });

  test('garbage from another host does not cancel a pending pairing', () async {
    await pair();
    for (final path in ['pair-request', 'pair-verify']) {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:${server.serverPort}/api/sync/$path'),
        headers: {'Content-Type': 'application/json'},
        body: 'not json',
      );
      expect(response.statusCode, 400);
    }
    expect(server.incomingPairingRequest.value, isNotNull);
  });

  test(
    'a malformed message from a paired id is invalid, not untrusted',
    () async {
      final response = await post('capabilities', {
        'apiVersion': 3,
        'encrypted': {'nonce': 'AA==', 'ciphertext': 'AA==', 'mac': 'AA=='},
      });
      expect(response.statusCode, 400);
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
  test(
    'an older peer is rejected before exporting library data and stays paired',
    () async {
      await Hive.box('user').put('likedSongs', [song('private')]);
      final legacy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => legacy.close(force: true));
      final paths = <String>[];
      legacy.listen((request) async {
        paths.add(request.uri.path);
        final raw = jsonDecode(await utf8.decoder.bind(request).join());
        final message = await SyncSecurity.open(
          secret,
          raw['encrypted'],
          'api/sync/capabilities|$ownId|$peerId',
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'encrypted': await SyncSecurity.seal(secret, {
              'requestId': message['requestId'],
              'categories': ['favourites'],
            }, 'api/sync/capabilities|$peerId|$ownId'),
          }),
        );
        await request.response.close();
      });
      await server.syncWith(
        DiscoveredSyncDevice(
          deviceId: peerId,
          name: 'Old peer',
          ip: '127.0.0.1',
          port: legacy.port,
        ),
      );
      expect(paths, ['/api/sync/capabilities']);
      expect(server.state.value.status, LocalSyncStatus.error);
      expect(server.state.value.error, LocalSyncError.updateRequired);
      expect(server.pairedDevices.value.single.secret, secret);
      expect(Hive.box('userNoBackup').get('localSyncDocumentV2'), isNull);
      expect(Hive.box('user').get('likedSongs')[0]['ytid'], 'private');
    },
  );
  test(
    'changing categories waits for an outgoing exchange to finish',
    () async {
      await server.setCategories({SyncCategory.favourites});
      final peer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => peer.close(force: true));
      final arrived = Completer<void>();
      final release = Completer<void>();
      peer.listen((request) async {
        arrived.complete();
        await release.future;
        request.response.statusCode = 503;
        await request.response.close();
      });
      final sync = server.syncWith(
        DiscoveredSyncDevice(
          deviceId: peerId,
          name: 'Fixture',
          ip: '127.0.0.1',
          port: peer.port,
        ),
      );
      await arrived.future;
      final change = server.setCategories({});
      await Future<void>.delayed(Duration.zero);
      expect(server.selectedCategories, contains(SyncCategory.favourites));
      release.complete();
      await sync;
      await change;
      expect(server.selectedCategories, isEmpty);
    },
  );

  test('sync now stops at the first paired device that fails', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();
    await server.savePairedDevice(
      PairedSyncDevice(deviceId: 'second', name: 'Second', secret: secret),
    );
    server.state.value = LocalSyncState(
      discoveredDevices: [
        DiscoveredSyncDevice(
          deviceId: peerId,
          name: 'Fixture',
          ip: '127.0.0.1',
          port: port,
        ),
        DiscoveredSyncDevice(
          deviceId: 'second',
          name: 'Second',
          ip: '127.0.0.1',
          port: port,
        ),
        const DiscoveredSyncDevice(
          deviceId: 'stranger',
          name: 'Not paired',
          ip: '127.0.0.1',
          port: 1,
        ),
      ],
    );

    await server.syncAllNow();

    expect(server.state.value.status, LocalSyncStatus.error);
    expect(server.state.value.activeDevice?.deviceId, peerId);
  });

  test(
    'an interrupted merge that cannot be recovered does not stop sync',
    () async {
      await server.savePairedDevice(
        PairedSyncDevice(deviceId: 'kept', name: 'Kept', secret: secret),
      );
      await server.dispose();
      // A journal the recovery cannot read.
      await Hive.box('userNoBackup')
          .put('localSyncPendingMergeV2', {'user': 1});

      server = LocalSyncService.forTesting(pairingNow: () => pairingClock);
      await server.initialise();

      expect(
        server.pairedDevices.value.map((device) => device.deviceId),
        contains('kept'),
      );
      await Hive.box('userNoBackup').delete('localSyncPendingMergeV2');
    },
  );
}
