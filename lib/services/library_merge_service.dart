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
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_merge.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/settings_manager.dart';

export 'local_sync/sync_data.dart' show SyncCategory, syncCategoryKeys;

class LibraryMergeService {
  LibraryMergeService._();
  static const schemaVersion = syncSchemaVersion;
  static const libraryKeys = [
    'likedSongs',
    'likedRadioStations',
    'playlists',
    'likedPlaylists',
    'customPlaylists',
    'playlistFolders',
    'pinnedPlaylistIds',
    'recentlyPlayedSongs',
    'searchHistory',
    'wrappedListeningStats',
  ];
  static const _documentKey = 'localSyncDocumentV2';
  static const _baselineKey = 'localSyncBaselineV2';
  static const _journalKey = 'localSyncPendingMergeV2';
  static Future<void> _tail = Future.value();
  @visibleForTesting
  static Future<void> Function(String stage)? fault;

  static Future<T> _locked<T>(Future<T> Function() action) {
    final done = Completer<void>();
    final previous = _tail;
    _tail = done.future;
    return previous.then((_) => action()).whenComplete(done.complete);
  }

  static Future<void> awaitIdle() => _locked(() async {});

  /// After a backup restore, so the restored library is added rather than read as deletions.
  static Future<void> forgetBaseline() => _locked(() async {
    await Hive.box('userNoBackup').delete(_baselineKey);
  });

  static Future<void> recoverPendingMerge() async {
    final store = Hive.box('userNoBackup');
    final journal = store.get(_journalKey);
    if (journal is! Map) return;
    final before = Map<String, dynamic>.from(journal['user']);
    final absent = (journal['absent'] as List).cast<String>();
    final after = journal['after'] as Map?;
    bool unchanged(String key) =>
        after == null ||
        canonicalSync(encodeSyncValue(Hive.box('user').get(key))) ==
            canonicalSync(after[key]);
    await Hive.box('user').putAll(
      decodeSyncValue({
        for (final e in before.entries)
          if (unchanged(e.key)) e.key: e.value,
      }) as Map,
    );
    await Hive.box('user').deleteAll(absent.where(unchanged));
    await Hive.box('user').flush();
    for (final key in [_documentKey, _baselineKey]) {
      if (journal[key] == null) {
        await store.delete(key);
      } else {
        await store.put(key, journal[key]);
      }
    }
    await store.delete(_journalKey);
    await store.flush();
    _refresh();
  }

  /// This installation's sync identity, created on first use.
  static String get deviceId {
    final store = Hive.box('userNoBackup');
    final existing = store.get('localSyncDeviceId');
    if (existing is String && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    unawaited(store.put('localSyncDeviceId', id));
    return id;
  }

  /// Whether any of [keys] changed since the last sync captured them.
  static Future<bool> hasUnsyncedChanges(Iterable<String> keys) =>
      _locked(() async {
        final baseline = _baseline();
        if (baseline == null) return true;
        final current = _snapshot();
        return keys.any(
          (key) => canonicalSync(current[key]) != canonicalSync(baseline[key]),
        );
      });

  static Map<String, dynamic> _snapshot() {
    final user = Hive.box('user');
    return {
      for (final key in libraryKeys)
        if (key != 'wrappedListeningStats' || user.get(key) != null)
          key: encodeSyncValue(user.get(key, defaultValue: [])),
    };
  }

  static SyncDocument _document() {
    final raw = Hive.box('userNoBackup').get(_documentKey);
    return raw is Map ? SyncDocument.fromMap(raw) : SyncDocument();
  }

  static Map<String, dynamic>? _baseline() {
    final raw = Hive.box('userNoBackup').get(_baselineKey);
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static Future<void> _save(
    SyncDocument document,
    Map<String, dynamic> baseline,
  ) async {
    SyncDocument.fromMap(document.toMap());
    await Hive.box('userNoBackup')
        .putAll({_documentKey: document.toMap(), _baselineKey: baseline});
    await Hive.box('userNoBackup').flush();
  }

  static Map<String, dynamic> _payload(
    SyncDocument document,
    Set<SyncCategory> categories,
  ) => {
    'schemaVersion': schemaVersion,
    'categories': categories.map((e) => e.name).toList()..sort(),
    'document': document.select(categories).toMap(),
  };

  static Future<Map<String, dynamic>> exportLibrary({
    Set<SyncCategory>? categories,
  }) => _locked(() async {
    await listeningStatsService.prepareForSync();
    final current = _snapshot();
    final document = _document();
    if (document.capture(current, _baseline(), deviceId)) {
      await _save(document, current);
    }
    return _payload(document, categories ?? SyncCategory.values.toSet());
  });

  /// Merges [remote] and returns what changed plus this side's merged payload.
  static Future<({Map<String, int> stats, Map<String, dynamic> library})>
  mergeLibrary(Map<String, dynamic> remote, {Set<SyncCategory>? categories}) =>
      _locked(() async {
        if (remote['schemaVersion'] != schemaVersion ||
            remote['document'] is! Map ||
            remote['document']['version'] != schemaVersion) {
          throw const FormatException(
            'Unsupported sync version. Update both devices.',
          );
        }
        final incomingCategories = parseSyncCategories(remote['categories']);
        final selected = categories ?? SyncCategory.values.toSet();
        if (!selected.containsAll(incomingCategories)) {
          throw const FormatException('Sync categories changed');
        }
        final incoming = SyncDocument.fromMap(remote['document']);
        if (incoming.select(incomingCategories).records.length !=
            incoming.records.length) {
          throw const FormatException('Unselected sync data');
        }
        await listeningStatsService.prepareForSync();
        final store = Hive.box('userNoBackup');
        for (var attempt = 0; attempt < 4; attempt++) {
          final current = _snapshot();
          final document = _document();
          final captured = document.capture(current, _baseline(), deviceId);
          final metadataChanges = document.join(incoming);
          final reply = _payload(document, incomingCategories);
          if (!captured && metadataChanges == 0) {
            return (stats: <String, int>{}, library: reply);
          }
          final merged = document.materialize();
          final keys = incomingCategories
              .expand((c) => syncCategoryKeys[c]!)
              .toSet();
          final updates = <String, dynamic>{};
          final stats = <String, int>{if (metadataChanges > 0) '_metadata': 1};
          for (final key in keys) {
            if (canonicalSync(current[key]) != canonicalSync(merged[key])) {
              updates[key] = merged[key];
              stats[key] = 1;
            }
          }
          if (updates.isEmpty) {
            await _save(document, current);
            return (stats: stats, library: reply);
          }
          final journal = {
            'user': {
              for (final key in updates.keys)
                if (Hive.box('user').containsKey(key)) key: current[key],
            },
            'after': updates,
            'absent': updates.keys
                .where((key) => !Hive.box('user').containsKey(key))
                .toList(),
            _documentKey: store.get(_documentKey),
            _baselineKey: store.get(_baselineKey),
          };
          await store.put(_journalKey, journal);
          await store.flush();
          if (canonicalSync(current) != canonicalSync(_snapshot())) {
            await store.delete(_journalKey);
            continue;
          }
          try {
            await fault?.call('prepared');
            if (canonicalSync(current) != canonicalSync(_snapshot())) {
              await store.delete(_journalKey);
              continue;
            }
            final write = Hive.box('user')
                .putAll(decodeSyncValue(updates) as Map);
            _refresh();
            await write;
            await Hive.box('user').flush();
            await fault?.call('written');
            await _save(document, {...current, ...updates});
            await fault?.call('metadata');
            await store.delete(_journalKey);
            await store.flush();
            return (stats: stats, library: reply);
          } catch (_) {
            await recoverPendingMerge();
            rethrow;
          }
        }
        throw StateError('Library is changing; try syncing again.');
      });

  static int totalAdded(Map<String, int> stats) => stats.entries
      .where((entry) => !entry.key.startsWith('_'))
      .fold(0, (sum, entry) => sum + entry.value);
  static void _refresh() {
    reloadSettingsFromStorage();
    reloadSongLibraryStateFromStorage();
    reloadPlaylistLibraryStateFromStorage();
    reloadSearchHistoryFromStorage();
    listeningStatsService.reload();
  }
}
