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

import 'package:cryptography/cryptography.dart'
    show SecretBoxAuthenticationError;
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
import 'package:musify/utilities/platform_utils.dart';

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
}

/// A device paired by PIN; it is found again by discovery before each sync.
class PairedSyncDevice {
  const PairedSyncDevice({
    required this.deviceId,
    required this.name,
    required this.secret,
  });

  factory PairedSyncDevice.fromMap(Map map) => PairedSyncDevice(
    deviceId: map['deviceId']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Musify',
    secret: map['secret']?.toString() ?? '',
  );

  final String deviceId;
  final String name;
  final String secret;

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'name': name,
    'secret': secret,
  };
}

/// A pairing attempt from another device; the PIN is shown here.
class IncomingPairingRequest {
  IncomingPairingRequest({
    required this.clientName,
    required this.pin,
    required this.completed,
  });

  final String clientName;
  final String pin;

  /// Completes with true once the PIN is verified, false if rejected or timed out.
  final Future<bool> completed;
}

enum LocalSyncStatus { idle, scanning, syncing, waitingForPin, success, error }

/// Where a sync run is, in order. The UI maps these to progress.
enum LocalSyncStage { exporting, exchanging, merging }

/// Why a sync failed; the UI turns these into localized messages.
enum LocalSyncError {
  notRunning,
  incorrectPin,
  rejected,
  busy,
  untrusted,
  updateRequired,
  noCommonCategories,
  tooLarge,
  unreachable,
  failed,
}

class LocalSyncState {
  const LocalSyncState({
    this.status = LocalSyncStatus.idle,
    this.discoveredDevices = const [],
    this.activeDevice,
    this.stage,
    this.changed,
    this.error,
  });

  final LocalSyncStatus status;
  final List<DiscoveredSyncDevice> discoveredDevices;

  /// The device the current sync or pairing is talking to.
  final DiscoveredSyncDevice? activeDevice;
  final LocalSyncStage? stage;

  /// Library keys either side changed in the last sync.
  final Set<String>? changed;
  final LocalSyncError? error;

  LocalSyncState copyWith({
    LocalSyncStatus? status,
    List<DiscoveredSyncDevice>? discoveredDevices,
    DiscoveredSyncDevice? activeDevice,
    LocalSyncStage? stage,
    Set<String>? changed,
    LocalSyncError? error,
    bool clearActiveDevice = false,
    bool clearStage = false,
    bool clearChanged = false,
    bool clearError = false,
  }) {
    return LocalSyncState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      activeDevice: clearActiveDevice
          ? null
          : (activeDevice ?? this.activeDevice),
      stage: clearStage ? null : (stage ?? this.stage),
      changed: clearChanged ? null : (changed ?? this.changed),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

typedef _Reply = (int, Map<String, dynamic>);

/// Serverless library sync: each device runs a small HTTP server and answers UDP discovery.
class LocalSyncService {
  LocalSyncService._()
    : _testDiscovery = null,
      _pairingNow = DateTime.now,
      _replyTimeout = _shortTimeout,
      _bodyTimeout = _mergeTimeout;

  /// A throwaway instance for tests that talk to each other over loopback.
  @visibleForTesting
  LocalSyncService.forTesting({
    Future<List<DiscoveredSyncDevice>> Function()? discovery,
    DateTime Function()? pairingNow,
    Duration? replyTimeout,
    Duration? bodyTimeout,
  }) : _testDiscovery = discovery,
       _pairingNow = pairingNow ?? DateTime.now,
       _replyTimeout = replyTimeout ?? _shortTimeout,
       _bodyTimeout = bodyTimeout ?? _mergeTimeout;

  static final LocalSyncService instance = LocalSyncService._();

  static const int discoveryPort = 53531;
  static const int apiVersion = 3;
  static const Duration autoSyncInterval = Duration(minutes: 30);
  static const Duration _startupSyncDelay = Duration(seconds: 6);
  static const Duration _localChangeDebounce = Duration(seconds: 30);
  static const Duration _pairingTimeout = Duration(seconds: 60);
  static const Duration _shortTimeout = Duration(seconds: 12);
  static const Duration _mergeTimeout = Duration(seconds: 45);
  static const int _smallMessageBytes = 64 * 1024;
  static const String _deviceHeader = 'x-musify-device';

  static const String _discoveryRequest = 'MUSIFY_DISCOVERY_REQUEST';
  static const String _discoveryResponse = 'MUSIFY_DISCOVERY_RESPONSE';

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
  final DateTime Function() _pairingNow;

  /// How long a reply that must be known to arrive may take to be written.
  final Duration _replyTimeout;

  /// How long a request may take to send its body.
  final Duration _bodyTimeout;

  /// A large body is read by one request at a time: the others would pile
  /// up to 64 MB each, and none of them has proven who sent it yet.
  bool _largeBodyActive = false;

  /// Runs once a pairing is trusted and before the reply is sent (tests).
  @visibleForTesting
  Future<void> Function()? beforePairingReply;
  final http.Client _client = http.Client();
  Future<void> _pairedWrites = Future.value();
  Future<void> _serverOperations = Future.value();
  int _activeTransfers = 0;
  Completer<void>? _transfersIdle;
  final FlutterMulticastLock _multicastLock = FlutterMulticastLock();

  HttpServer? _httpServer;
  RawDatagramSocket? _udpSocket;
  StreamSubscription<BoxEvent>? _userBoxSubscription;
  String? _observedRecapReset;
  Timer? _periodicTimer;
  Timer? _startupTimer;
  Timer? _localChangeTimer;
  bool _initialised = false;
  bool _silentSyncRunning = false;
  bool _syncAgain = false;
  DateTime? _lastResumeSync;

  Completer<String?>? _pinInputCompleter;

  // Pending pairing on the receiving side.
  String? _pendingClientId;
  String? _pendingClientName;
  PinPairingReceiver? _pendingPairing;
  String? _pendingSession;
  DateTime? _lastPairingRequest;
  Completer<bool>? _pendingCompleter;
  Timer? _pendingTimer;

  // Pairing started from this device, reused if the user retries the PIN.
  String? _outgoingSession;
  Map<String, dynamic>? _outgoingChallenge;
  String? _outgoingTarget;
  DateTime? _outgoingExpires;

  // What a handler wants done once its reply went out, or failed to.
  final Expando<Future<void> Function(bool delivered)> _afterReply = Expando();

  // Requests whose body was read to its end.
  final Expando<bool> _bodyRead = Expando();

  final Map<String, DateTime> _retryAfter = {};
  final Map<String, int> _retryCount = {};
  final Map<String, Future<void>> _outbound = {};

  bool get isSupportedPlatform => isAndroidPlatform || isDesktopPlatform;

  int? get serverPort => _httpServer?.port;

  String get deviceName => isAndroidPlatform
      ? 'Musify (Android)'
      : 'Musify (${Platform.localHostname})';

  Future<void> initialise() async {
    if (_initialised || !isSupportedPlatform) return;
    _initialised = true;

    try {
      await LibraryMergeService.recoverPendingMerge();
    } catch (e, stackTrace) {
      // Not worth leaving sync off for good: the server, the paired devices and
      // the timers do not depend on it.
      logger.log(
        'Local sync could not recover an interrupted merge',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _loadPairedDevices();

    if (localSyncEnabled.value) {
      try {
        await startServer();
      } catch (_) {
        // Logged by startServer; the settings page shows it as not visible.
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

  /// Re-subscribes to the `user` box, which a backup restore silently unsubscribes.
  Future<void> rebindStorageListeners() async {
    await _userBoxSubscription?.cancel();
    final box = Hive.box('user');
    final recap = box.get('wrappedListeningStats');
    _observedRecapReset = recap is Map && recap['syncResetId'] is String
        ? recap['syncResetId'] as String
        : null;
    _userBoxSubscription = box.watch().listen(_onLocalChange);
  }

  Future<void> pauseForStorageRestore() async {
    _localChangeTimer?.cancel();
    await stopServer();
    await Future.wait(_outbound.values.toList());
    await LibraryMergeService.awaitIdle();
  }

  /// [storageChanged] is false when the restore was cancelled or rolled back:
  /// the library is as it was, so the baseline still describes it.
  Future<void> resumeAfterStorageRestore({bool storageChanged = true}) async {
    reloadSettingsFromStorage();
    if (storageChanged) await LibraryMergeService.forgetBaseline();
    await rebindStorageListeners();
    if (localSyncEnabled.value) await startServer();
  }

  Future<void> dispose() async {
    _periodicTimer?.cancel();
    _startupTimer?.cancel();
    _localChangeTimer?.cancel();
    await _userBoxSubscription?.cancel();
    await stopServer();
    _client.close();
  }

  /// Turns local sync on or off; false if the server could not start.
  Future<bool> setEnabled(bool enabled) async {
    if (!isSupportedPlatform) return false;
    await Hive.box('settings').put(_enabledKey, enabled);
    localSyncEnabled.value = enabled;

    if (!enabled) {
      _localChangeTimer?.cancel();
      await stopServer();
      return true;
    }
    try {
      await startServer();
    } catch (_) {
      await Hive.box('settings').put(_enabledKey, false);
      localSyncEnabled.value = false;
      return false;
    }
    unawaited(triggerSilentSync());
    return true;
  }

  Future<void> setAutomatic(bool enabled) async {
    await Hive.box('settings').put(_automaticKey, enabled);
    localSyncAutomatic.value = enabled;
    if (enabled) {
      unawaited(triggerSilentSync());
    } else {
      _localChangeTimer?.cancel();
    }
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
    // A change takes effect only after exchanges already in progress finish.
    while (_activeTransfers > 0) {
      _transfersIdle ??= Completer<void>();
      await _transfersIdle!.future;
    }
    await Hive.box('settings')
        .put('localSyncCategories', categories.map((e) => e.name).toList());
    if (categories.isNotEmpty) _scheduleLocalSync();
  }

  void _beginTransfer() => _activeTransfers++;

  void _endTransfer() {
    if (--_activeTransfers == 0) {
      final idle = _transfersIdle;
      _transfersIdle = null;
      idle?.complete();
    }
  }

  PairedSyncDevice? _paired(String deviceId) => pairedDevices.value
      .where((e) => e.deviceId == deviceId && e.secret.isNotEmpty)
      .firstOrNull;

  bool isDevicePaired(String deviceId) => _paired(deviceId) != null;

  Future<void> _serializePaired(Future<void> Function() action) {
    final result = _pairedWrites.then((_) => action());
    _pairedWrites = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<void> _savePairedDeviceUnlocked(PairedSyncDevice device) async {
    final updated = List<PairedSyncDevice>.from(pairedDevices.value)
      ..removeWhere((item) => item.deviceId == device.deviceId)
      ..add(device);
    await _storePairedDevices(updated);
  }

  Future<void> savePairedDevice(PairedSyncDevice device) =>
      _serializePaired(() => _savePairedDeviceUnlocked(device));

  Future<void> forgetDevice(String deviceId) => _serializePaired(() async {
    final updated = List<PairedSyncDevice>.from(pairedDevices.value)
      ..removeWhere((item) => item.deviceId == deviceId);
    await _storePairedDevices(updated);
    await _dropCounters((key) => key.contains(':$deviceId:'));
  });

  Future<void> forgetAllDevices() => _serializePaired(() async {
    await _storePairedDevices(const []);
    await _dropCounters((_) => true);
  });

  Iterable<String> _counterKeys(bool Function(String key) matches) =>
      Hive.box('userNoBackup').keys.whereType<String>().where(
        (key) =>
            (key.startsWith('localSyncSent:') ||
                key.startsWith('localSyncReceived:')) &&
            matches(key),
      );

  Future<void> _dropCounters(bool Function(String key) matches) =>
      Hive.box('userNoBackup').deleteAll(_counterKeys(matches).toList());

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

  Future<void> _serializeServer(Future<void> Function() action) {
    final result = _serverOperations.then((_) => action());
    _serverOperations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<void> startServer() => _serializeServer(_startServer);

  Future<void> _startServer() async {
    if (_httpServer != null) return;

    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _httpServer = server;
      server.listen((request) => unawaited(_handle(request)));

      if (isAndroidPlatform) await _acquireMulticastLock();

      // Another instance may own the discovery port; incoming syncs still work.
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
      logger.log('Local sync server listening on port ${server.port}');
    } catch (e, stackTrace) {
      logger.log(
        'Local sync server failed to start',
        error: e,
        stackTrace: stackTrace,
      );
      await _stopServer();
      rethrow;
    }
  }

  Future<void> stopServer() => _serializeServer(_stopServer);

  Future<void> _stopServer() async {
    _cancelPendingPairing();
    cancelPinInput();
    _udpSocket?.close();
    _udpSocket = null;

    if (isAndroidPlatform) await _releaseMulticastLock();

    final server = _httpServer;
    _httpServer = null;
    await server?.close(force: true);
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

    final response =
        '$_discoveryResponse;${deviceName.replaceAll(';', ' ')};'
        '${server.port};${LibraryMergeService.deviceId}';
    _udpSocket?.send(utf8.encode(response), datagram.address, datagram.port);
  }

  Future<void> _handle(HttpRequest request) async {
    final handler = request.method != 'POST'
        ? null
        : switch (request.uri.path) {
            '/api/sync/pair-request' => _handlePairRequest,
            '/api/sync/pair-verify' => _handlePairVerify,
            '/api/sync/capabilities' => _handleCapabilities,
            '/api/sync/merge' => _handleMerge,
            _ => null,
          };
    // The clients always say so. A web page cannot send JSON to another
    // origin without a preflight request, which this server never answers.
    final (status, body) = handler == null
        ? (404, <String, dynamic>{'error': 'not_found'})
        : !_isJson(request)
        ? (415, <String, dynamic>{'error': 'unsupported_media_type'})
        : await handler(request);
    // A reply to a request whose body is large or of unknown size and was
    // not read would wait for all of it to arrive, and the sender decides
    // when that is: answer now and hang up instead.
    final length = request.contentLength;
    if (_bodyRead[request] != true &&
        (length < 0 || length > _smallMessageBytes)) {
      await _replyAndHangUp(request, status, body);
      return;
    }
    final afterReply = _afterReply[request];
    var delivered = true;
    try {
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(json.encode(body));
      final closing = request.response.close();
      // A connection the other side reset never finishes writing: that only
      // matters when something depends on the reply having gone out.
      await (afterReply == null ? closing : closing.timeout(_replyTimeout));
    } catch (_) {
      // The other device gave up waiting.
      delivered = false;
    }
    if (afterReply != null) {
      try {
        await afterReply(delivered);
      } catch (e, stackTrace) {
        logger.log(
          'Local sync could not finish a request',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _replyAndHangUp(
    HttpRequest request,
    int status,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = request.response..statusCode = status;
      final payload = utf8.encode(json.encode(body));
      final socket = await response.detachSocket(writeHeaders: false);
      socket
        ..add(
          utf8.encode(
            'HTTP/1.1 $status ${response.reasonPhrase}\r\n'
            'Content-Type: application/json; charset=utf-8\r\n'
            'Content-Length: ${payload.length}\r\n'
            'Connection: close\r\n\r\n',
          ),
        )
        ..add(payload);
      try {
        await socket.flush().timeout(_shortTimeout);
      } catch (_) {
        // The other device gave up waiting.
      }
      socket.destroy();
    } catch (_) {
      // The other device gave up waiting.
    }
  }

  bool _isJson(HttpRequest request) {
    try {
      return request.headers.contentType?.mimeType == 'application/json';
    } catch (_) {
      return false;
    }
  }

  Future<_Reply> _handlePairRequest(HttpRequest request) async {
    final Map<String, dynamic> data;
    try {
      data = await _readJson(request, maxBytes: _smallMessageBytes);
    } catch (_) {
      return (400, {'error': 'invalid_pairing'});
    }
    try {
      if (data['apiVersion'] != apiVersion) {
        return (426, {'error': 'upgrade_required'});
      }
      final id = data['clientId'];
      if (id is! String || id.isEmpty || id.length > 128) {
        return (400, {'error': 'invalid_pairing'});
      }
      final now = _pairingNow();
      final blockedUntil = Hive.box('userNoBackup')
          .get('localSyncPairBlockedUntil');
      if (blockedUntil is int && now.millisecondsSinceEpoch < blockedUntil) {
        return (429, {'error': 'pairing_busy'});
      }
      if (_pendingSession != null ||
          (_lastPairingRequest != null &&
              now.difference(_lastPairingRequest!) <
                  const Duration(seconds: 3))) {
        return (429, {'error': 'pairing_busy'});
      }
      _lastPairingRequest = now;
      _pendingClientId = id;
      final name = data['clientName']?.toString() ?? 'Musify';
      _pendingClientName = name.substring(0, min(100, name.length));
      final session = SyncSecurity.randomToken(16);
      _pendingSession = session;
      _pendingCompleter = Completer<bool>();
      _pendingTimer = Timer(_pairingTimeout, _cancelPendingPairing);
      final ownId = LibraryMergeService.deviceId;
      final pairing = await PinPairingReceiver.create('$id|$ownId|$session');
      if (_pendingSession != session) {
        return (403, {'error': 'pairing_expired'});
      }
      _pendingPairing = pairing;
      incomingPairingRequest.value = IncomingPairingRequest(
        clientName: _pendingClientName!,
        pin: pairing.pin,
        completed: _pendingCompleter!.future,
      );
      return (
        200,
        {'session': session, 'challenge': pairing.challenge, 'deviceId': ownId},
      );
    } catch (_) {
      _cancelPendingPairing();
      return (400, {'error': 'invalid_pairing'});
    }
  }

  Future<_Reply> _handlePairVerify(HttpRequest request) async {
    final Map<String, dynamic> data;
    try {
      data = await _readJson(request, maxBytes: _smallMessageBytes);
    } catch (_) {
      return (400, {'error': 'invalid_pairing'});
    }
    final session = _pendingSession;
    final pairing = _pendingPairing;
    // Only the requester knows the session, so other hosts cannot cancel the attempt.
    if (session == null ||
        pairing == null ||
        data['session'] != session ||
        data['proof'] is! Map) {
      return (403, {'error': 'pairing_expired'});
    }
    final ({String secret, String proof}) agreement;
    try {
      agreement = await pairing.verify(data['proof']);
    } catch (_) {
      // Only a proof that fails is a wrong PIN.
      return _countWrongPin();
    }
    if (_pendingSession != session) {
      return (403, {'error': 'pairing_cancelled'});
    }
    final id = _pendingClientId!;
    final name = _pendingClientName!;
    final completer = _pendingCompleter;
    PairedSyncDevice? previous;
    var counters = <String, Object?>{};
    try {
      previous = _paired(id);
      final store = Hive.box('userNoBackup');
      counters = {
        for (final key in _counterKeys((key) => key.contains(':$id:')))
          key: store.get(key),
      };
      final confirmation = await SyncSecurity.seal(agreement.secret, {
        'status': 'paired',
        'deviceId': LibraryMergeService.deviceId,
        'deviceName': deviceName,
      }, 'pair:$session:reply');
      await _trust(id, name, agreement.secret);
      await store.deleteAll(_pairFailureKeys);
      _clearPendingPairing();
      await beforePairingReply?.call();
      // This device trusts the other one now: if the reply never reaches it,
      // the other one does not trust this one, so that is undone.
      _afterReply[request] = (delivered) async {
        if (delivered) {
          if (completer != null && !completer.isCompleted) {
            completer.complete(true);
          }
        } else {
          await _undoTrust(id, previous, counters);
          if (completer != null && !completer.isCompleted) {
            completer.complete(false);
          }
        }
      };
      return (200, {'proof': agreement.proof, 'confirmation': confirmation});
    } catch (e, stackTrace) {
      // The PIN was right; this device failed. Not a wrong PIN, and not paired.
      logger.log(
        'Local sync pairing could not be completed',
        error: e,
        stackTrace: stackTrace,
      );
      _cancelPendingPairing();
      await _undoTrust(id, previous, counters);
      return (500, {'error': 'pairing_failed'});
    }
  }

  static const List<String> _pairFailureKeys = [
    'localSyncPairFailures',
    'localSyncPairLastFailure',
    'localSyncPairBlockedUntil',
  ];

  // Wrong PINs: four free tries, then waits of 5, 10 and 15 minutes (never
  // more), and a day without a mistake clears the count. The wait is for the
  // whole device, not for whoever got the PIN wrong, because the PIN is the
  // only thing that tells them apart: while it lasts nobody can start a new
  // pairing, and devices that are already paired are not affected.
  static const Duration _pairBlockCap = Duration(minutes: 15);
  static const Duration _pairFailureMemory = Duration(hours: 24);

  /// A wrong PIN closes the attempt and, from the fifth in a row, blocks new ones.
  Future<_Reply> _countWrongPin() async {
    _cancelPendingPairing();
    try {
      final store = Hive.box('userNoBackup');
      final now = _pairingNow();
      final previous = store.get('localSyncPairFailures', defaultValue: 0);
      final last = store.get('localSyncPairLastFailure');
      final forgotten =
          last is int &&
          now.millisecondsSinceEpoch - last > _pairFailureMemory.inMilliseconds;
      final failures = (forgotten || previous is! int ? 0 : previous) + 1;
      final delayMinutes = failures < 5
          ? 0
          : min(_pairBlockCap.inMinutes, 5 * (1 << min(failures - 5, 4)));
      await store.putAll({
        'localSyncPairFailures': failures,
        'localSyncPairLastFailure': now.millisecondsSinceEpoch,
        if (delayMinutes > 0)
          'localSyncPairBlockedUntil': now
              .add(Duration(minutes: delayMinutes))
              .millisecondsSinceEpoch,
      });
    } catch (e, stackTrace) {
      logger.log(
        'Local sync could not record a wrong PIN',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return (403, {'error': 'incorrect_pin'});
  }

  /// Puts the trust of [id] back as it was before a pairing that did not finish.
  Future<void> _undoTrust(
    String id,
    PairedSyncDevice? previous,
    Map<String, Object?> counters,
  ) async {
    try {
      await _serializePaired(() async {
        final updated = List<PairedSyncDevice>.from(pairedDevices.value)
          ..removeWhere((item) => item.deviceId == id);
        if (previous != null) updated.add(previous);
        await _storePairedDevices(updated);
        final store = Hive.box('userNoBackup');
        await _dropCounters((key) => key.contains(':$id:'));
        if (counters.isNotEmpty) await store.putAll(counters);
      });
    } catch (e, stackTrace) {
      logger.log(
        'Local sync could not undo an unfinished pairing',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Stores a new pairing secret; old replay counters belong to the old secret.
  Future<void> _trust(String deviceId, String name, String secret) =>
      _serializePaired(() async {
        await _savePairedDeviceUnlocked(
          PairedSyncDevice(deviceId: deviceId, name: name, secret: secret),
        );
        await _dropCounters(
          (key) =>
              key.contains(':$deviceId:') && !key.endsWith(syncDigest(secret)),
        );
      });

  Future<({Map<String, dynamic> body, PairedSyncDevice peer})> _authenticated(
    HttpRequest request, {
    int maxBytes = maxSyncMessageBytes,
  }) async {
    // Cheap rejections before buffering a body; the sender is only proven by decryption.
    final id = request.headers.value(_deviceHeader);
    if (id == null) throw const _HttpFailure(426, 'upgrade_required');
    final peer = _paired(id);
    if (peer == null) throw const _HttpFailure(403, 'not_paired');
    if (request.contentLength > maxBytes) {
      throw const _HttpFailure(413, 'too_large');
    }
    final large = maxBytes > _smallMessageBytes;
    if (large) {
      // The device id is public (discovery answers with it), so a large body
      // is not trusted yet: its size must be known, and only one is read.
      if (request.contentLength < 0) {
        throw const _HttpFailure(411, 'length_required');
      }
      if (_largeBodyActive) throw const _HttpFailure(429, 'busy');
      _largeBodyActive = true;
    }
    final Map<String, dynamic> body;
    try {
      final bytes = await _readBody(request, maxBytes: maxBytes);
      body = await SyncSecurity.openRequestInBackground(
        peer.secret,
        bytes,
        '${request.uri.path.substring(1)}|$id|${LibraryMergeService.deviceId}',
        apiVersion: apiVersion,
      );
    } on SyncEnvelopeException catch (e) {
      throw e.upgradeRequired
          ? const _HttpFailure(426, 'upgrade_required')
          : const _HttpFailure(400, 'invalid');
    } on SecretBoxAuthenticationError {
      throw const _HttpFailure(403, 'not_paired');
    } on SyncTooLargeException {
      throw const _HttpFailure(413, 'too_large');
    } on _HttpFailure {
      rethrow;
    } catch (_) {
      throw const _HttpFailure(400, 'invalid');
    } finally {
      if (large) _largeBodyActive = false;
    }
    final nonce = body['requestId'];
    if (nonce is! String || nonce.length < 20 || nonce.length > 128) {
      throw const _HttpFailure(400, 'invalid_request');
    }
    final store = Hive.box('userNoBackup');
    final counterKey = 'localSyncReceived:$id:${syncDigest(peer.secret)}';
    final sequence = body['sequence'];
    if (sequence is! int ||
        sequence <= (store.get(counterKey, defaultValue: 0) as int)) {
      throw const _HttpFailure(403, 'replayed_request');
    }
    await store.put(counterKey, sequence);
    await store.flush();
    return (body: body, peer: peer);
  }

  Future<_Reply> _encryptedReply(
    HttpRequest request,
    PairedSyncDevice peer,
    Map<String, dynamic> received,
    Map<String, dynamic> body,
  ) async {
    final context =
        '${request.uri.path.substring(1)}|${LibraryMergeService.deviceId}|${peer.deviceId}';
    return (
      200,
      {
        'encrypted': await SyncSecurity.sealInBackground(peer.secret, {
          ...body,
          'requestId': received['requestId'],
        }, context),
      },
    );
  }

  Future<_Reply> _handleCapabilities(HttpRequest request) async {
    try {
      final auth = await _authenticated(request, maxBytes: _smallMessageBytes);
      return await _encryptedReply(request, auth.peer, auth.body, {
        'schemaVersion': syncSchemaVersion,
        'categories': selectedCategories.map((e) => e.name).toList(),
      });
    } on _HttpFailure catch (e) {
      return (e.status, {'error': e.code});
    } catch (_) {
      return (400, {'error': 'invalid_request'});
    }
  }

  Future<_Reply> _handleMerge(HttpRequest request) async {
    var transferStarted = false;
    try {
      final auth = await _authenticated(request);
      _beginTransfer();
      transferStarted = true;
      final categories = parseSyncCategories(auth.body['categories']);
      if (categories.isEmpty || !selectedCategories.containsAll(categories)) {
        return (409, {'error': 'categories_changed'});
      }
      final library = auth.body['library'];
      if (library is! Map) return (400, {'error': 'library_missing'});
      if (library['schemaVersion'] != syncSchemaVersion) {
        return (426, {'error': 'upgrade_required'});
      }
      if (_httpServer == null) return (503, {'error': 'sync_off'});
      final result = await LibraryMergeService.mergeLibrary(
        Map<String, dynamic>.from(library),
        categories: categories,
      );
      await _recordSync(auth.peer.deviceId, auth.peer.name);
      // Pass the change on to other paired devices, as in a chain A-B-C.
      if (result.changed.isNotEmpty &&
          pairedDevices.value.any((d) => d.deviceId != auth.peer.deviceId)) {
        _scheduleLocalSync();
      }
      return await _encryptedReply(request, auth.peer, auth.body, {
        'library': result.library,
        'changed': result.changed.toList(),
      });
    } on _HttpFailure catch (e) {
      return (e.status, {'error': e.code});
    } catch (e, stack) {
      logger.log('Local sync request rejected', error: e, stackTrace: stack);
      return (400, {'error': 'invalid_sync'});
    } finally {
      if (transferStarted) _endTransfer();
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
    _pendingPairing = null;
    _pendingSession = null;
    _pendingCompleter = null;
    incomingPairingRequest.value = null;
  }

  /// Broadcasts a discovery request and collects the answers for [duration],
  /// telling [onFound] about the list as it grows. The scan changes nothing
  /// else: a silent sync's quick scan must not rewrite what the page shows.
  Future<List<DiscoveredSyncDevice>> discoverDevices({
    Duration duration = const Duration(seconds: 4),
    void Function(List<DiscoveredSyncDevice> devices)? onFound,
  }) async {
    if (_testDiscovery != null) return _testDiscovery();
    final discovered = <DiscoveredSyncDevice>[];

    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? subscription;
    final ownDeviceId = LibraryMergeService.deviceId;

    try {
      if (isAndroidPlatform) await _acquireMulticastLock();

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
        onFound?.call(List.unmodifiable(discovered));
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
      if (isAndroidPlatform && _httpServer == null) {
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
      discoveredDevices: const [],
      clearError: true,
      clearChanged: true,
      clearStage: true,
      clearActiveDevice: true,
    );
    await discoverDevices(
      onFound: (devices) =>
          state.value = state.value.copyWith(discoveredDevices: devices),
    );
    if (state.value.status == LocalSyncStatus.scanning) {
      state.value = state.value.copyWith(status: LocalSyncStatus.idle);
    }
  }

  /// Pairs with [device] if needed (PIN via [submitPin]), then syncs both ways.
  Future<void> syncWith(DiscoveredSyncDevice device) async {
    if (state.value.status == LocalSyncStatus.syncing ||
        state.value.status == LocalSyncStatus.waitingForPin) {
      return;
    }

    state.value = state.value.copyWith(
      status: LocalSyncStatus.syncing,
      activeDevice: device,
      clearError: true,
      clearChanged: true,
      clearStage: true,
    );

    var pairing = false;
    try {
      if (_httpServer == null) {
        throw const _LocalSyncException(LocalSyncError.notRunning);
      }

      if (!isDevicePaired(device.deviceId)) {
        pairing = true;
        await _requestPairing(device);
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
        await _verifyPairing(device, pin.trim());
        pairing = false;
      }

      final result = await _performSync(
        device,
        onStage: (stage) => state.value = state.value.copyWith(stage: stage),
      );
      await _recordSync(device.deviceId, device.name);
      // Other paired devices have not seen what this one brought.
      if (result.local.isNotEmpty && pairedDevices.value.length > 1) {
        _scheduleLocalSync();
      }

      state.value = state.value.copyWith(
        status: LocalSyncStatus.success,
        changed: {...result.local, ...result.remote},
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
        error: _errorFor(e, pairing: pairing),
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
      clearChanged: true,
      clearStage: true,
      clearActiveDevice: true,
    );
  }

  /// Syncs with every paired device that is online, one after another.
  Future<void> syncAllNow() async {
    final targets = state.value.discoveredDevices
        .where((device) => isDevicePaired(device.deviceId))
        .toList();
    final changed = <String>{};
    for (final device in targets) {
      await syncWith(device);
      if (state.value.status != LocalSyncStatus.success) return;
      changed.addAll(state.value.changed ?? const {});
    }
    // Forward data learned from later devices to the earlier ones, even when
    // automatic sync is disabled. Keep the same error handling as the first pass.
    for (final device in targets.take(
      targets.length > 1 ? targets.length - 1 : 0,
    )) {
      await syncWith(device);
      if (state.value.status != LocalSyncStatus.success) return;
      changed.addAll(state.value.changed ?? const {});
    }
    if (targets.length > 1) {
      state.value = state.value.copyWith(
        changed: changed,
        clearActiveDevice: true,
      );
    }
  }

  /// Resuming fires on every desktop window focus, so it syncs at most every 2 minutes.
  Future<void> syncOnResume() async {
    final last = _lastResumeSync;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 2)) {
      return;
    }
    _lastResumeSync = DateTime.now();
    await triggerSilentSync();
  }

  /// Syncs with every paired device found by a short discovery, without UI.
  Future<void> triggerSilentSync() async {
    if (_silentSyncRunning) {
      // Edits made during a pass may have missed peers it already synced.
      _syncAgain = true;
      return;
    }
    if (!localSyncEnabled.value ||
        !localSyncAutomatic.value ||
        offlineMode.value ||
        _httpServer == null ||
        pairedDevices.value.isEmpty) {
      return;
    }
    if (state.value.status != LocalSyncStatus.idle &&
        state.value.status != LocalSyncStatus.success &&
        state.value.status != LocalSyncStatus.error) {
      // A manual sync is running: try again once it is over.
      _scheduleLocalSync();
      return;
    }

    _silentSyncRunning = true;
    try {
      final now = DateTime.now();
      final targets =
          (await discoverDevices(duration: const Duration(seconds: 2)))
              .where(
                (d) =>
                    isDevicePaired(d.deviceId) &&
                    !(_retryAfter[d.deviceId]?.isAfter(now) ?? false),
              )
              .toList();
      // Devices synced before the last one that brought changes have not seen them yet.
      var lastChanged = -1;
      for (var i = 0; i < targets.length; i++) {
        if (await _syncQuietly(targets[i])) lastChanged = i;
      }
      for (var i = 0; i < lastChanged; i++) {
        await _syncQuietly(targets[i]);
      }
    } finally {
      _silentSyncRunning = false;
    }
    if (_syncAgain) {
      _syncAgain = false;
      await triggerSilentSync();
    }
  }

  /// Returns whether this device's data changed; failures back off exponentially.
  Future<bool> _syncQuietly(DiscoveredSyncDevice device) async {
    try {
      final result = await _performSync(device);
      await _recordSync(device.deviceId, device.name);
      return result.local.isNotEmpty;
    } catch (e) {
      logger.log('Automatic local sync with ${device.name} failed: $e');
      final count = (_retryCount[device.deviceId] ?? 0) + 1;
      _retryCount[device.deviceId] = count;
      _retryAfter[device.deviceId] = DateTime.now().add(
        Duration(seconds: min(1800, 30 * pow(2, min(count, 6)).toInt())),
      );
      return false;
    }
  }

  Future<void> _requestPairing(DiscoveredSyncDevice target) async {
    if (_outgoingTarget == target.deviceId &&
        _outgoingChallenge != null &&
        (_outgoingExpires?.isAfter(DateTime.now()) ?? false)) {
      return;
    }
    final response = await _post(target, '/api/sync/pair-request', {
      'apiVersion': apiVersion,
      'clientId': LibraryMergeService.deviceId,
      'clientName': deviceName,
    }, timeout: _shortTimeout);
    if (response['deviceId'] != target.deviceId ||
        response['session'] is! String ||
        response['challenge'] is! Map) {
      throw const _LocalSyncException(LocalSyncError.updateRequired);
    }
    _outgoingSession = response['session'];
    _outgoingTarget = target.deviceId;
    _outgoingExpires = DateTime.now().add(_pairingTimeout);
    _outgoingChallenge = Map<String, dynamic>.from(response['challenge']);
  }

  Future<void> _verifyPairing(DiscoveredSyncDevice target, String pin) async {
    final session = _outgoingSession!;
    final pairing = await PinPairingClient.create(
      _outgoingChallenge!,
      '${LibraryMergeService.deviceId}|${target.deviceId}|$session',
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
    if (proof['deviceId'] != target.deviceId || proof['status'] != 'paired') {
      throw const _LocalSyncException(LocalSyncError.incorrectPin);
    }
    await _trust(
      target.deviceId,
      proof['deviceName']?.toString() ?? target.name,
      secret,
    );
    _outgoingSession = null;
    _outgoingTarget = null;
    _outgoingExpires = null;
  }

  Future<Map<String, dynamic>> _securePost(
    DiscoveredSyncDevice target,
    String path,
    Map<String, dynamic> body,
  ) async {
    final peer = _paired(target.deviceId);
    if (peer == null) throw const _LocalSyncException(LocalSyncError.untrusted);
    if (_httpServer == null) {
      throw const _LocalSyncException(LocalSyncError.notRunning);
    }
    final ownId = LibraryMergeService.deviceId;
    final nonce = SyncSecurity.randomToken(24);
    final counterKey =
        'localSyncSent:${target.deviceId}:${syncDigest(peer.secret)}';
    final store = Hive.box('userNoBackup');
    final sequence = (store.get(counterKey, defaultValue: 0) as int) + 1;
    await store.put(counterKey, sequence);
    await store.flush();
    final encrypted = await SyncSecurity.sealInBackground(peer.secret, {
      ...body,
      'requestId': nonce,
      'sequence': sequence,
    }, '${path.substring(1)}|$ownId|${target.deviceId}');
    final response = await _post(
      target,
      path,
      {'apiVersion': apiVersion, 'encrypted': encrypted},
      timeout: _mergeTimeout,
      headers: {_deviceHeader: ownId},
    );
    if (response['encrypted'] is! Map) {
      throw const _LocalSyncException(LocalSyncError.updateRequired);
    }
    final result = await SyncSecurity.openInBackground(
      peer.secret,
      response['encrypted'],
      '${path.substring(1)}|${target.deviceId}|$ownId',
    );
    if (result['requestId'] != nonce) {
      throw const _LocalSyncException(LocalSyncError.failed);
    }
    return result;
  }

  /// One sync at a time per device, so both directions never interleave.
  Future<({Set<String> local, Set<String> remote})> _performSync(
    DiscoveredSyncDevice target, {
    void Function(LocalSyncStage)? onStage,
  }) {
    final previous = _outbound[target.deviceId] ?? Future.value();
    final done = Completer<void>();
    _outbound[target.deviceId] = done.future;
    return previous
        .then((_) async {
          _beginTransfer();
          try {
            return await _performSyncUnlocked(target, onStage: onStage);
          } finally {
            _endTransfer();
          }
        })
        .whenComplete(() {
          done.complete();
          if (identical(_outbound[target.deviceId], done.future)) {
            _outbound.remove(target.deviceId);
          }
        });
  }

  Future<({Set<String> local, Set<String> remote})> _performSyncUnlocked(
    DiscoveredSyncDevice target, {
    void Function(LocalSyncStage stage)? onStage,
  }) async {
    final capabilities = await _securePost(
      target,
      '/api/sync/capabilities',
      {},
    );
    if (capabilities['schemaVersion'] != syncSchemaVersion) {
      throw const _LocalSyncException(LocalSyncError.updateRequired);
    }
    final categories = selectedCategories.intersection(
      parseSyncCategories(capabilities['categories']),
    );
    if (categories.isEmpty) {
      throw const _LocalSyncException(LocalSyncError.noCommonCategories);
    }
    onStage?.call(LocalSyncStage.exporting);
    final library = await LibraryMergeService.exportLibrary(
      categories: categories,
    );
    onStage?.call(LocalSyncStage.exchanging);
    final response = await _securePost(target, '/api/sync/merge', {
      'categories': categories.map((e) => e.name).toList(),
      'library': library,
    });
    if (response['library'] is! Map) {
      throw const _LocalSyncException(LocalSyncError.failed);
    }
    onStage?.call(LocalSyncStage.merging);
    if (_httpServer == null) {
      throw const _LocalSyncException(LocalSyncError.notRunning);
    }
    final local = await LibraryMergeService.mergeLibrary(
      Map<String, dynamic>.from(response['library']),
      categories: categories,
    );
    _retryAfter.remove(target.deviceId);
    _retryCount.remove(target.deviceId);
    final remote = response['changed'];
    return (
      local: local.changed,
      remote: remote is List ? remote.whereType<String>().toSet() : <String>{},
    );
  }

  Future<void> _recordSync(String deviceId, String name) async {
    final now = DateTime.now().toUtc();
    await Hive.box('settings').put(_lastSyncedAtKey, now.toIso8601String());
    localSyncLastSyncedAt.value = now;
    await _serializePaired(() async {
      final peer = _paired(deviceId);
      if (peer != null && peer.name != name) {
        await _savePairedDeviceUnlocked(
          PairedSyncDevice(deviceId: deviceId, name: name, secret: peer.secret),
        );
      }
    });
  }

  Future<Map<String, dynamic>> _post(
    DiscoveredSyncDevice target,
    String path,
    Map<String, dynamic> body, {
    required Duration timeout,
    Map<String, String> headers = const {},
  }) async {
    final encoded = utf8.encode(json.encode(body));
    if (encoded.length > maxSyncMessageBytes) {
      throw const _LocalSyncException(LocalSyncError.tooLarge);
    }
    final outgoing =
        http.Request(
            'POST',
            Uri(scheme: 'http', host: target.ip, port: target.port, path: path),
          )
          ..headers.addAll({'Content-Type': 'application/json', ...headers})
          ..bodyBytes = encoded;
    final response = await _client.send(outgoing).timeout(timeout);
    final responseBytes = await _readMessage(response.stream).timeout(timeout);
    dynamic decoded;
    try {
      decoded = json.decode(utf8.decode(responseBytes));
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = decoded is Map ? decoded['error']?.toString() : null;
      throw _HttpFailure(response.statusCode, code ?? '');
    }
    if (decoded is! Map) {
      throw const _LocalSyncException(LocalSyncError.failed);
    }
    return Map<String, dynamic>.from(decoded);
  }

  LocalSyncError _errorFor(Object error, {required bool pairing}) {
    if (error is _LocalSyncException) return error.error;
    if (error is SyncTooLargeException) return LocalSyncError.tooLarge;
    if (error is _HttpFailure) {
      return switch (error.status) {
        426 => LocalSyncError.updateRequired,
        429 => LocalSyncError.busy,
        413 => LocalSyncError.tooLarge,
        403 when error.code == 'incorrect_pin' => LocalSyncError.incorrectPin,
        403 => pairing ? LocalSyncError.rejected : LocalSyncError.untrusted,
        _ => LocalSyncError.failed,
      };
    }
    if (error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException) {
      return LocalSyncError.unreachable;
    }
    return LocalSyncError.failed;
  }

  void _onLocalChange(BoxEvent event) {
    final key = event.key.toString();
    // Consume merge writes even when the changed category is disabled.
    final isMerge = LibraryMergeService.isMergeWrite(key, event.value);
    if (key == 'wrappedListeningStats') {
      final recap = event.value;
      final reset = recap is Map && recap['syncResetId'] is String
          ? recap['syncResetId'] as String
          : null;
      final resetChanged = reset != null && reset != _observedRecapReset;
      _observedRecapReset = reset;
      if (isMerge || !resetChanged) return;
    }
    if (isMerge ||
        pairedDevices.value.isEmpty ||
        !selectedCategories.any((c) => syncCategoryKeys[c]!.contains(key))) {
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

  /// The limited broadcast plus each interface's /24 broadcast.
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

  Future<Uint8List> _readMessage(
    Stream<List<int>> stream, {
    int maxBytes = maxSyncMessageBytes,
  }) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const _HttpFailure(413, 'too_large');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  /// Reads a request body, giving up after [_bodyTimeout]. Unlike a timeout
  /// on the future, this stops listening, so a client that stalls or trickles
  /// cannot keep the read and its buffer alive; the reply that follows ends
  /// the connection, as the body was not read to its end.
  Future<Uint8List> _readBody(HttpRequest request, {required int maxBytes}) {
    final result = Completer<Uint8List>();
    final bytes = BytesBuilder(copy: false);
    late final StreamSubscription<List<int>> subscription;
    void finish(void Function() complete) {
      if (result.isCompleted) return;
      complete();
      unawaited(subscription.cancel());
    }

    final timer = Timer(
      _bodyTimeout,
      () => finish(
        () => result.completeError(const _HttpFailure(408, 'request_timeout')),
      ),
    );
    subscription = request.listen(
      (chunk) {
        if (bytes.length + chunk.length > maxBytes) {
          finish(
            () => result.completeError(const _HttpFailure(413, 'too_large')),
          );
        } else {
          bytes.add(chunk);
        }
      },
      onDone: () => finish(() {
        _bodyRead[request] = true;
        result.complete(bytes.takeBytes());
      }),
      onError: (Object error, StackTrace stackTrace) =>
          finish(() => result.completeError(error, stackTrace)),
      cancelOnError: true,
    );
    return result.future.whenComplete(timer.cancel);
  }

  Future<Map<String, dynamic>> _readJson(
    HttpRequest request, {
    required int maxBytes,
  }) async {
    final bytes = await _readBody(request, maxBytes: maxBytes);
    final decoded = json.decode(utf8.decode(bytes));
    if (decoded is! Map) throw const _HttpFailure(400, 'invalid');
    return Map<String, dynamic>.from(decoded);
  }
}

class _LocalSyncException implements Exception {
  const _LocalSyncException(this.error);

  final LocalSyncError error;

  @override
  String toString() => error.name;
}

class _HttpFailure implements Exception {
  const _HttpFailure(this.status, this.code);

  final int status;
  final String code;

  @override
  String toString() => 'HTTP $status: $code';
}
