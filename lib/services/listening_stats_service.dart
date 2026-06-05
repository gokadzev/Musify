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

import 'package:hive/hive.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/listening_stats_utils.dart';

final listeningStatsService = ListeningStatsService();

class ListeningStatsService {
  static const storageKey = 'wrappedListeningStats';
  static const _persistInterval = Duration(seconds: 10);

  Map<String, dynamic>? _stats;
  Timer? _persistTimer;
  Duration _listeningTimeRemainder = Duration.zero;
  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);

  bool get hasStats {
    final now = DateTime.now();
    final stats = _readStats();
    final history = stats['history'] as Map<String, dynamic>;
    return hasDisplayableListeningStats(_asMap(stats['currentMonth'])) ||
        history.values.any(
          (month) => hasDisplayableListeningStats(_asMap(month)),
        ) ||
        (isListeningStatsAnnualWindow(now) &&
            hasDisplayableAnnualListeningStats(stats, now));
  }

  bool get isAnnualRecapAvailable {
    final now = DateTime.now();
    if (!isListeningStatsAnnualWindow(now)) return false;

    return hasDisplayableAnnualListeningStats(_readStats(now), now);
  }

  int get year => listeningStatsAnnualYear(DateTime.now());

  int get yearTotalSeconds {
    final now = DateTime.now();
    return annualTotalSecondsFromStats(_readStats(now), now);
  }

  List<String> get availableMonthKeys {
    final now = DateTime.now();
    return visibleListeningStatsMonthKeys(_readStats(now), now);
  }

  Map<String, dynamic>? monthStats(String monthKey) {
    final stats = _readStats();
    Map<String, dynamic>? month;
    if (monthKey == stats['currentMonthKey']?.toString()) {
      month = _asMap(stats['currentMonth']);
    } else {
      final history = stats['history'] as Map<String, dynamic>;
      month = _asMap(history[monthKey]);
    }

    return month;
  }

  List<Map<String, dynamic>> monthTopSongs(
    String monthKey, {
    int limit = wrappedMonthlyHistorySongsLimit,
  }) {
    final month = monthStats(monthKey);
    return sortedListeningSongs(_asMap(month?['songs']), limit: limit);
  }

  List<Map<String, dynamic>> yearTopSongs({
    int limit = wrappedAnnualSongsLimit,
  }) {
    final now = DateTime.now();
    final months = annualListeningMonthsFromStats(_readStats(now), now);
    return annualListeningSongsFromMonths(months, limit: limit);
  }

  void recordListeningTime(Duration listenedDuration, {DateTime? listenedAt}) {
    if (!wrappedEnabled.value) return;
    if (listenedDuration <= Duration.zero) return;

    _listeningTimeRemainder += listenedDuration;
    final wholeSeconds = _listeningTimeRemainder.inSeconds;
    if (wholeSeconds <= 0) return;
    _listeningTimeRemainder -= Duration(seconds: wholeSeconds);

    final now = listenedAt ?? DateTime.now();
    _stats = applyListeningTimeDelta(
      _readStats(now),
      listenedDuration: Duration(seconds: wholeSeconds),
      listenedAt: now,
    );
    _schedulePersist();
  }

  void recordListening(
    Map song,
    Duration listenedDuration, {
    bool incrementPlayCount = false,
    bool countTotalSeconds = true,
    DateTime? listenedAt,
  }) {
    if (!wrappedEnabled.value) return;

    final now = listenedAt ?? DateTime.now();
    _stats = applyListeningStatsDelta(
      _readStats(now),
      song: song,
      listenedDuration: listenedDuration,
      listenedAt: now,
      incrementPlayCount: incrementPlayCount,
      countTotalSeconds: countTotalSeconds,
    );
    if (incrementPlayCount || listenedDuration > Duration.zero) {
      _schedulePersist();
    }
  }

  void reload() {
    _stats = null;
  }

  Future<void> clearStats() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    _listeningTimeRemainder = Duration.zero;
    final now = DateTime.now();
    _stats = createEmptyListeningStats(
      now.year,
      currentMonthKey: listeningStatsMonthKey(now),
    );
    await deleteData('user', storageKey);
  }

  void flush() {
    _persistTimer?.cancel();
    _persistTimer = null;
    unawaited(_persist());
  }

  Map<String, dynamic> _readStats([DateTime? now]) {
    final currentDate = now ?? DateTime.now();
    final cached = _stats;
    if (cached != null) {
      final previousMonthKey = cached['currentMonthKey']?.toString();
      _stats = normalizeListeningStats(cached, currentDate);
      if (previousMonthKey != _stats!['currentMonthKey']?.toString()) {
        _schedulePersist();
      }
      return _stats!;
    }

    final raw = Hive.box('user').get(storageKey);
    _stats = normalizeListeningStats(raw, currentDate);
    if (_shouldPersistNormalizedStats(raw, _stats!)) {
      _schedulePersist();
    }
    return _stats!;
  }

  void _schedulePersist() {
    final now = DateTime.now();
    final nextPersist = _lastPersist.add(_persistInterval);
    if (!now.isBefore(nextPersist)) {
      _persistTimer?.cancel();
      _persistTimer = null;
      unawaited(_persist());
      return;
    }

    _persistTimer ??= Timer(nextPersist.difference(now), () {
      _persistTimer = null;
      unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    final stats = _stats;
    if (stats == null) return;
    _lastPersist = DateTime.now();
    await addOrUpdateData('user', storageKey, stats);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  bool _shouldPersistNormalizedStats(
    dynamic raw,
    Map<String, dynamic> normalized,
  ) {
    if (raw is! Map) return false;

    if (raw['schemaVersion'] != wrappedListeningStatsSchemaVersion) {
      return true;
    }

    if (raw.containsKey('months') ||
        raw.containsKey('yearSongs') ||
        raw.containsKey('yearTotalSeconds')) {
      return true;
    }

    if (raw['currentMonthKey']?.toString() !=
        normalized['currentMonthKey']?.toString()) {
      return true;
    }

    if (_hasUnqualifiedSongs(raw['currentMonth'])) {
      return true;
    }

    if (_songCount(raw['currentMonth']) > wrappedCurrentMonthSongsLimit) {
      return true;
    }

    final rawHistory = _asMap(raw['history']) ?? const <String, dynamic>{};
    final normalizedHistory =
        _asMap(normalized['history']) ?? const <String, dynamic>{};

    if (!_sameKeys(rawHistory, normalizedHistory)) return true;

    if (rawHistory.values.any(_hasUnqualifiedSongs)) return true;

    return rawHistory.values.any(
      (month) => _songCount(month) > wrappedMonthlyHistorySongsLimit,
    );
  }

  bool _sameKeys(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
    }

    return true;
  }

  int _songCount(dynamic month) {
    final monthMap = _asMap(month);
    final songs = _asMap(monthMap?['songs']);
    return songs?.length ?? 0;
  }

  bool _hasUnqualifiedSongs(dynamic month) {
    final monthMap = _asMap(month);
    final songs = _asMap(monthMap?['songs']);
    if (songs == null) return false;

    return songs.values.any((value) {
      final song = _asMap(value);
      if (song == null) return false;
      final playCount = song['playCount'] is int
          ? song['playCount'] as int
          : int.tryParse(song['playCount']?.toString() ?? '') ?? 0;
      return playCount <= 0;
    });
  }
}
