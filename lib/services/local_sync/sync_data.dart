import 'dart:convert';

import 'package:crypto/crypto.dart';

const maxSyncImageCharacters = 16 * 1024 * 1024;
const maxSyncMessageBytes = 64 * 1024 * 1024;

enum SyncCategory { favourites, playlists, recent, recap, searches, radio }

const syncCategoryKeys = <SyncCategory, List<String>>{
  SyncCategory.favourites: ['likedSongs'],
  SyncCategory.playlists: [
    'playlists',
    'likedPlaylists',
    'customPlaylists',
    'playlistFolders',
    'pinnedPlaylistIds',
  ],
  SyncCategory.recent: ['recentlyPlayedSongs'],
  SyncCategory.recap: ['wrappedListeningStats'],
  SyncCategory.searches: ['searchHistory'],
  SyncCategory.radio: ['likedRadioStations'],
};

Set<SyncCategory> parseSyncCategories(Object? raw) {
  if (raw is! List || raw.any((e) => e is! String))
    throw const FormatException('Invalid sync categories');
  final result = <SyncCategory>{};
  for (final item in raw) {
    final matches = SyncCategory.values.where((e) => e.name == item);
    if (matches.isEmpty)
      throw const FormatException('Unsupported sync category');
    result.add(matches.single);
  }
  return result;
}

Object? encodeSyncValue(Object? value) {
  if (value is DateTime)
    return {
      '__musifyType': 'DateTime',
      'value': value.toUtc().toIso8601String(),
    };
  if (value is Duration) return value.inSeconds;
  if (value is Map)
    return value.map(
      (key, item) => MapEntry(key.toString(), encodeSyncValue(item)),
    );
  if (value is List) return value.map(encodeSyncValue).toList();
  if (value == null || value is String || value is bool || value is num)
    return value;
  return value.toString();
}

Object? decodeSyncValue(Object? value) {
  if (value is Map) {
    if (value['__musifyType'] == 'DateTime') {
      final date = DateTime.tryParse(value['value'].toString());
      if (date == null) throw const FormatException('Invalid date');
      return date.toLocal();
    }
    return value.map(
      (key, item) => MapEntry(key.toString(), decodeSyncValue(item)),
    );
  }
  if (value is List) return value.map(decodeSyncValue).toList();
  return value;
}

String canonicalSync(Object? value) {
  Object? ordered(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((e) => e.toString()).toList()..sort();
      return {for (final key in keys) key: ordered(value[key])};
    }
    if (value is List) return value.map(ordered).toList();
    return value;
  }

  return jsonEncode(ordered(encodeSyncValue(value)));
}

String syncDigest(Object? value) =>
    sha256.convert(utf8.encode(canonicalSync(value))).toString();

void validateSyncJson(Object? value, [int depth = 0]) {
  if (depth > 24) throw const FormatException('Sync data is too deeply nested');
  if (value is String) {
    final limit = value.startsWith('data:image/')
        ? maxSyncImageCharacters
        : 1024 * 1024;
    if (value.length > limit)
      throw const FormatException('Sync string is too large');
  } else if (value is num) {
    if (!value.isFinite) throw const FormatException('Invalid sync number');
  } else if (value is List) {
    if (value.length > 100000)
      throw const FormatException('Too many sync items');
    for (final item in value) {
      validateSyncJson(item, depth + 1);
    }
  } else if (value is Map) {
    if (value.length > 100000 || value.keys.any((e) => e is! String))
      throw const FormatException('Invalid sync object');
    for (final item in value.values) {
      validateSyncJson(item, depth + 1);
    }
  } else if (value != null && value is! bool) {
    throw const FormatException('Invalid sync value');
  }
}
