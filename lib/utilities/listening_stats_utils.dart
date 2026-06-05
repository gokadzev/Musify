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

const wrappedListeningStatsSchemaVersion = 2;
const wrappedCurrentMonthSongsLimit = 250;
const wrappedMonthlyHistorySongsLimit = 15;
const wrappedAnnualSongsLimit = 30;
const wrappedExpandedSongsLimit = wrappedAnnualSongsLimit;
const wrappedShareSongsLimit = 5;
const wrappedAnnualRecapStartDay = 20;

const qualifiedListeningThreshold = Duration(seconds: 30);
const shortSongBoundary = Duration(seconds: 60);

Duration qualifiedPlaybackThreshold(Duration? duration) {
  if (duration == null || duration <= Duration.zero) {
    return qualifiedListeningThreshold;
  }

  if (duration < shortSongBoundary) {
    final halfDuration = Duration(milliseconds: duration.inMilliseconds ~/ 2);
    return halfDuration > Duration.zero
        ? halfDuration
        : const Duration(seconds: 1);
  }

  return qualifiedListeningThreshold;
}

String listeningStatsMonthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

int listeningStatsAnnualYear(DateTime date) =>
    date.month == DateTime.january ? date.year - 1 : date.year;

bool isListeningStatsAnnualWindow(DateTime date) {
  return date.month == DateTime.january ||
      date.month == DateTime.december ||
      (date.month == DateTime.november &&
          date.day >= wrappedAnnualRecapStartDay);
}

Map<String, dynamic> createEmptyListeningStats(
  int year, {
  String? currentMonthKey,
}) {
  final monthKey = currentMonthKey ?? listeningStatsMonthKey(DateTime(year));

  return {
    'schemaVersion': wrappedListeningStatsSchemaVersion,
    'year': _parseMonthKey(monthKey)?.year ?? year,
    'currentMonthKey': monthKey,
    'currentMonth': _createEmptyMonth(),
    'history': <String, dynamic>{},
  };
}

Map<String, dynamic> normalizeListeningStats(dynamic raw, DateTime now) {
  final currentMonthKey = listeningStatsMonthKey(now);
  if (raw is! Map) {
    return createEmptyListeningStats(
      now.year,
      currentMonthKey: currentMonthKey,
    );
  }

  final stats = Map<String, dynamic>.from(raw);
  var currentMonthKeyFromStats = _readString(stats['currentMonthKey']);
  if (_parseMonthKey(currentMonthKeyFromStats) == null) {
    currentMonthKeyFromStats = currentMonthKey;
  }

  var currentMonth = _normalizeMonth(stats['currentMonth']);
  var currentMonthFromHistory = _createEmptyMonth();
  final history = <String, dynamic>{};

  void absorbStoredMonth(String monthKey, dynamic value) {
    final parsedKey = _parseMonthKey(monthKey);
    if (parsedKey == null) return;

    final month = _normalizeMonth(value);
    if (!_hasMonthStats(month)) return;

    if (monthKey == currentMonthKey) {
      currentMonthFromHistory = _mergeMonthStats(
        currentMonthFromHistory,
        month,
        songLimit: wrappedCurrentMonthSongsLimit,
      );
      return;
    }

    _storeHistoryMonth(history, monthKey, month);
  }

  _normalizeMonths(stats['history']).forEach(absorbStoredMonth);
  _normalizeMonths(stats['months']).forEach(absorbStoredMonth);

  if (currentMonthKeyFromStats != currentMonthKey) {
    _storeHistoryMonth(history, currentMonthKeyFromStats, currentMonth);
    currentMonthKeyFromStats = currentMonthKey;
    currentMonth = _createEmptyMonth();
  }

  currentMonth = _mergeMonthStats(
    currentMonth,
    currentMonthFromHistory,
    songLimit: wrappedCurrentMonthSongsLimit,
  );

  final normalized = {
    'schemaVersion': wrappedListeningStatsSchemaVersion,
    'year': now.year,
    'currentMonthKey': currentMonthKeyFromStats,
    'currentMonth': _trimmedMonth(
      currentMonth,
      songLimit: wrappedCurrentMonthSongsLimit,
    ),
    'history': _retainedHistory(history, now),
  };

  return normalized;
}

Map<String, dynamic> applyListeningTimeDelta(
  Map<String, dynamic> source, {
  required Duration listenedDuration,
  required DateTime listenedAt,
}) {
  final seconds = listenedDuration.inSeconds;
  final stats = normalizeListeningStats(source, listenedAt);
  if (seconds <= 0) return stats;

  final monthStats = _monthStatsForDelta(stats, listenedAt);
  monthStats['totalSeconds'] = _readInt(monthStats['totalSeconds']) + seconds;

  return _storeDeltaMonth(stats, listenedAt, monthStats);
}

Map<String, dynamic> applyListeningStatsDelta(
  Map<String, dynamic> source, {
  required Map song,
  required Duration listenedDuration,
  required DateTime listenedAt,
  required bool incrementPlayCount,
  bool countTotalSeconds = true,
}) {
  final seconds = listenedDuration.inSeconds;
  final stats = countTotalSeconds
      ? applyListeningTimeDelta(
          source,
          listenedDuration: listenedDuration,
          listenedAt: listenedAt,
        )
      : normalizeListeningStats(source, listenedAt);

  if (seconds <= 0 && !incrementPlayCount) return stats;

  final ytid = song['ytid']?.toString();
  if (ytid == null || ytid.isEmpty) return stats;

  final monthStats = _monthStatsForDelta(stats, listenedAt);
  _upsertSongStats(
    monthStats['songs'] as Map<String, dynamic>,
    song,
    seconds,
    listenedAt,
    incrementPlayCount: incrementPlayCount,
  );

  return _storeDeltaMonth(stats, listenedAt, monthStats);
}

Map<String, dynamic> _monthStatsForDelta(
  Map<String, dynamic> stats,
  DateTime listenedAt,
) {
  final currentMonthKey = stats['currentMonthKey']?.toString();
  final listenedMonthKey = listeningStatsMonthKey(listenedAt);
  final writesToCurrentMonth = currentMonthKey == listenedMonthKey;
  return writesToCurrentMonth
      ? _normalizeMonth(stats['currentMonth'])
      : _normalizeMonth(_normalizeMap(stats['history'])[listenedMonthKey]);
}

Map<String, dynamic> _storeDeltaMonth(
  Map<String, dynamic> stats,
  DateTime listenedAt,
  Map<String, dynamic> monthStats,
) {
  final currentMonthKey = stats['currentMonthKey']?.toString();
  final listenedMonthKey = listeningStatsMonthKey(listenedAt);
  final writesToCurrentMonth = currentMonthKey == listenedMonthKey;
  final songLimit = writesToCurrentMonth
      ? wrappedCurrentMonthSongsLimit
      : wrappedMonthlyHistorySongsLimit;
  final trimmedMonth = _trimmedMonth(monthStats, songLimit: songLimit);

  if (writesToCurrentMonth) {
    stats['currentMonth'] = trimmedMonth;
  } else {
    final history = _normalizeMap(stats['history']);
    history[listenedMonthKey] = _trimmedMonth(
      trimmedMonth,
      songLimit: wrappedMonthlyHistorySongsLimit,
    );
    stats['history'] = _retainedHistory(history, listenedAt);
  }

  return stats;
}

List<Map<String, dynamic>> annualListeningSongsFromMonths(
  Map<String, dynamic> months, {
  int limit = wrappedExpandedSongsLimit,
}) {
  final songs = <String, dynamic>{};

  for (final month in months.values) {
    final monthSongs = _normalizeMap(_normalizeMonth(month)['songs']);
    for (final entry in monthSongs.entries) {
      final ytid = entry.key;
      final source = _normalizeMap(entry.value);
      final existing = _normalizeMap(songs[ytid]);
      if (existing.isEmpty) {
        songs[ytid] = Map<String, dynamic>.from(source);
        continue;
      }

      existing['seconds'] =
          _readInt(existing['seconds']) + _readInt(source['seconds']);
      existing['playCount'] =
          _readInt(existing['playCount']) + _readInt(source['playCount']);
      existing['listeningCount'] = existing['playCount'];
      if (_readDate(
        source['lastPlayed'],
      ).isAfter(_readDate(existing['lastPlayed']))) {
        _copyLatestSongMetadata(existing, source);
      }
      songs[ytid] = existing;
    }
  }

  return sortedListeningSongs(songs, limit: limit);
}

Map<String, dynamic> annualListeningMonthsFromStats(
  Map<String, dynamic> source,
  DateTime now,
) {
  final stats = normalizeListeningStats(source, now);
  final recapYear = listeningStatsAnnualYear(now);
  final months = <String, dynamic>{};

  final history = _normalizeMap(stats['history']);
  for (final entry in history.entries) {
    final parsed = _parseMonthKey(entry.key);
    if (parsed?.year != recapYear) continue;
    final month = _normalizeMonth(entry.value);
    if (_hasMonthStats(month)) months[entry.key] = month;
  }

  final currentMonthKey = stats['currentMonthKey']?.toString() ?? '';
  final currentMonthDate = _parseMonthKey(currentMonthKey);
  if (currentMonthDate?.year == recapYear) {
    final currentMonth = _normalizeMonth(stats['currentMonth']);
    if (_hasMonthStats(currentMonth)) {
      months[currentMonthKey] = currentMonth;
    }
  }

  return months;
}

int annualTotalSecondsFromStats(Map<String, dynamic> source, DateTime now) {
  final months = annualListeningMonthsFromStats(source, now);
  return months.values.fold<int>(
    0,
    (total, month) => total + monthTotalSeconds(_asMap(month)),
  );
}

bool hasDisplayableAnnualListeningStats(
  Map<String, dynamic> source,
  DateTime now,
) {
  final months = annualListeningMonthsFromStats(source, now);
  final totalSeconds = months.values.fold<int>(
    0,
    (total, month) => total + monthTotalSeconds(_asMap(month)),
  );
  if (totalSeconds >= Duration.secondsPerMinute) return true;

  return annualListeningSongsFromMonths(months, limit: 1).isNotEmpty;
}

List<String> visibleListeningStatsMonthKeys(
  Map<String, dynamic> source,
  DateTime now,
) {
  final stats = normalizeListeningStats(source, now);
  final keys = <String>[];
  final currentMonthKey = stats['currentMonthKey']?.toString() ?? '';
  final currentMonth = _normalizeMonth(stats['currentMonth']);
  if (hasDisplayableListeningStats(currentMonth)) keys.add(currentMonthKey);

  final history = _normalizeMap(stats['history']);
  for (final entry in history.entries) {
    if (!_isHistoryMonthVisible(entry.key, now)) continue;
    final month = _normalizeMonth(entry.value);
    if (hasDisplayableListeningStats(month)) keys.add(entry.key);
  }

  return keys..sort((a, b) => b.compareTo(a));
}

List<Map<String, dynamic>> sortedListeningSongs(
  Map<String, dynamic>? songs, {
  int limit = wrappedExpandedSongsLimit,
}) {
  if (songs == null || songs.isEmpty) return const [];

  final values =
      songs.values.whereType<Map>().map(Map<String, dynamic>.from).toList()
        ..sort(_compareSongStats);

  return values.take(limit).toList();
}

int monthTotalSeconds(Map<String, dynamic>? monthStats) {
  if (monthStats == null) return 0;
  return _readInt(monthStats['totalSeconds']);
}

bool hasDisplayableListeningStats(Map<String, dynamic>? monthStats) {
  final month = _normalizeMonth(monthStats);
  return monthTotalSeconds(month) >= Duration.secondsPerMinute ||
      _hasQualifiedSongStats(month);
}

int listeningStatsDisplayMinutes(
  int seconds, {
  bool hasQualifiedSongs = false,
}) {
  if (seconds < Duration.secondsPerMinute) {
    return hasQualifiedSongs ? 1 : 0;
  }

  return seconds ~/ Duration.secondsPerMinute;
}

int monthDisplayMinutes(Map<String, dynamic>? monthStats) {
  final month = _normalizeMonth(monthStats);
  return listeningStatsDisplayMinutes(
    monthTotalSeconds(month),
    hasQualifiedSongs: _hasQualifiedSongStats(month),
  );
}

Map<String, dynamic> _createEmptyMonth() => {
  'totalSeconds': 0,
  'songs': <String, dynamic>{},
};

Map<String, dynamic> _normalizeMonths(dynamic raw) {
  final months = _normalizeMap(raw);
  return months.map((key, value) => MapEntry(key, _normalizeMonth(value)));
}

Map<String, dynamic> _normalizeMonth(dynamic raw) {
  final month = _normalizeMap(raw);
  return {
    'totalSeconds': _readInt(month['totalSeconds']),
    'songs': _normalizeMap(month['songs']),
  };
}

Map<String, dynamic> _mergeMonthStats(
  Map<String, dynamic> target,
  Map<String, dynamic> source, {
  required int songLimit,
}) {
  final merged = _normalizeMonth(target);
  final sourceMonth = _normalizeMonth(source);

  merged['totalSeconds'] =
      _readInt(merged['totalSeconds']) + _readInt(sourceMonth['totalSeconds']);

  final mergedSongs = _normalizeMap(merged['songs']);
  final sourceSongs = _normalizeMap(sourceMonth['songs']);
  for (final entry in sourceSongs.entries) {
    final ytid = entry.key;
    final sourceSong = _normalizeMap(entry.value);
    if (sourceSong.isEmpty) continue;

    final existing = _normalizeMap(mergedSongs[ytid]);
    if (existing.isEmpty) {
      mergedSongs[ytid] = Map<String, dynamic>.from(sourceSong);
      continue;
    }

    existing['seconds'] =
        _readInt(existing['seconds']) + _readInt(sourceSong['seconds']);
    existing['playCount'] =
        _readInt(existing['playCount']) + _readInt(sourceSong['playCount']);
    existing['listeningCount'] = existing['playCount'];

    if (_readDate(
      sourceSong['lastPlayed'],
    ).isAfter(_readDate(existing['lastPlayed']))) {
      _copyLatestSongMetadata(existing, sourceSong);
    }

    mergedSongs[ytid] = existing;
  }

  merged['songs'] = mergedSongs;
  return _trimmedMonth(merged, songLimit: songLimit);
}

Map<String, dynamic> _normalizeMap(dynamic raw) {
  if (raw is! Map) return <String, dynamic>{};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

void _upsertSongStats(
  Map<String, dynamic> songs,
  Map song,
  int seconds,
  DateTime listenedAt, {
  required bool incrementPlayCount,
}) {
  final ytid = song['ytid']?.toString();
  if (ytid == null || ytid.isEmpty) return;

  final entry = _normalizeMap(songs[ytid]);
  entry
    ..['ytid'] = ytid
    ..['title'] = _readString(song['title'], fallback: entry['title'])
    ..['artist'] = _readString(song['artist'], fallback: entry['artist'])
    ..['image'] = _readString(song['image'], fallback: entry['image'])
    ..['lowResImage'] = _readString(
      song['lowResImage'],
      fallback: entry['lowResImage'],
    )
    ..['highResImage'] = _readString(
      song['highResImage'],
      fallback: entry['highResImage'],
    )
    ..['artworkPath'] = _readString(
      song['artworkPath'],
      fallback: entry['artworkPath'],
    )
    ..['artWorkPath'] = _readString(
      song['artWorkPath'],
      fallback: entry['artWorkPath'],
    )
    ..['seconds'] = _readInt(entry['seconds']) + seconds
    ..['playCount'] =
        _readInt(entry['playCount']) + (incrementPlayCount ? 1 : 0)
    ..['lastPlayed'] = listenedAt.toIso8601String();

  final duration = _readPersistableDuration(
    song['duration'] ?? entry['duration'],
  );
  if (duration != null) entry['duration'] = duration;

  entry['listeningCount'] = entry['playCount'];
  songs[ytid] = entry;
}

Map<String, dynamic> _trimmedMonth(
  Map<String, dynamic> month, {
  required int songLimit,
}) {
  final normalized = _normalizeMonth(month);
  final songs = _normalizeMap(normalized['songs'])
    ..removeWhere((_, value) {
      final song = _normalizeMap(value);
      return _readInt(song['playCount']) <= 0;
    });
  _trimSongs(songs, songLimit);
  normalized['songs'] = songs;
  return normalized;
}

void _trimSongs(Map<String, dynamic> songs, int limit) {
  if (songs.length <= limit) return;

  final entries = songs.entries.toList()
    ..sort((a, b) {
      final aMap = _normalizeMap(a.value);
      final bMap = _normalizeMap(b.value);
      return _compareSongStats(aMap, bMap);
    });

  songs
    ..clear()
    ..addEntries(entries.take(limit));
}

void _storeHistoryMonth(
  Map<String, dynamic> history,
  String monthKey,
  Map<String, dynamic> month,
) {
  if (_parseMonthKey(monthKey) == null) return;
  if (!_hasMonthStats(month)) return;

  final existing = _normalizeMonth(history[monthKey]);
  history[monthKey] = _mergeMonthStats(
    existing,
    month,
    songLimit: wrappedMonthlyHistorySongsLimit,
  );
}

Map<String, dynamic> _retainedHistory(
  Map<String, dynamic> history,
  DateTime now,
) {
  final retained = <String, dynamic>{};

  for (final entry in history.entries) {
    if (!_shouldRetainHistoryMonth(entry.key, now)) continue;
    final month = _trimmedMonth(
      _normalizeMonth(entry.value),
      songLimit: wrappedMonthlyHistorySongsLimit,
    );
    if (_hasMonthStats(month)) retained[entry.key] = month;
  }

  return retained;
}

bool _shouldRetainHistoryMonth(String monthKey, DateTime now) {
  final parsed = _parseMonthKey(monthKey);
  if (parsed == null) return false;

  if (parsed.year == now.year) return parsed.month < now.month;
  if (now.month == DateTime.january && parsed.year == now.year - 1) {
    return true;
  }

  return false;
}

bool _isHistoryMonthVisible(String monthKey, DateTime now) {
  final parsed = _parseMonthKey(monthKey);
  if (parsed == null) return false;

  if (parsed.year == now.year) return parsed.month < now.month;
  if (now.month == DateTime.january && parsed.year == now.year - 1) {
    return true;
  }

  return false;
}

bool _hasMonthStats(Map<String, dynamic> month) {
  return _readInt(month['totalSeconds']) > 0;
}

bool _hasQualifiedSongStats(Map<String, dynamic> month) {
  final songs = _normalizeMap(month['songs']);
  return songs.values.any((value) {
    final song = _normalizeMap(value);
    return _readInt(song['playCount']) > 0;
  });
}

DateTime? _parseMonthKey(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length != 2) return null;

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return null;
  if (month < DateTime.january || month > DateTime.december) return null;

  return DateTime(year, month);
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

void _copyLatestSongMetadata(
  Map<String, dynamic> target,
  Map<String, dynamic> source,
) {
  target
    ..['title'] = _readString(source['title'], fallback: target['title'])
    ..['artist'] = _readString(source['artist'], fallback: target['artist'])
    ..['image'] = _readString(source['image'], fallback: target['image'])
    ..['lowResImage'] = _readString(
      source['lowResImage'],
      fallback: target['lowResImage'],
    )
    ..['highResImage'] = _readString(
      source['highResImage'],
      fallback: target['highResImage'],
    )
    ..['artworkPath'] = _readString(
      source['artworkPath'],
      fallback: target['artworkPath'],
    )
    ..['artWorkPath'] = _readString(
      source['artWorkPath'],
      fallback: target['artWorkPath'],
    )
    ..['lastPlayed'] = source['lastPlayed'];

  if (source['duration'] != null) target['duration'] = source['duration'];
}

int _compareSongStats(Map<String, dynamic> a, Map<String, dynamic> b) {
  final playComparison = _readInt(
    b['playCount'],
  ).compareTo(_readInt(a['playCount']));
  if (playComparison != 0) return playComparison;

  final secondsComparison = _readInt(
    b['seconds'],
  ).compareTo(_readInt(a['seconds']));
  if (secondsComparison != 0) return secondsComparison;

  return _readDate(b['lastPlayed']).compareTo(_readDate(a['lastPlayed']));
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _readString(dynamic value, {dynamic fallback}) {
  final text = value?.toString();
  if (text != null && text.isNotEmpty) return text;
  return fallback?.toString() ?? '';
}

dynamic _readPersistableDuration(dynamic value) {
  if (value == null) return null;
  if (value is String || value is int || value is double) return value;
  if (value is Duration) return value.inSeconds;
  return value.toString();
}

DateTime _readDate(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
