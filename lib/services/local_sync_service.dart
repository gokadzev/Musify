/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_multicast_lock/flutter_multicast_lock.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musify/main.dart';
import 'package:musify/services/library_merge_service.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_pairing.dart';
import 'package:musify/services/local_sync/sync_security.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// Another Musify instance that answered a discovery broadcast.
class DiscoveredSyncDevice {
  const DiscoveredSyncDevice({
    required this.ip,
    required this.port,
    required this.name,
    required this.deviceId,
  });

  final String ip;
  final int port;
  final String name;
  final String deviceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredSyncDevice &&
          ip == other.ip &&
          port == other.port &&
          deviceId == other.deviceId;

  @override
  int get hashCode => Object.hash(ip, port, deviceId);
}

/// A device this one has exchanged a pairing PIN with. The address is only a
/// hint for the UI: syncing always goes through a fresh discovery.
class PairedSyncDevice {
  const PairedSyncDevice({
    required this.deviceId,
    required this.name,
    required this.ip,
    required this.port,
    this.secret = '',
  });

  factory PairedSyncDevice.fromMap(Map map) => PairedSyncDevice(
    deviceId: map['deviceId']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Unknown device',
    ip: map['ip']?.toString() ?? '',
    port: map['port'] is num ? (map['port'] as num).toInt() : 0,
    secret: map['secret']?.toString() ?? '',
  );

  final String deviceId;
  final String name;
  final String ip;
  final int port;
  final String secret;

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'name': name,
    'ip': ip,
    'port': port,
    'secret': secret,
  };
}

/// A pairing attempt started by another device. The PIN must be shown on this
/// device so the user can type it on the other one.
class IncomingPairingRequest {
  IncomingPairingRequest({
    required this.clientName,
    required this.pin,
    required this.completed,
  });

  final String clientName;
  final String pin;

  /// Resolves to `true` once the other device verified the PIN, `false` when
  /// it was rejected here or timed out.
  final Future<bool> completed;
}

enum LocalSyncStatus { idle, scanning, syncing, waitingForPin, success, error }

/// Where a sync run is, in order. The UI maps these to progress.
enum LocalSyncStage { exporting, exchanging, merging, finalizing }

class LocalSyncState {
  const LocalSyncState({
    this.status = LocalSyncStatus.idle,
    this.discoveredDevices = const [],
    this.activeDevice,
    this.stage,
    this.stats,
    this.errorMessage,
    this.rawError,
  });

  final LocalSyncStatus status;
  final List<DiscoveredSyncDevice> discoveredDevices;

  /// The device the current sync or pairing is talking to.
  final DiscoveredSyncDevice? activeDevice;
  final LocalSyncStage? stage;
  final Map<String, int>? stats;
  final String? errorMessage;
  final String? rawError;

  LocalSyncState copyWith({
    LocalSyncStatus? status,
    List<DiscoveredSyncDevice>? discoveredDevices,
    DiscoveredSyncDevice? activeDevice,
    LocalSyncStage? stage,
    Map<String, int>? stats,
    String? errorMessage,
    String? rawError,
    bool clearActiveDevice = false,
    bool clearStage = false,
    bool clearStats = false,
    bool clearError = false,
  }) {
    return LocalSyncState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      activeDevice: clearActiveDevice
          ? null
          : (activeDevice ?? this.activeDevice),
      stage: clearStage ? null : (stage ?? this.stage),
      stats: clearStats ? null : (stats ?? this.stats),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rawError: clearError ? null : (rawError ?? this.rawError),
    );
  }
}

/// Peer-to-peer library sync between Musify devices on the same network.
///
/// No server in the middle: every device with local sync turned on runs a
/// small HTTP server on a random port and answers UDP discovery broadcasts on
/// [discoveryPort]. A first contact between two devices is confirmed with a
/// PIN shown on the receiving device; after that either side can push its
/// library to the other, which merges it and answers with its own merged
/// library, so one round trip leaves both devices with the same content.
class LocalSyncService {
  LocalSyncService._() : _testDiscovery = null;

  /// A throwaway instance for tests that talk to each other over loopback.
  @visibleForTesting
  LocalSyncService.forTesting({
    Future<List<DiscoveredSyncDevice>> Function()? discovery,
  }) : _testDiscovery = discovery;

  static final LocalSyncService instance = LocalSyncService._();

  static const int discoveryPort = 53531;
  static const int apiVersion = 2;
  static const Duration autoSyncInterval = Duration(minutes: 30);
  static const Duration _startupSyncDelay = Duration(seconds: 6);
  static const Duration _localChangeDebounce = Duration(seconds: 30);
  static const Duration _pairingTimeout = Duration(seconds: 60);
  static const Duration _shortTimeout = Duration(seconds: 12);
  static const Duration _mergeTimeout = Duration(seconds: 45);

  static const String _discoveryRequest = 'MUSIFY_DISCOVERY_REQUEST';
  static const String _discoveryResponse = 'MUSIFY_DISCOVERY_RESPONSE';

  static const String _deviceIdKey = 'localSyncDeviceId';
  static const String _pairedDevicesKey = 'localSyncPairedDevices';
  static const String _enabledKey = 'localSyncEnabled';
  static const String _automaticKey = 'localSyncAutomatic';
  static const String _lastSyncedAtKey = 'localSyncLastSyncedAt';

  final ValueNotifier<LocalSyncState> state = ValueNotifier(
    const LocalSyncState(),
  );
  final ValueNotifier<List<PairedSyncDevice>> pairedDevices = ValueNotifier(
    const [],
  );
  final ValueNotifier<IncomingPairingRequest?> incomingPairingRequest =
      ValueNotifier(null);
  final ValueNotifier<bool> serverRunning = ValueNotifier(false);

  final Future<List<DiscoveredSyncDevice>> Function()? _testDiscovery;
  final http.Client _client = http.Client();
  final FlutterMulticastLock _multicastLock = FlutterMulticastLock();

  HttpServer? _httpServer;
  RawDatagramSocket? _udpSocket;
  StreamSubscription<BoxEvent>? _userBoxSubscription;
  Timer? _periodicTimer;
  Timer? _startupTimer;
  Timer? _localChangeTimer;
  bool _initialised = false;
  bool _silentSyncRunning = false;

  Completer<String?>? _pinInputCompleter;

  // Pending pairing on the receiving side.
  String? _pendingClientId;
  String? _pendingClientName;
  int? _pendingClientPort;
  PinPairingReceiver? _pendingPairing;
  String? _pendingSession;
  DateTime? _lastPairingRequest;
  final Map<String, DateTime> _retryAfter = {};
  final Map<String, int> _retryCount = {};
  final Map<String, String> _receipts = {};
  Completer<bool>? _pendingCompleter;
  Timer? _pendingTimer;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS);

  int? get serverPort => _httpServer?.port;

  String get deviceName {
    if (Platform.isAndroid) return 'Musify (Android)';
    if (Platform.isIOS) return 'Musify (iOS)';
    final user =
        Platform.environment['USER'] ??
        Platform.environment['USERNAME'] ??
        Platform.environment['LOGNAME'];
    final os = Platform.isLinux
        ? 'Linux'
        : Platform.isWindows
        ? 'Windows'
        : Platform.isMacOS
        ? 'macOS'
        : Platform.operatingSystem;
    if (user != null && user.trim().isNotEmpty) {
      return 'Musify ($user - $os)';
    }
    return 'Musify ($os)';
  }

  Future<void> initialise() async {
    if (_initialised || !isSupportedPlatform) return;
    _initialised = true;

    await LibraryMergeService.recoverPendingMerge();
    _loadPairedDevices();
    await _ensureDeviceId();

    if (localSyncEnabled.value) {
      try {
        await startServer();
        localSyncStatus.value = 'Discoverable as $deviceName';
      } catch (e) {
        localSyncStatus.value = 'Could not start local sync: $e';
      }
    }

    await rebindStorageListeners();
    _periodicTimer = Timer.periodic(
      autoSyncInterval,
      (_) => unawaited(triggerSilentSync()),
    );
    _startupTimer = Timer(
      _startupSyncDelay,
      () => unawaited(triggerSilentSync()),
    );
  }

  /// Re-subscribes to the `user` box. A backup restore closes and reopens
  /// the Hive boxes, which silently ends the previous subscription.
  Future<void> rebindStorageListeners() async {
    await _userBoxSubscription?.cancel();
    _userBoxSubscription = Hive.box('user').watch().listen(_onLocalChange);
  }

  Future<void> pauseForStorageRestore() async {
    _localChangeTimer?.cancel();
    await stopServer();
    await Future.wait(_outbound.values.toList());
    await LibraryMergeService.awaitIdle();
  }

  Future<void> resumeAfterStorageRestore() async {
    reloadSettingsFromStorage();
    await rebindStorageListeners();
    if (localSyncEnabled.value) await startServer();
  }

  Future<void> dispose() async {
    _periodicTimer?.cancel();
    _startupTimer?.cancel();
    _localChangeTimer?.cancel();
    await _userBoxSubscription?.cancel();
    _cancelPendingPairing();
    await stopServer();
    _client.close();
  }

  Future<({String message, bool success})> setEnabled(bool enabled) async {
    if (!isSupportedPlatform) {
      return (
        message: 'Local sync is not available on this platform',
        success: false,
      );
    }

    await Hive.box('settings').put(_enabledKey, enabled);
    reloadSettingsFromStorage();

    if (!enabled) {
      _localChangeTimer?.cancel();
      await stopServer();
      localSyncStatus.value = 'Local sync is off';
      return (message: 'Local sync turned off', success: true);
    }

    try {
      await startServer();
    } catch (e) {
      await Hive.box('settings').put(_enabledKey, false);
      reloadSettingsFromStorage();
      localSyncStatus.value = 'Could not start local sync';
      return (message: 'Could not start local sync: $e', success: false);
    }

    localSyncStatus.value = 'Discoverable as $deviceName';
    unawaited(triggerSilentSync());
    return (message: 'Local sync turned on', success: true);
  }

  Future<void> setAutomatic(bool enabled) async {
    await Hive.box('settings').put(_automaticKey, enabled);
    reloadSettingsFromStorage();
    if (enabled) {
      unawaited(triggerSilentSync());
    } else {
      _localChangeTimer?.cancel();
    }
  }

  bool isDevicePaired(String deviceId) =>
      deviceId.isNotEmpty &&
      pairedDevices.value.any(
        (device) => device.deviceId == deviceId && device.secret.isNotEmpty,
      );

  Future<void> savePairedDevice(PairedSyncDevice device) async {
    final updated = List<PairedSyncDevice>.from(pairedDevices.value)
      ..removeWhere((item) => item.deviceId == device.deviceId)
      ..add(device);
    await _storePairedDevices(updated);
  }

  Future<void> forgetDevice(String deviceId) async {
    final updated = List<PairedSyncDevice>.from(pairedDevices.value)
      ..removeWhere((item) => item.deviceId == deviceId);
    await _storePairedDevices(updated);
  }

  Future<void> forgetAllDevices() async {
    await _storePairedDevices(const []);
  }

  void _loadPairedDevices() {
    final raw = Hive.box('userNoBackup').get(_pairedDevicesKey);
    pairedDevices.value = raw is List
        ? raw
              .whereType<Map>()
              .map(PairedSyncDevice.fromMap)
              .where((device) => device.deviceId.isNotEmpty)
              .toList()
        : const [];
  }

  Future<void> _storePairedDevices(List<PairedSyncDevice> devices) async {
    await Hive.box('userNoBackup')
        .put(_pairedDevicesKey, devices.map((d) => d.toMap()).toList());
    pairedDevices.value = List.unmodifiable(devices);
  }

  Future<String> _ensureDeviceId() async {
    final box = Hive.box('userNoBackup');
    final existing = box.get(_deviceIdKey, defaultValue: '').toString();
    if (existing.isNotEmpty) return existing;

    final random = Random.secure();
    final id = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await box.put(_deviceIdKey, id);
    return id;
  }

  Future<void> startServer() async {
    if (_httpServer != null) return;

    try {
      final router = Router()
        ..get('/api/sync/info', _handleInfo)
        ..post('/api/sync/pair-request', _handlePairRequest)
        ..post('/api/sync/pair-verify', _handlePairVerify)
        ..post('/api/sync/capabilities', _handleCapabilities)
        ..post('/api/sync/confirm', _handleConfirm)
        ..post('/api/sync/merge', _handleMerge);

      _httpServer = await shelf_io.serve(
        router.call,
        InternetAddress.anyIPv4,
        0,
      );

      if (Platform.isAndroid) {
        await _acquireMulticastLock();
      }

      // Another instance on this machine may already own the discovery port.
      // Incoming syncs still work then; this device just cannot be found by
      // a broadcast.
      try {
        _udpSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          discoveryPort,
        );
        _udpSocket!.listen(_onDiscoveryDatagram);
      } on SocketException catch (e) {
        logger.log('Local sync discovery port $discoveryPort unavailable: $e');
      }

      serverRunning.value = true;
      logger.log(
        'Local sync server listening on port ${_httpServer!.port}, '
        'discovery on UDP $discoveryPort',
      );
    } catch (e, stackTrace) {
      logger.log(
        'Local sync server failed to start',
        error: e,
        stackTrace: stackTrace,
      );
      await stopServer();
      rethrow;
    }
  }

  Future<void> stopServer() async {
    _cancelPendingPairing();
    cancelPinInput();
    _udpSocket?.close();
    _udpSocket = null;

    if (Platform.isAndroid) {
      await _releaseMulticastLock();
    }

    final server = _httpServer;
    _httpServer = null;
    if (server != null) {
      await server.close(force: true);
    }

    serverRunning.value = false;
  }

  void _onDiscoveryDatagram(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _udpSocket?.receive();
    final server = _httpServer;
    if (datagram == null || server == null) return;

    String message;
    try {
      message = utf8.decode(datagram.data);
    } on FormatException {
      return;
    }
    if (message != _discoveryRequest) return;

    unawaited(() async {
      final deviceId = await _ensureDeviceId();
      final response =
          '$_discoveryResponse;${deviceName.replaceAll(';', ' ')};'
          '${server.port};$deviceId';
      _udpSocket?.send(utf8.encode(response), datagram.address, datagram.port);
    }());
  }

  Future<shelf.Response> _handleInfo(shelf.Request request) async {
    return _json({
      'name': deviceName,
      'platform': Platform.operatingSystem,
      'pairingVersion': 3,
      'apiVersion': apiVersion,
      'deviceId': await _ensureDeviceId(),
    });
  }

  Set<SyncCategory> get selectedCategories {
    final raw = Hive.box('settings').get('localSyncCategories');
    if (raw == null) return SyncCategory.values.toSet();
    if (raw is! List) return {};
    return SyncCategory.values
        .where((value) => raw.contains(value.name))
        .toSet();
  }

  Future<void> setCategories(Set<SyncCategory> categories) async {
    await Hive.box('settings')
        .put('localSyncCategories', categories.map((e) => e.name).toList());
    if (categories.isNotEmpty) unawaited(triggerSilentSync());
  }

  Future<shelf.Response> _handlePairRequest(shelf.Request request) async {
    try {
      final data = await _readJson(request);
      if (data['apiVersion'] != apiVersion || data['pairingVersion'] != 3)
        return _json({'error': 'upgrade_required'}, status: 426);
      final id = data['clientId'];
      if (id is! String || id.isEmpty || id.length > 128)
        return _json({'error': 'invalid_pairing'}, status: 400);
      final now = DateTime.now();
      if (_pendingSession != null ||
          (_lastPairingRequest != null &&
              now.difference(_lastPairingRequest!) <
                  const Duration(seconds: 3)))
        return _json({'error': 'pairing_busy'}, status: 429);
      _lastPairingRequest = now;
      _pendingClientId = id;
      final name = data['clientName']?.toString() ?? 'Musify';
      _pendingClientName = name.substring(0, min(100, name.length));
      _pendingClientPort = data['clientPort'] is int ? data['clientPort'] : 0;
      final session = SyncSecurity.randomToken(16);
      _pendingSession = session;
      _pendingCompleter = Completer<bool>();
      _pendingTimer = Timer(_pairingTimeout, _cancelPendingPairing);
      final ownId = await _ensureDeviceId();
      final pairing = await PinPairingReceiver.create('$id|$ownId|$session');
      if (_pendingSession != session)
        return _json({'error': 'pairing_expired'}, status: 403);
      _pendingPairing = pairing;
      incomingPairingRequest.value = IncomingPairingRequest(
        clientName: _pendingClientName!,
        pin: pairing.pin,
        completed: _pendingCompleter!.future,
      );
      return _json({
        'status': 'pairing_started',
        'session': session,
        'challenge': pairing.challenge,
        'deviceId': ownId,
      });
    } catch (_) {
      return _json({'error': 'invalid_pairing'}, status: 400);
    }
  }

  Future<shelf.Response> _handlePairVerify(shelf.Request request) async {
    try {
      final data = await _readJson(request);
      final session = _pendingSession;
      final pairing = _pendingPairing;
      if (session == null ||
          pairing == null ||
          data['session'] != session ||
          data['proof'] is! Map)
        return _json({'error': 'pairing_expired'}, status: 403);
      final agreement = await pairing.verify(data['proof']);
      if (_pendingSession != session)
        return _json({'error': 'pairing_cancelled'}, status: 403);
      final connection =
          request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      await savePairedDevice(
        PairedSyncDevice(
          deviceId: _pendingClientId!,
          name: _pendingClientName!,
          ip: connection?.remoteAddress.address ?? '',
          port: _pendingClientPort ?? 0,
          secret: agreement.secret,
        ),
      );
      final confirmation = await SyncSecurity.seal(agreement.secret, {
        'status': 'paired',
        'deviceId': await _ensureDeviceId(),
        'deviceName': deviceName,
      }, 'pair:$session:reply');
      final completer = _pendingCompleter;
      _clearPendingPairing();
      if (completer != null && !completer.isCompleted) completer.complete(true);
      return _json({'proof': agreement.proof, 'confirmation': confirmation});
    } catch (_) {
      _cancelPendingPairing();
      return _json({'error': 'incorrect_pin'}, status: 403);
    }
  }

  Future<({Map<String, dynamic> body, String secret, String id, String nonce})>
  _authenticated(shelf.Request request) async {
    final data = await _readJson(request);
    if (data['apiVersion'] != apiVersion)
      throw const FormatException('upgrade_required');
    final id = data['clientId']?.toString() ?? '';
    final peer = pairedDevices.value
        .where((e) => e.deviceId == id && e.secret.isNotEmpty)
        .firstOrNull;
    if (peer == null || data['encrypted'] is! Map)
      throw const FormatException('not_paired');
    final context = '${request.url.path}|$id|${await _ensureDeviceId()}';
    final body = await SyncSecurity.open(
      peer.secret,
      data['encrypted'],
      context,
    );
    final nonce = body['requestId'];
    if (nonce is! String || nonce.length < 20 || nonce.length > 128)
      throw const FormatException('invalid_request');
    final store = Hive.box('userNoBackup');
    final counterKey = 'localSyncReceived:$id:${syncDigest(peer.secret)}';
    final sequence = body['sequence'];
    if (sequence is! int ||
        sequence <= (store.get(counterKey, defaultValue: 0) as int))
      throw const FormatException('replayed_request');
    await store.put(counterKey, sequence);
    await store.flush();
    return (body: body, secret: peer.secret, id: id, nonce: nonce);
  }

  Future<shelf.Response> _encryptedReply(
    shelf.Request request,
    String secret,
    String id,
    String nonce,
    Map<String, dynamic> body,
  ) async {
    final context = '${request.url.path}|${await _ensureDeviceId()}|$id';
    return _json({
      'encrypted': await SyncSecurity.seal(secret, {
        ...body,
        'requestId': nonce,
      }, context),
    });
  }

  Future<shelf.Response> _handleCapabilities(shelf.Request request) async {
    try {
      final auth = await _authenticated(request);
      return await _encryptedReply(request, auth.secret, auth.id, auth.nonce, {
        'schemaVersion': LibraryMergeService.schemaVersion,
        'categories': selectedCategories.map((e) => e.name).toList(),
      });
    } catch (_) {
      return _json({'error': 'pair_or_update_both_devices'}, status: 403);
    }
  }

  Future<shelf.Response> _handleMerge(shelf.Request request) async {
    late ({Map<String, dynamic> body, String secret, String id, String nonce})
    auth;
    try {
      auth = await _authenticated(request);
    } catch (_) {
      return _json({'error': 'pair_or_update_both_devices'}, status: 403);
    }
    try {
      final categories = parseSyncCategories(auth.body['categories']);
      if (!selectedCategories.containsAll(categories) || categories.isEmpty)
        return _json({'error': 'categories_changed'}, status: 409);
      if (auth.body['library'] is! Map)
        return _json({'error': 'library_missing'}, status: 400);
      if (auth.body['library']['schemaVersion'] !=
          LibraryMergeService.schemaVersion)
        return _json({'error': 'upgrade_required'}, status: 426);
      if (_httpServer == null) throw StateError('Local sync is off');
      final stats = await LibraryMergeService.mergeLibrary(
        Map<String, dynamic>.from(auth.body['library']),
        categories: categories,
      );
      final library = await LibraryMergeService.exportLibrary(
        categories: categories,
      );
      final receipt = SyncSecurity.randomToken(16);
      _receipts['${auth.id}:$receipt'] = syncDigest(library);
      if (_receipts.length > 128) _receipts.remove(_receipts.keys.first);
      if (stats.isNotEmpty) _scheduleLocalSync();
      return await _encryptedReply(request, auth.secret, auth.id, auth.nonce, {
        'library': library,
        'stats': stats,
        'receipt': receipt,
      });
    } catch (e, stack) {
      logger.log('Local sync request rejected', error: e, stackTrace: stack);
      return _json({'error': 'invalid_or_unauthenticated_sync'}, status: 400);
    }
  }

  Future<shelf.Response> _handleConfirm(shelf.Request request) async {
    try {
      final auth = await _authenticated(request);
      final key = '${auth.id}:${auth.body['receipt']}';
      final expected = _receipts[key];
      if (expected == null || auth.body['digest'] != expected)
        return _json({'error': 'unknown_receipt'}, status: 409);
      _receipts.remove(key);
      await _recordSync(
        pairedDevices.value.firstWhere((e) => e.deviceId == auth.id).name,
        {},
      );
      return await _encryptedReply(request, auth.secret, auth.id, auth.nonce, {
        'confirmed': true,
      });
    } catch (_) {
      return _json({'error': 'invalid_confirmation'}, status: 403);
    }
  }

  /// Rejects the pairing request currently shown on this device, if any.
  void rejectIncomingPairing() => _cancelPendingPairing();

  void _cancelPendingPairing() {
    final completer = _pendingCompleter;
    _clearPendingPairing();
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
  }

  void _clearPendingPairing() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingClientId = null;
    _pendingClientName = null;
    _pendingClientPort = null;
    _pendingPairing = null;
    _pendingSession = null;
    _pendingCompleter = null;
    incomingPairingRequest.value = null;
  }

  /// Broadcasts a discovery request and collects the answers for [duration].
  Future<List<DiscoveredSyncDevice>> discoverDevices({
    Duration duration = const Duration(seconds: 4),
  }) async {
    if (_testDiscovery != null) return _testDiscovery();
    final discovered = <DiscoveredSyncDevice>[];
    state.value = state.value.copyWith(discoveredDevices: const []);

    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? subscription;
    final ownDeviceId = await _ensureDeviceId();

    try {
      if (Platform.isAndroid) {
        await _acquireMulticastLock();
      }

      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        ..broadcastEnabled = true;

      subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket?.receive();
        if (datagram == null) return;

        String message;
        try {
          message = utf8.decode(datagram.data);
        } on FormatException {
          return;
        }
        if (!message.startsWith(_discoveryResponse)) return;

        final parts = message.split(';');
        if (parts.length < 4) return;
        final port = int.tryParse(parts[2]);
        if (port == null) return;

        final device = DiscoveredSyncDevice(
          ip: datagram.address.address,
          port: port,
          name: parts[1],
          deviceId: parts[3],
        );

        // Our own server answers the broadcast too.
        if (device.deviceId == ownDeviceId) return;
        if (discovered.any((d) => d.deviceId == device.deviceId)) return;

        discovered.add(device);
        state.value = state.value.copyWith(
          discoveredDevices: List.unmodifiable(discovered),
        );
      });

      final payload = utf8.encode(_discoveryRequest);
      for (final address in await _broadcastAddresses()) {
        try {
          socket.send(payload, address, discoveryPort);
        } catch (e) {
          logger.log('Discovery broadcast to ${address.address} failed: $e');
        }
      }

      await Future.delayed(duration);
    } catch (e, stackTrace) {
      logger.log(
        'Local sync discovery failed',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      await subscription?.cancel();
      socket?.close();
      if (Platform.isAndroid && _httpServer == null) {
        await _releaseMulticastLock();
      }
    }

    return discovered;
  }

  /// Runs a discovery for the UI, keeping [state] in sync with the scan.
  Future<void> startDiscovery() async {
    if (state.value.status == LocalSyncStatus.syncing ||
        state.value.status == LocalSyncStatus.waitingForPin) {
      return;
    }
    state.value = state.value.copyWith(
      status: LocalSyncStatus.scanning,
      clearError: true,
      clearStats: true,
      clearStage: true,
      clearActiveDevice: true,
    );
    await discoverDevices();
    if (state.value.status == LocalSyncStatus.scanning) {
      state.value = state.value.copyWith(status: LocalSyncStatus.idle);
    }
  }

  /// Pairs with [device] if needed (asking the UI for the PIN through
  /// [submitPin]) and then runs a two-way sync with it.
  Future<void> syncWith(DiscoveredSyncDevice device) async {
    if (state.value.status == LocalSyncStatus.syncing ||
        state.value.status == LocalSyncStatus.waitingForPin) {
      return;
    }

    state.value = state.value.copyWith(
      status: LocalSyncStatus.syncing,
      activeDevice: device,
      clearError: true,
      clearStats: true,
      clearStage: true,
    );

    var pairing = false;
    try {
      if (_httpServer == null) {
        throw const _LocalSyncException(
          'Turn on local sync on this device first',
        );
      }

      if (!isDevicePaired(device.deviceId)) {
        pairing = true;
        final status = await _requestPairing(device);
        if (status == 'pairing_started') {
          state.value = state.value.copyWith(
            status: LocalSyncStatus.waitingForPin,
          );
          _pinInputCompleter = Completer<String?>();
          final pin = await _pinInputCompleter!.future.timeout(
            _pairingTimeout,
            onTimeout: () => null,
          );
          _pinInputCompleter = null;

          if (pin == null || pin.trim().isEmpty) {
            state.value = state.value.copyWith(
              status: LocalSyncStatus.idle,
              clearActiveDevice: true,
            );
            return;
          }

          state.value = state.value.copyWith(status: LocalSyncStatus.syncing);
          final paired = await _verifyPairing(device, pin.trim());
          if (!paired) {
            throw const _LocalSyncException('incorrect_pin');
          }
        } else if (status != 'already_paired') {
          throw _LocalSyncException('Unexpected pairing status: $status');
        }
      }

      pairing = false;
      final stats = await _performSync(
        device,
        onStage: (stage) {
          state.value = state.value.copyWith(stage: stage);
        },
      );

      await savePairedDevice(
        PairedSyncDevice(
          deviceId: device.deviceId,
          name: device.name,
          ip: device.ip,
          port: device.port,
          secret: pairedDevices.value
              .firstWhere((e) => e.deviceId == device.deviceId)
              .secret,
        ),
      );
      await _recordSync(device.name, stats);

      state.value = state.value.copyWith(
        status: LocalSyncStatus.success,
        stats: stats,
        clearStage: true,
      );
    } catch (e, stackTrace) {
      logger.log(
        'Local sync with ${device.name} failed',
        error: e,
        stackTrace: stackTrace,
      );
      state.value = state.value.copyWith(
        status: LocalSyncStatus.error,
        errorMessage: await _friendlyError(e, device, pairing: pairing),
        rawError: e.toString(),
        clearStage: true,
      );
    }
  }

  void submitPin(String pin) {
    final completer = _pinInputCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(pin);
    }
  }

  void cancelPinInput() {
    final completer = _pinInputCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(null);
    }
  }

  /// Back to the device list after a success or error screen.
  void resetStatus() {
    if (state.value.status == LocalSyncStatus.syncing ||
        state.value.status == LocalSyncStatus.waitingForPin) {
      return;
    }
    state.value = state.value.copyWith(
      status: LocalSyncStatus.idle,
      clearError: true,
      clearStats: true,
      clearStage: true,
      clearActiveDevice: true,
    );
  }

  /// Syncs with every paired device that answers a short discovery. Runs in
  /// the background with no UI beyond [localSyncStatus].
  Future<void> triggerSilentSync() async {
    if (_silentSyncRunning ||
        !localSyncEnabled.value ||
        !localSyncAutomatic.value ||
        offlineMode.value ||
        _httpServer == null ||
        pairedDevices.value.isEmpty) {
      return;
    }
    if (state.value.status != LocalSyncStatus.idle &&
        state.value.status != LocalSyncStatus.success &&
        state.value.status != LocalSyncStatus.error) {
      return;
    }

    _silentSyncRunning = true;
    try {
      final discovered = await discoverDevices(
        duration: const Duration(seconds: 2),
      );
      if (discovered.where((d) => isDevicePaired(d.deviceId)).isEmpty)
        localSyncStatus.value = 'Waiting for paired devices on this network';
      for (var pass = 0; pass < 2; pass++) {
        for (final device in discovered) {
          if (!isDevicePaired(device.deviceId) ||
              (_retryAfter[device.deviceId]?.isAfter(DateTime.now()) ?? false))
            continue;
          try {
            final stats = await _performSync(device);
            await savePairedDevice(
              PairedSyncDevice(
                deviceId: device.deviceId,
                name: device.name,
                ip: device.ip,
                port: device.port,
                secret: pairedDevices.value
                    .firstWhere((e) => e.deviceId == device.deviceId)
                    .secret,
              ),
            );
            await _recordSync(device.name, stats);
          } catch (e) {
            logger.log('Automatic local sync with ${device.name} failed: $e');
            final count = (_retryCount[device.deviceId] ?? 0) + 1;
            _retryCount[device.deviceId] = count;
            _retryAfter[device.deviceId] = DateTime.now().add(
              Duration(seconds: min(1800, 30 * pow(2, min(count, 6)).toInt())),
            );
            localSyncStatus.value =
                'Waiting for ${device.name}; pairing and local data are preserved';
          }
        }
      }
    } finally {
      _silentSyncRunning = false;
    }
  }

  String? _outgoingSession;
  Map<String, dynamic>? _outgoingChallenge;
  String? _outgoingTarget;
  DateTime? _outgoingExpires;

  Future<String> _requestPairing(DiscoveredSyncDevice target) async {
    if (_outgoingTarget == target.deviceId &&
        _outgoingChallenge != null &&
        (_outgoingExpires?.isAfter(DateTime.now()) ?? false))
      return 'pairing_started';
    final response = await _post(target, '/api/sync/pair-request', {
      'apiVersion': apiVersion,
      'pairingVersion': 3,
      'clientId': await _ensureDeviceId(),
      'clientName': deviceName,
      'clientPort': serverPort,
    }, timeout: _shortTimeout);
    if (response['deviceId'] != target.deviceId ||
        response['session'] is! String ||
        response['challenge'] is! Map)
      throw const _LocalSyncException('Update both devices before pairing.');
    _outgoingSession = response['session'];
    _outgoingTarget = target.deviceId;
    _outgoingExpires = DateTime.now().add(_pairingTimeout);
    _outgoingChallenge = Map<String, dynamic>.from(response['challenge']);
    return 'pairing_started';
  }

  Future<bool> _verifyPairing(DiscoveredSyncDevice target, String pin) async {
    final session = _outgoingSession!;
    final pairing = await PinPairingClient.create(
      _outgoingChallenge!,
      '${await _ensureDeviceId()}|${target.deviceId}|$session',
      pin,
    );
    _outgoingChallenge = null;
    final response = await _post(target, '/api/sync/pair-verify', {
      'session': session,
      'proof': pairing.proof(),
    }, timeout: _pairingTimeout);
    final secret = await pairing.verify(response['proof']);
    final proof = await SyncSecurity.open(
      secret,
      response['confirmation'],
      'pair:$session:reply',
    );
    if (proof['deviceId'] != target.deviceId || proof['status'] != 'paired')
      return false;
    await savePairedDevice(
      PairedSyncDevice(
        deviceId: target.deviceId,
        name: proof['deviceName']?.toString() ?? target.name,
        ip: target.ip,
        port: target.port,
        secret: secret,
      ),
    );
    _outgoingSession = null;
    _outgoingTarget = null;
    _outgoingExpires = null;
    return true;
  }

  Future<Map<String, dynamic>> _securePost(
    DiscoveredSyncDevice target,
    String path,
    Map<String, dynamic> body,
  ) async {
    final peer = pairedDevices.value.firstWhere(
      (e) => e.deviceId == target.deviceId && e.secret.isNotEmpty,
    );
    if (_httpServer == null)
      throw const _LocalSyncException('Local sync is off.');
    final ownId = await _ensureDeviceId();
    final nonce = SyncSecurity.randomToken(24);
    final counterKey =
        'localSyncSent:${target.deviceId}:${syncDigest(peer.secret)}';
    final store = Hive.box('userNoBackup');
    final sequence = (store.get(counterKey, defaultValue: 0) as int) + 1;
    await store.put(counterKey, sequence);
    await store.flush();
    final encrypted = await SyncSecurity.seal(peer.secret, {
      ...body,
      'requestId': nonce,
      'sequence': sequence,
    }, '${path.substring(1)}|$ownId|${target.deviceId}');
    final response = await _post(target, path, {
      'apiVersion': apiVersion,
      'clientId': ownId,
      'encrypted': encrypted,
    }, timeout: _mergeTimeout);
    if (response['encrypted'] is! Map)
      throw const _LocalSyncException('Update and pair both devices again.');
    final result = await SyncSecurity.open(
      peer.secret,
      response['encrypted'],
      '${path.substring(1)}|${target.deviceId}|$ownId',
    );
    if (result['requestId'] != nonce)
      throw const _LocalSyncException('Invalid sync response.');
    return result;
  }

  final Map<String, Future<void>> _outbound = {};
  Future<Map<String, int>> _performSync(
    DiscoveredSyncDevice target, {
    void Function(LocalSyncStage)? onStage,
  }) {
    final previous = _outbound[target.deviceId] ?? Future.value();
    final done = Completer<void>();
    _outbound[target.deviceId] = done.future;
    return previous
        .then((_) => _performSyncUnlocked(target, onStage: onStage))
        .whenComplete(() {
          done.complete();
          if (identical(_outbound[target.deviceId], done.future))
            _outbound.remove(target.deviceId);
        });
  }

  Future<Map<String, int>> _performSyncUnlocked(
    DiscoveredSyncDevice target, {
    void Function(LocalSyncStage stage)? onStage,
  }) async {
    final capabilities = await _securePost(
      target,
      '/api/sync/capabilities',
      {},
    );
    if (capabilities['schemaVersion'] != LibraryMergeService.schemaVersion)
      throw const _LocalSyncException('Update both devices to use Local Sync.');
    final categories = selectedCategories.intersection(
      parseSyncCategories(capabilities['categories']),
    );
    if (categories.isEmpty)
      throw const _LocalSyncException(
        'Select at least one matching category on both devices.',
      );
    onStage?.call(LocalSyncStage.exporting);
    final library = await LibraryMergeService.exportLibrary(
      categories: categories,
    );
    onStage?.call(LocalSyncStage.exchanging);
    final response = await _securePost(target, '/api/sync/merge', {
      'categories': categories.map((e) => e.name).toList(),
      'library': library,
    });
    if (response['library'] is! Map || response['receipt'] is! String)
      throw const _LocalSyncException('The other device sent no library.');
    onStage?.call(LocalSyncStage.merging);
    final remote = Map<String, dynamic>.from(response['library']);
    if (_httpServer == null)
      throw const _LocalSyncException('Local sync was turned off.');
    final localStats = await LibraryMergeService.mergeLibrary(
      remote,
      categories: categories,
    );
    if (localStats.isNotEmpty) _scheduleLocalSync();
    onStage?.call(LocalSyncStage.finalizing);
    final confirmation = await _securePost(target, '/api/sync/confirm', {
      'receipt': response['receipt'],
      'digest': syncDigest(remote),
    });
    if (confirmation['confirmed'] != true)
      throw const _LocalSyncException('Sync confirmation failed. Try again.');
    final stats = <String, int>{...localStats};
    if (response['stats'] is Map) {
      for (final e in (response['stats'] as Map).entries) {
        if (e.value is int)
          stats[e.key.toString()] =
              (stats[e.key.toString()] ?? 0) + e.value as int;
      }
    }
    _retryAfter.remove(target.deviceId);
    _retryCount.remove(target.deviceId);
    return stats;
  }

  Future<void> _recordSync(String deviceName, Map<String, int> stats) async {
    final now = DateTime.now().toUtc();
    await Hive.box('settings').put(_lastSyncedAtKey, now.toIso8601String());
    reloadSettingsFromStorage();
    final added = LibraryMergeService.totalAdded(stats);
    localSyncStatus.value = added == 0
        ? 'Synced with $deviceName; no selected data changed'
        : 'Synced with $deviceName; selected data updated';
  }

  Future<Map<String, dynamic>> _post(
    DiscoveredSyncDevice target,
    String path,
    Map<String, dynamic> body, {
    required Duration timeout,
  }) async {
    final uri = Uri(
      scheme: 'http',
      host: target.ip,
      port: target.port,
      path: path,
    );
    final encoded = json.encode(body);
    if (utf8.encode(encoded).length > maxSyncMessageBytes)
      throw const _LocalSyncException(
        'Selected sync data is too large. Choose fewer categories.',
      );
    final outgoing = http.Request('POST', uri)
      ..headers.addAll(const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      })
      ..body = encoded;
    final response = await _client.send(outgoing).timeout(timeout);
    final responseBytes = await _readMessage(response.stream).timeout(timeout);
    dynamic decoded;
    try {
      decoded = json.decode(utf8.decode(responseBytes));
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded is Map ? decoded['error']?.toString() : null;
      throw _LocalSyncHttpException(
        response.statusCode,
        error ?? 'HTTP ${response.statusCode}',
      );
    }
    if (decoded is! Map) {
      throw const _LocalSyncException('Unexpected response from device');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<String> _friendlyError(
    Object error,
    DiscoveredSyncDevice device, {
    required bool pairing,
  }) async {
    if (error is _LocalSyncException && error.message == 'incorrect_pin') {
      return 'Incorrect PIN. Check the code shown on ${device.name}.';
    }
    if (error is _LocalSyncHttpException) {
      if (error.statusCode == 426)
        return 'Update both devices to use Local Sync.';
      if (error.message == 'incorrect_pin') {
        return 'Incorrect PIN. Check the code shown on ${device.name}.';
      }
      if (error.statusCode == 403) {
        return pairing
            ? '${device.name} rejected the pairing.'
            : '${device.name} no longer trusts this device. Sync again to pair.';
      }
      return '${device.name} answered with an error (${error.statusCode}).';
    }
    if (error is _LocalSyncException) {
      return error.message;
    }
    if (error is TimeoutException) {
      return 'Could not reach ${device.name}. Your data is safe; sync will resume when both devices are on the same network.';
    }
    if (error is SocketException) {
      return 'Could not reach ${device.name}. Make sure both devices are on the same network.';
    }
    return 'Sync failed: $error';
  }

  void _onLocalChange(BoxEvent event) {
    if (!selectedCategories
            .expand((c) => syncCategoryKeys[c]!)
            .contains(event.key.toString()) ||
        !localSyncEnabled.value ||
        !localSyncAutomatic.value ||
        pairedDevices.value.isEmpty) {
      return;
    }
    _scheduleLocalSync();
  }

  void _scheduleLocalSync() {
    if (!localSyncEnabled.value || !localSyncAutomatic.value) return;
    _localChangeTimer?.cancel();
    _localChangeTimer = Timer(
      _localChangeDebounce,
      () => unawaited(triggerSilentSync()),
    );
  }

  /// The limited broadcast plus each interface's /24 broadcast, so a desktop
  /// with several interfaces still reaches the Wi-Fi the phone is on.
  Future<List<InternetAddress>> _broadcastAddresses() async {
    final addresses = <String>{'255.255.255.255'};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.isLoopback) continue;
          final parts = address.address.split('.');
          if (parts.length == 4) {
            addresses.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
          }
        }
      }
    } catch (e) {
      logger.log('Could not list network interfaces: $e');
    }
    return addresses.map(InternetAddress.new).toList();
  }

  Future<void> _acquireMulticastLock() async {
    try {
      await _multicastLock.acquireMulticastLock();
    } catch (e) {
      logger.log('Could not acquire multicast lock: $e');
    }
  }

  Future<void> _releaseMulticastLock() async {
    try {
      await _multicastLock.releaseMulticastLock();
    } catch (_) {}
  }

  Future<Uint8List> _readMessage(Stream<List<int>> stream) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > maxSyncMessageBytes)
        throw const FormatException('Sync message too large');
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Future<Map<String, dynamic>> _readJson(shelf.Request request) async {
    final bytes = await _readMessage(request.read());
    final decoded = json.decode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Request body is not a JSON object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  shelf.Response _json(Map<String, dynamic> body, {int status = 200}) {
    return shelf.Response(
      status,
      body: json.encode(body),
      headers: const {'Content-Type': 'application/json'},
    );
  }
}

class _LocalSyncException implements Exception {
  const _LocalSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _LocalSyncHttpException implements Exception {
  const _LocalSyncHttpException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'HTTP $statusCode: $message';
}
