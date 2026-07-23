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
import 'package:just_audio/just_audio.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/listening_stats_utils.dart';
import 'package:musify/utilities/map_utils.dart';

final listeningStatsService = ListeningStatsService();

class ListeningStatsService {
  static const storageKey = 'wrappedListeningStats';

  Map<String, dynamic>? _stats;
  // Stats are accumulated in memory and only written to Hive at meaningful
  // checkpoints (track change, pause, stop, app backgrounding) via [flush],
  // instead of on a periodic timer. This keeps device I/O off the hot path
  // during continuous playback.
  bool _dirty = false;
  Duration _listeningTimeRemainder = Duration.zero;

  // Playback-session bookkeeping stays here so the audio handler can focus on
  // transport and lifecycle, not on stats-specific state transitions.
  Map<String, dynamic>? _sessionSong;
  String? _sessionSongId;
  Duration? _sessionDuration;
  Duration _sessionListened = Duration.zero;
  DateTime? _sessionLastTick;
  bool _sessionQualified = false;
  bool _sessionLastAudioPlayerPlaying = false;

  bool get hasStats {
    final now = DateTime.now();
    final stats = _readStats(now);
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
    _markDirty();
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
      _markDirty();
    }
  }

  void updateListeningSessionDuration(
    String? currentSongYtid,
    Duration duration,
  ) {
    if (_sessionSongId == currentSongYtid) {
      _sessionDuration = duration;
    }
  }

  void startListeningSession(
    Map song, {
    Duration? duration,
    DateTime? startedAt,
  }) {
    if (!wrappedEnabled.value) return;

    final ytid = song['ytid']?.toString();
    if (ytid == null || ytid.isEmpty) return;

    _sessionSong = cloneMap(song);
    _sessionSongId = ytid;
    _sessionDuration = duration ?? _durationFromSong(song);
    _sessionListened = Duration.zero;
    _sessionQualified = false;
    _sessionLastTick = startedAt ?? DateTime.now();
    // A session is started only once playback has begun, so mark it playing now;
    // otherwise ticks before the next playerState transition would be dropped.
    _sessionLastAudioPlayerPlaying = true;
  }

  void resumeListeningSession({Map? currentSong}) {
    if (!wrappedEnabled.value) return;

    final song = currentSong;
    if (song == null) return;

    final ytid = song['ytid']?.toString();
    if (ytid == null || ytid.isEmpty) return;

    if (_sessionSongId != ytid) {
      // Reached from handlePlayerStateForListeningStats before
      // _sessionLastAudioPlayerPlaying is updated, so the flag still holds the
      // pre-transition value (false). We just got a "playing" event for a
      // different song, meaning the previous one was playing up to this tick;
      // pass wasPlaying: true explicitly so its final tick isn't dropped.
      finishListeningSession(countCurrentTick: true, wasPlaying: true);
      startListeningSession(song);
      return;
    }

    _sessionLastTick = DateTime.now();
    _sessionLastAudioPlayerPlaying = true;
  }

  void recordListeningSessionProgress({bool? wasPlaying}) {
    final song = _sessionSong;
    if (song == null) return;

    final now = DateTime.now();
    final lastTick = _sessionLastTick;
    _sessionLastTick = now;
    if (lastTick == null) return;

    final shouldCount = wasPlaying ?? _sessionLastAudioPlayerPlaying;
    if (!shouldCount) return;

    final listenedDuration = now.difference(lastTick);
    if (listenedDuration <= Duration.zero) return;

    if (!wrappedEnabled.value) {
      return;
    }

    _sessionListened += listenedDuration;
    recordListeningTime(listenedDuration, listenedAt: now);

    if (!_sessionQualified) {
      if (_sessionListened >= qualifiedPlaybackThreshold(_sessionDuration)) {
        _sessionQualified = true;
        recordListening(
          song,
          _sessionListened,
          listenedAt: now,
          incrementPlayCount: true,
          countTotalSeconds: false,
        );
      }
      return;
    }

    recordListening(
      song,
      listenedDuration,
      listenedAt: now,
      countTotalSeconds: false,
    );
  }

  void handlePlayerStateForListeningStats(
    PlayerState state, {
    Map? currentSong,
  }) {
    if (state.playing == _sessionLastAudioPlayerPlaying) return;

    if (state.playing) {
      resumeListeningSession(currentSong: currentSong);
    } else {
      recordListeningSessionProgress(
        wasPlaying: _sessionLastAudioPlayerPlaying,
      );
    }

    _sessionLastAudioPlayerPlaying = state.playing;
  }

  void finishListeningSession({
    bool countCurrentTick = false,
    bool flushStats = true,
    bool? wasPlaying,
  }) {
    if (_sessionSong == null) return;

    if (countCurrentTick) {
      recordListeningSessionProgress(wasPlaying: wasPlaying);
    }

    _sessionSong = null;
    _sessionSongId = null;
    _sessionDuration = null;
    _sessionListened = Duration.zero;
    _sessionLastTick = null;
    _sessionQualified = false;
    _sessionLastAudioPlayerPlaying = false;
    if (flushStats) {
      unawaited(
        flush().catchError((error, stackTrace) {
          logger.log(
            'Error flushing listening stats',
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    }
  }

  static final RegExp _youtubeIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  static const _radioStatsPurgedKey = 'radioStreamStatsPurged';

  bool _looksLikeNonYoutubeEntry(Map<String, dynamic> song) {
    final ytid = song['ytid']?.toString() ?? '';
    return !_youtubeIdPattern.hasMatch(ytid);
  }

  int _readSeconds(dynamic seconds) {
    if (seconds is int) return seconds;
    if (seconds is num) return seconds.toInt();
    return int.tryParse(seconds?.toString() ?? '') ?? 0;
  }

  /// Removes legacy radio-stream entries from already-persisted Wrapped
  /// stats. Safe to call on every app startup: it only does real work, and
  /// only writes to disk, the first time (guarded via Hive), and is a no-op
  /// once the stats are clean.
  Future<void> purgeLegacyRadioStreamStats() async {
    try {
      final settingsBox = Hive.box('settings');
      if (settingsBox.get(_radioStatsPurgedKey) == true) return;

      final stats = Map<String, dynamic>.from(_readStats());
      var changedAnyMonth = false;

      Map<String, dynamic> cleanMonth(dynamic monthValue) {
        final month = Map<String, dynamic>.from(_asMap(monthValue) ?? {});
        final songs = Map<String, dynamic>.from(_asMap(month['songs']) ?? {});

        final strayKeys = <String>[];
        var removedSeconds = 0;
        for (final entry in songs.entries) {
          final song = _asMap(entry.value);
          if (song == null) continue;
          if (_looksLikeNonYoutubeEntry(song)) {
            strayKeys.add(entry.key);
            removedSeconds += _readSeconds(song['seconds']);
          }
        }

        if (strayKeys.isEmpty) return month;

        changedAnyMonth = true;
        for (final key in strayKeys) {
          songs.remove(key);
        }
        month['songs'] = songs;

        // totalSeconds tracks all listening time, including the radio time
        // attributed to the entries just removed above, so correct it too.
        final currentTotal = _readSeconds(month['totalSeconds']);
        final newTotal = currentTotal - removedSeconds;
        month['totalSeconds'] = newTotal > 0 ? newTotal : 0;

        return month;
      }

      stats['currentMonth'] = cleanMonth(stats['currentMonth']);

      final history = _asMap(stats['history']) ?? const <String, dynamic>{};
      final newHistory = <String, dynamic>{};
      for (final entry in history.entries) {
        newHistory[entry.key] = cleanMonth(entry.value);
      }
      stats['history'] = newHistory;

      if (changedAnyMonth) {
        _stats = stats;
        _markDirty();
        await flush();
      }

      await settingsBox.put(_radioStatsPurgedKey, true);
    } catch (e, stackTrace) {
      logger.log(
        'Error purging legacy radio stream stats',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void startListeningSessionIfNeeded({
    Map? currentSong,
    bool isPlaying = false,
  }) {
    if (!wrappedEnabled.value || _sessionSong != null || !isPlaying) {
      return;
    }

    final song = currentSong;
    if (song != null) {
      startListeningSession(song);
    }
  }

  Duration? _durationFromSong(Map song) {
    final duration = song['duration'];
    if (duration is Duration) return duration;
    if (duration is int) return Duration(seconds: duration);
    if (duration is num) return Duration(seconds: duration.toInt());

    final text = duration?.toString();
    if (text == null || text.isEmpty) return null;

    final numericSeconds = int.tryParse(text);
    if (numericSeconds != null) return Duration(seconds: numericSeconds);

    final parts = text.split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return null;
    if (parts.length == 2) {
      return Duration(minutes: parts[0]!, seconds: parts[1]!);
    }
    if (parts.length == 3) {
      return Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!);
    }

    return null;
  }

  void reload() {
    _dirty = false;
    _listeningTimeRemainder = Duration.zero;
    _stats = null;
  }

  Future<void> clearStats() async {
    _dirty = false;
    _listeningTimeRemainder = Duration.zero;
    final now = DateTime.now();
    final cleared = createEmptyListeningStats(
      now.year,
      currentMonthKey: listeningStatsMonthKey(now),
    );
    _stats = cleared;
    await deleteData('user', storageKey);
    // Persist the cleared map last so an in-flight checkpoint flush can't
    // resurrect the deleted stats (skipped if a new recording replaced _stats).
    if (identical(_stats, cleared)) {
      await addOrUpdateData('user', storageKey, cleared);
    }
  }

  /// Writes pending stats to disk if anything changed since the last write.
  /// Called at playback checkpoints and when the app is backgrounded/closed.
  Future<void> flush() async {
    await _persist();
  }

  Map<String, dynamic> _readStats([DateTime? now]) {
    final currentDate = now ?? DateTime.now();
    final cached = _stats;
    if (cached != null) {
      final previousMonthKey = cached['currentMonthKey']?.toString();
      _stats = normalizeListeningStats(cached, currentDate);
      if (previousMonthKey != _stats!['currentMonthKey']?.toString()) {
        _markDirty();
      }
      return _stats!;
    }

    final raw = Hive.box('user').get(storageKey);
    _stats = normalizeListeningStats(raw, currentDate);
    if (_shouldPersistNormalizedStats(raw, _stats!)) {
      _markDirty();
    }
    return _stats!;
  }

  void _markDirty() {
    _dirty = true;
  }

  Future<void> _persist() async {
    final stats = _stats;
    if (stats == null || !_dirty) return;
    try {
      await addOrUpdateData('user', storageKey, stats);
      // Clear the dirty flag only if no newer recording replaced _stats while
      // this write was in flight, otherwise those changes would be lost.
      if (identical(_stats, stats)) {
        _dirty = false;
      }
    } catch (e, stackTrace) {
      logger.log(
        'Error persisting listening stats',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
