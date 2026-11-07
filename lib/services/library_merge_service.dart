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
import 'package:hive_ce/hive_ce.dart';
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
  static const _documentKey = 'localSyncDocumentV2';
  static const _baselineKey = 'localSyncBaselineV2';
  static const _journalKey = 'localSyncPendingMergeV2';
  static Future<void> _tail = Future.value();
  static final Map<String, String> _written = {};
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
    const recapKey = 'wrappedListeningStats';
    final touchesRecap =
        before.containsKey(recapKey) || absent.contains(recapKey);
    if (touchesRecap) await listeningStatsService.prepareForSync();
    bool unchanged(String key) =>
        !(key == recapKey && listeningStatsService.hasPendingChanges) &&
        (after == null ||
            canonicalSync(encodeSyncValue(Hive.box('user').get(key))) ==
                canonicalSync(after[key]));
    final restore = {
      for (final e in before.entries)
        if (unchanged(e.key)) e.key: e.value,
    };
    final remove = absent.where(unchanged).toList();
    final restoredRecap =
        restore.containsKey(recapKey) || remove.contains(recapKey);
    await Hive.box('user').putAll(decodeSyncValue(restore) as Map);
    await Hive.box('user').deleteAll(remove);
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
    _refresh(
      reloadRecap: restoredRecap && !listeningStatsService.hasPendingChanges,
    );
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

  /// Whether this `user` box event is the merge's own write; each write is matched once.
  static bool isMergeWrite(String key, Object? value) {
    final written = _written.remove(key);
    return written != null && written == syncDigest(value);
  }

  /// A `user` box without a single key, next to a baseline that remembers
  /// items, is a library that went missing: capturing it would send the
  /// deletion of everything to every device.
  static void _refuseMissingLibrary() {
    final baseline = _baseline();
    if (baseline == null || Hive.box('user').isNotEmpty) return;
    // The search history does not count: it can be emptied on purpose.
    final remembersItems = baseline.entries.any(
      (entry) =>
          entry.key != 'searchHistory' &&
          ((entry.value is List && (entry.value as List).isNotEmpty) ||
              (entry.value is Map && (entry.value as Map).isNotEmpty)),
    );
    if (remembersItems) {
      throw StateError('The library is missing; sync is stopped.');
    }
  }

  /// Entries that cannot be exchanged (no id, or one that is not safe) are
  /// not in the merged library; a merge puts them back where they were on
  /// this device instead of erasing them.
  static Object? _keepEntriesWithoutId(
    String key,
    Object? merged,
    Map<String, dynamic> current,
  ) {
    bool unexchanged(Object? item) =>
        item is Map && !SyncDocument.isSyncableId(item['ytid']?.toString());

    List<dynamic> putBack(Object? mergedList, Object? localList) {
      final result = mergedList is List
          ? List<dynamic>.of(mergedList)
          : <dynamic>[];
      if (localList is List) {
        for (var i = 0; i < localList.length; i++) {
          if (unexchanged(localList[i])) {
            result.insert(min(i, result.length), localList[i]);
          }
        }
      }
      return result;
    }

    // The playlists of this device wherever they are (on top or in a folder).
    Map<String, Map> localPlaylists() => {
      for (final list in [
        current['customPlaylists'],
        for (final folder in current['playlistFolders'] as List? ?? const [])
          if (folder is Map) folder['playlists'],
      ])
        for (final playlist in list as List? ?? const [])
          if (playlist is Map && playlist['ytid'] != null)
            playlist['ytid'].toString(): playlist,
    };

    List<dynamic> songsPutBack(Object? playlists, Map<String, Map> local) => [
      for (final playlist in playlists as List? ?? const [])
        if (playlist is Map && local[playlist['ytid']?.toString()] != null)
          {
            ...playlist,
            'list': putBack(
              playlist['list'],
              local[playlist['ytid'].toString()]!['list'],
            ),
          }
        else
          playlist,
    ];

    switch (key) {
      case 'likedSongs' || 'likedPlaylists' || 'recentlyPlayedSongs':
        return merged is List ? putBack(merged, current[key]) : merged;
      case 'customPlaylists':
        return merged is List ? songsPutBack(merged, localPlaylists()) : merged;
      case 'playlistFolders':
        final local = localPlaylists();
        return merged is List
            ? [
                for (final folder in merged)
                  if (folder is Map)
                    {
                      ...folder,
                      'playlists': songsPutBack(folder['playlists'], local),
                    }
                  else
                    folder,
              ]
            : merged;
    }
    return merged;
  }

  // Local file paths are never exchanged, but remain useful on this device.
  static Object? _keepLocalPaths(Object? merged, Object? local) {
    const keys = {
      'audioPath',
      'artworkPath',
      'artWorkPath',
      'filePath',
      'downloadPath',
      'localPath',
      'path',
    };
    if (merged is Map && local is Map) {
      return <String, dynamic>{
        for (final e in merged.entries)
          e.key.toString(): _keepLocalPaths(e.value, local[e.key]),
        for (final key in keys)
          if (local.containsKey(key)) key: local[key],
      };
    }
    if (merged is List && local is List) {
      Object? identity(Object? item) =>
          item is Map ? item['ytid'] ?? item['id'] : null;
      final originals = <Object, Object?>{};
      for (final item in local) {
        final id = identity(item);
        if (id != null) originals[id] = item;
      }
      return [
        for (final item in merged)
          _keepLocalPaths(item, originals[identity(item)]),
      ];
    }
    return merged;
  }

  static Map<String, dynamic> _snapshot() {
    final user = Hive.box('user');
    return {
      for (final key in syncCategoryKeys.values.expand((keys) => keys))
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
    'schemaVersion': syncSchemaVersion,
    'categories': categories.map((e) => e.name).toList()..sort(),
    'document': document.select(categories).toMap(),
  };

  static Future<Map<String, dynamic>> exportLibrary({
    Set<SyncCategory>? categories,
  }) => _locked(() async {
    _refuseMissingLibrary();
    await listeningStatsService.prepareForSync();
    final current = _snapshot();
    final document = _document();
    if (document.capture(current, _baseline(), deviceId)) {
      await _save(document, current);
    }
    return _payload(document, categories ?? SyncCategory.values.toSet());
  });

  /// Merges [remote] and returns what changed plus this side's merged payload.
  static Future<({Set<String> changed, Map<String, dynamic> library})>
  mergeLibrary(Map<String, dynamic> remote, {Set<SyncCategory>? categories}) =>
      _locked(() async {
        if (remote['schemaVersion'] != syncSchemaVersion ||
            remote['document'] is! Map ||
            remote['document']['version'] != syncSchemaVersion) {
          throw const FormatException(
            'Unsupported sync version. Update both devices.',
          );
        }
        final incomingCategories = parseSyncCategories(remote['categories']);
        final selected = categories ?? SyncCategory.values.toSet();
        if (!selected.containsAll(incomingCategories)) {
          throw const FormatException('Sync categories changed');
        }
        _refuseMissingLibrary();
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
            return (changed: <String>{}, library: reply);
          }
          final merged = document.materialize();
          final keys = incomingCategories
              .expand((c) => syncCategoryKeys[c]!)
              .toSet();
          final updates = <String, dynamic>{};
          for (final key in keys) {
            final value = _keepEntriesWithoutId(
              key,
              _keepLocalPaths(merged[key], current[key]),
              current,
            );
            if (canonicalSync(current[key]) != canonicalSync(value)) {
              updates[key] = value;
            }
          }
          final changed = {
            ...updates.keys,
            if (metadataChanges > 0) '_metadata',
          };
          if (updates.isEmpty) {
            await _save(document, current);
            return (changed: changed, library: reply);
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
            final updatesRecap = updates.containsKey('wrappedListeningStats');
            if (updatesRecap) {
              await listeningStatsService.prepareForSync();
              await fault?.call('recapFlushed');
            }
            if ((updatesRecap && listeningStatsService.hasPendingChanges) ||
                canonicalSync(current) != canonicalSync(_snapshot())) {
              await store.delete(_journalKey);
              continue;
            }
            for (final e in updates.entries) {
              _written[e.key] = syncDigest(e.value);
            }
            final write = Hive.box('user')
                .putAll(decodeSyncValue(updates) as Map);
            _refresh(reloadRecap: updates.containsKey('wrappedListeningStats'));
            await write;
            await Hive.box('user').flush();
            await fault?.call('written');
            await _save(document, {...current, ...updates});
            await fault?.call('metadata');
            await store.delete(_journalKey);
            await store.flush();
            return (changed: changed, library: reply);
          } catch (_) {
            await recoverPendingMerge();
            rethrow;
          }
        }
        throw StateError('Library is changing; try syncing again.');
      });

  static void _refresh({bool reloadRecap = true}) {
    reloadSettingsFromStorage();
    reloadSongLibraryStateFromStorage();
    reloadPlaylistLibraryStateFromStorage();
    reloadSearchHistoryFromStorage();
    if (reloadRecap) listeningStatsService.reload();
  }
}
