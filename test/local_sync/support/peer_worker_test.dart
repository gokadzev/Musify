import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musify/services/common_services.dart';
import 'package:musify/services/library_merge_service.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync_service.dart';
import 'package:musify/services/settings_manager.dart';

void main() {
  final role = Platform.environment['MUSIFY_SYNC_TEST_ROLE'];
  final root = Platform.environment['MUSIFY_SYNC_TEST_ROOT'];
  test(
    'independent encrypted sync peer',
    () async {
      final directory = Directory('$root/data-$role');
      await directory.create(recursive: true);
      Hive.init(directory.path);
      for (final name in ['user', 'userNoBackup', 'settings', 'cache']) {
        await Hive.openBox(name);
      }
      await Hive.box('settings').put('localSyncAutomatic', false);
      final service = LocalSyncService.forTesting(
        discovery: () async {
          final peers = <DiscoveredSyncDevice>[];
          for (final other in ['a', 'b', 'c']) {
            final file = File('$root/$other.ready.json');
            if (other == role || !file.existsSync()) continue;
            final info = jsonDecode(file.readAsStringSync());
            peers.add(
              DiscoveredSyncDevice(
                ip: '127.0.0.1',
                port: info['port'],
                name: 'Peer $other',
                deviceId: info['deviceId'],
              ),
            );
          }
          return peers;
        },
      );
      await service.initialise();
      await service.startServer();
      addTearDown(() async {
        LibraryMergeService.fault = null;
        await service.dispose();
        await Hive.close();
      });
      service.incomingPairingRequest.addListener(() {
        final request = service.incomingPairingRequest.value;
        if (request != null) {
          File('$root/$role.pin').writeAsStringSync(request.pin);
        }
      });
      Future<void> ready() async {
        final response = await http.get(
          Uri.parse('http://127.0.0.1:${service.serverPort}/api/sync/info'),
        );
        final info = Map<String, dynamic>.from(jsonDecode(response.body));
        info['port'] = service.serverPort;
        await File('$root/$role.ready.json').writeAsString(jsonEncode(info));
      }

      await ready();
      Future<Map<String, dynamic>> snapshot() async => {
        'library': await LibraryMergeService.exportLibrary(),
        'data': encodeSyncValue(Hive.box('user').toMap()),
        'status': service.state.value.status.name,
        'error': service.state.value.rawError,
        'message': service.state.value.errorMessage,
        'paired': {
          for (final peer in service.pairedDevices.value)
            peer.deviceId: syncDigest(peer.secret),
        },
        'syncStatus': localSyncStatus.value,
        'journal': Hive.box('userNoBackup')
            .containsKey('localSyncPendingMergeV2'),
      };
      var last = 0;
      while (true) {
        final file = File('$root/$role.command.json');
        if (!file.existsSync()) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          continue;
        }
        final command = jsonDecode(file.readAsStringSync()) as Map;
        final sequence = command['sequence'] as int;
        if (sequence <= last) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          continue;
        }
        last = sequence;
        final op = command['op'];
        Object? failure;
        Timer? pinTimer;
        try {
          if (op == 'reset') {
            LibraryMergeService.fault = null;
            listeningStatsService.reload();
            await Hive.box('user').clear();
            await Hive.box('user')
                .putAll(decodeSyncValue(command['data']) as Map);
            await Hive.box('userNoBackup').deleteAll([
              'localSyncDocumentV2',
              'localSyncBaselineV2',
              'localSyncPendingMergeV2',
            ]);
            await service.setCategories(SyncCategory.values.toSet());
            service.resetStatus();
          } else if (op == 'edit') {
            await Hive.box('user')
                .putAll(decodeSyncValue(command['data']) as Map);
            listeningStatsService.reload();
          } else if (op == 'addRadio') {
            await addRadioStationToLiked(command['station'] as String);
          } else if (op == 'clearRecapAndListen') {
            wrappedEnabled.value = true;
            await listeningStatsService.clearStats();
            listeningStatsService.recordListeningTime(
              const Duration(minutes: 1),
            );
            await listeningStatsService.flush();
          } else if (op == 'clearRecap') {
            await listeningStatsService.clearStats();
          } else if (op == 'categories') {
            await service.setCategories(
              parseSyncCategories(command['categories']),
            );
          } else if (op == 'sync') {
            service.resetStatus();
            final targetName = command['target'];
            final info = jsonDecode(
              File('$root/$targetName.ready.json').readAsStringSync(),
            );
            final target = DiscoveredSyncDevice(
              ip: '127.0.0.1',
              port: command['unreachable'] == true ? 1 : info['port'],
              name: 'Peer $targetName',
              deviceId: info['deviceId'],
            );
            pinTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
              if (service.state.value.status == LocalSyncStatus.waitingForPin) {
                final pin = File('$root/$targetName.pin');
                if (pin.existsSync()) service.submitPin(pin.readAsStringSync());
              }
            });
            await service.syncWith(target);
          } else if (op == 'automatic') {
            await Hive.box('settings')
                .putAll({'localSyncEnabled': true, 'localSyncAutomatic': true});
            reloadSettingsFromStorage();
            await service.triggerSilentSync();
            await Hive.box('settings').put('localSyncAutomatic', false);
            reloadSettingsFromStorage();
          } else if (op == 'off') {
            await service.setEnabled(false);
          } else if (op == 'on') {
            await service.setEnabled(true);
            await ready();
          } else if (op == 'crashOnMerge') {
            LibraryMergeService.fault = (stage) async {
              if (stage == 'written') {
                File('$root/$role.crash').writeAsStringSync(stage);
                exit(77);
              }
            };
          }
        } catch (error, stack) {
          failure = '$error\n$stack';
        } finally {
          pinTimer?.cancel();
        }
        final response = {
          ...await snapshot(),
          'sequence': sequence,
          'workerError': failure,
        };
        final temp = File('$root/$role.reply.tmp');
        await temp.writeAsString(jsonEncode(response));
        await temp.rename('$root/$role.reply.json');
        if (op == 'stop') break;
      }
    },
    skip: role == null || root == null
        ? 'Started by the independent-peer controller'
        : false,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
