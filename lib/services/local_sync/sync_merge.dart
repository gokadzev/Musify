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

import 'dart:convert';

import 'package:musify/services/local_sync/sync_data.dart';

const _kindKeys = <String, String>{
  'likedSongs': 'likedSongs',
  'likedSongsOrder': 'likedSongs',
  'likedRadioStations': 'likedRadioStations',
  'likedRadioStationsOrder': 'likedRadioStations',
  'playlists': 'playlists',
  'playlistsOrder': 'playlists',
  'likedPlaylists': 'likedPlaylists',
  'likedPlaylistsOrder': 'likedPlaylists',
  'customPlaylists': 'customPlaylists',
  'playlistSong': 'customPlaylists',
  'playlistSongOrder': 'customPlaylists',
  'playlistLocation': 'customPlaylists',
  'customPlaylistsOrder': 'customPlaylists',
  'folderPlaylistOrder': 'customPlaylists',
  'playlistFolders': 'playlistFolders',
  'playlistFoldersOrder': 'playlistFolders',
  'pinnedPlaylistIds': 'pinnedPlaylistIds',
  'pinnedPlaylistIdsOrder': 'pinnedPlaylistIds',
  'recentlyPlayedSongs': 'recentlyPlayedSongs',
  'searchHistory': 'searchHistory',
  'searchHistoryOrder': 'searchHistory',
  'recapMonth': 'wrappedListeningStats',
  'recapReset': 'wrappedListeningStats',
};

class SyncDocument {
  SyncDocument({Map<String, dynamic>? records, this.clock = 0})
    : records = records ?? {};

  factory SyncDocument.fromMap(Map raw) {
    if (![2, syncSchemaVersion].contains(raw['version']) ||
        raw['records'] is! Map ||
        raw['clock'] is! int ||
        raw['clock'] < 0) {
      throw const FormatException('Unsupported sync document');
    }
    validateSyncJson(raw);
    final records = Map<String, dynamic>.from(raw['records']);
    for (final entry in records.entries) {
      final key = _parts(entry.key);
      final cell = entry.value;
      if (!_kindKeys.containsKey(key[0]) ||
          cell is! Map ||
          cell['clock'] is! int ||
          cell['clock'] < 0 ||
          cell['device'] is! String ||
          cell['device'].length > 128 ||
          cell['deleted'] is! bool) {
        throw const FormatException('Invalid sync record');
      }
      if (cell['epoch'] != null) _validateStamp(cell['epoch']);
      if (_aggregated(key[0])) {
        final migrated = Map<String, dynamic>.from(cell)
          ..putIfAbsent('generation', () => _generation(cell));
        _validateStamp(migrated['generation']);
        records[entry.key] = migrated;
      }
      if (cell['deleted'] != true) _validateValue(key, cell['value']);
    }
    return SyncDocument(records: records, clock: raw['clock']);
  }

  int clock;
  final Map<String, dynamic> records;
  Map<String, dynamic> toMap() => {
    'version': syncSchemaVersion,
    'clock': clock,
    'records': records,
  };

  SyncDocument select(Set<SyncCategory> categories) {
    final keys = categories.expand((c) => syncCategoryKeys[c]!).toSet();
    final selected = {
      for (final e in records.entries)
        if (keys.contains(_kindKeys[_parts(e.key)[0]])) e.key: e.value,
    };
    return SyncDocument(
      records: selected,
      clock: selected.values.fold(
        0,
        (int n, cell) => n > cell['clock'] ? n : cell['clock'],
      ),
    );
  }

  // Record observed local edits, including removals; returns whether anything changed.
  bool capture(
    Map<String, dynamic> current,
    Map<String, dynamic>? baseline,
    String device,
  ) {
    if (baseline != null && canonicalSync(current) == canonicalSync(baseline)) {
      return false;
    }
    final now = flatten(current);
    final before = baseline == null ? <String, dynamic>{} : flatten(baseline);
    final resetKey = _key('recapReset', '', '');
    if (baseline == null && records.isEmpty) {
      final reset = now.containsKey(resetKey) ? [++clock, device] : null;
      for (final e in now.entries) {
        records[e.key] = {
          'clock': e.key == resetKey && reset != null ? clock : 0,
          'device': e.key == resetKey && reset != null ? device : '',
          'deleted': false,
          'value': e.value,
          if (_parts(e.key)[0] == 'recapMonth' && reset != null) 'epoch': reset,
          if (_aggregated(_parts(e.key)[0])) 'generation': [0, ''],
        };
      }
      return true;
    }
    final resetChanged = now[resetKey] != before[resetKey];
    final edits =
        {...now.keys, ...before.keys}
            .where(
              (key) =>
                  (resetChanged && _parts(key)[0] == 'recapMonth') ||
                  canonicalSync(now[key]) != canonicalSync(before[key]) ||
                  now.containsKey(key) != before.containsKey(key),
            )
            .toList()
          ..sort();
    if (edits.isEmpty) return false;
    clock++;
    final epoch = resetChanged ? [clock, device] : _epoch(records[resetKey]);
    for (final key in edits) {
      final kind = _parts(key)[0];
      final previous = records[key] as Map?;
      final deleted = !now.containsKey(key);
      records[key] = {
        'clock': clock,
        'device': device,
        'deleted': deleted,
        'value': now[key],
        if (kind == 'recapMonth') 'epoch': epoch,
        if (_aggregated(kind))
          'generation': deleted || previous?['deleted'] == true
              ? [clock, device]
              : _generation(previous),
      };
    }
    return true;
  }

  int join(SyncDocument other) {
    var changes = 0;
    for (final entry in other.records.entries) {
      final local = records[entry.key] as Map?;
      final incoming = entry.value as Map;
      final kind = _parts(entry.key)[0];
      final aggregated = _aggregated(kind);
      // A device stamps each key once per clock tick, so equal stamps are the same write.
      if (local != null &&
          !aggregated &&
          local['clock'] == incoming['clock'] &&
          local['device'] == incoming['device'] &&
          local['deleted'] == incoming['deleted'] &&
          (local['clock'] as int) > 0) {
        continue;
      }
      final winner = local == null
          ? incoming
          : _mergeCell(kind, local, incoming);
      if (identical(winner, local) ||
          (aggregated && canonicalSync(local) == canonicalSync(winner))) {
        continue;
      }
      records[entry.key] = Map<String, dynamic>.from(winner);
      changes++;
    }
    clock = _max(clock, other.clock);
    for (final cell in records.values) {
      clock = _max(clock, cell['clock'] as int);
    }
    return changes;
  }

  static bool _aggregated(String kind) =>
      kind == 'recapMonth' || kind == 'recentlyPlayedSongs';

  // Deletions and explicit re-adds start a new generation.
  static List<dynamic> _generation(Map? cell) =>
      cell?['generation'] as List? ??
      (cell?['deleted'] == true ? _epoch(cell) : [0, '']);

  static void _validateStamp(dynamic stamp) {
    if (stamp is! List ||
        stamp.length != 2 ||
        stamp[0] is! int ||
        stamp[0] < 0 ||
        stamp[1] is! String ||
        stamp[1].length > 128) {
      throw const FormatException('Invalid sync generation');
    }
  }

  static Map _mergeCell(String kind, Map a, Map b) {
    final newest = _compare(a, b) >= 0 ? a : b;
    if (!_aggregated(kind)) return newest;
    if (kind == 'recapMonth') {
      final epoch = _compareEpoch(a['epoch'], b['epoch']);
      if (epoch != 0) return epoch > 0 ? a : b;
    }
    final generation = _compareEpoch(_generation(a), _generation(b));
    if (generation != 0) return generation > 0 ? a : b;
    if (a['deleted'] == true || b['deleted'] == true) {
      if (a['deleted'] == b['deleted']) return newest;
      return a['deleted'] == true ? a : b;
    }
    if (kind == 'recapMonth') {
      final month = _compareMonth(a['value'], b['value']);
      return month == 0 ? newest : (month > 0 ? a : b);
    }
    final left = Map<String, dynamic>.from(a['value']);
    final right = Map<String, dynamic>.from(b['value']);
    final count = _max(
      _integer(left.remove('listeningCount')),
      _integer(right.remove('listeningCount')),
    );
    final date = _date(left['lastPlayed'])
        .compareTo(_date(right['lastPlayed']));
    final order = date != 0
        ? date
        : canonicalSync(left).compareTo(canonicalSync(right));
    return {
      ...newest,
      'value': {...(order >= 0 ? left : right), 'listeningCount': count},
    };
  }

  Map<String, dynamic> materialize({DateTime? now}) {
    final recapEpoch = _epoch(records[_key('recapReset', '', '')]);
    final live = <String, dynamic>{
      for (final e in records.entries)
        if (e.value['deleted'] != true &&
            (_parts(e.key)[0] != 'recapMonth' ||
                _compareEpoch(e.value['epoch'], recapEpoch) == 0))
          e.key: e.value['value'],
    };
    List<String> ordered(
      String kind,
      Iterable<String> ids, [
      String parent = '',
    ]) {
      final available = ids.toSet();
      final order = (live[_key('${kind}Order', '', parent)] as List? ?? [])
          .cast<String>();
      return [
        ...order.where(available.remove),
        ...(available.toList()..sort()),
      ];
    }

    // Group once by kind and parent to avoid a quadratic scan per playlist.
    final grouped = <String, Map<String, Map<String, dynamic>>>{};
    for (final e in live.entries) {
      final parts = _parts(e.key);
      ((grouped[parts[0]] ??= {})[parts[1]] ??= {})[parts[2]] = e.value;
    }
    Map<String, dynamic> entries(String kind, [String parent = '']) =>
        grouped[kind]?[parent] ?? const {};
    List<dynamic> list(String kind, {bool strings = false}) {
      final items = entries(kind);
      return ordered(
        kind,
        items.keys,
      ).map((id) => strings ? id : items[id]).toList();
    }

    final folders = entries('playlistFolders');
    final playlists = entries('customPlaylists');
    final nested = <String, List<Map>>{for (final id in folders.keys) id: []};
    final top = <String, Map>{};
    for (final e in playlists.entries) {
      final songs = entries('playlistSong', e.key);
      final order = (live[_key('playlistSongOrder', e.key, '')] as List? ?? [])
          .cast<String>();
      final remaining = songs.keys.toSet();
      final ids = [
        ...order.where(remaining.remove),
        ...(remaining.toList()..sort()),
      ];
      final playlist = {
        ...e.value as Map,
        'list': ids.map((id) => songs[id]).toList(),
      };
      final location = live[_key('playlistLocation', '', e.key)];
      if (location is String && nested.containsKey(location)) {
        nested[location]!.add(playlist);
      } else {
        top[e.key] = playlist;
      }
    }
    final folderList = <Map>[];
    for (final id in ordered('playlistFolders', folders.keys)) {
      final members = {
        for (final item in nested[id]!) item['ytid'].toString(): item,
      };
      final order = (live[_key('folderPlaylistOrder', id, '')] as List? ?? [])
          .cast<String>();
      final remaining = members.keys.toSet();
      final ids = [
        ...order.where(remaining.remove),
        ...(remaining.toList()..sort()),
      ];
      folderList.add({
        ...folders[id] as Map,
        'playlists': ids.map((id) => members[id]).toList(),
      });
    }
    final allPlaylistIds = {
      ...playlists.keys,
      ...entries('playlists').keys,
      ...entries('likedPlaylists').keys,
    };
    final pins = list(
      'pinnedPlaylistIds',
      strings: true,
    ).cast<String>().where(allPlaylistIds.contains).take(5).toList();
    final recent = entries('recentlyPlayedSongs').values.toList()
      ..sort((a, b) {
        final date = _date(b['lastPlayed']).compareTo(_date(a['lastPlayed']));
        return date != 0
            ? date
            : a['ytid'].toString().compareTo(b['ytid'].toString());
      });
    final date = now ?? DateTime.now();
    final month = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final recap = entries('recapMonth');
    return {
      'wrappedListeningStats': {
        'schemaVersion': 2,
        if (live.containsKey(_key('recapReset', '', '')))
          'syncResetId': live[_key('recapReset', '', '')],
        'year': date.year,
        'currentMonthKey': month,
        'currentMonth':
            recap[month] ?? {'totalSeconds': 0, 'songs': <String, dynamic>{}},
        'history': {
          for (final e in recap.entries)
            if (e.key != month) e.key: e.value,
        },
      },
      'likedSongs': list('likedSongs'),
      'likedRadioStations': list('likedRadioStations', strings: true),
      'playlists': list('playlists', strings: true),
      'likedPlaylists': list('likedPlaylists'),
      'customPlaylists': ordered(
        'customPlaylists',
        top.keys,
      ).map((id) => top[id]).toList(),
      'playlistFolders': folderList,
      'pinnedPlaylistIds': pins,
      'recentlyPlayedSongs': recent.take(100).toList(),
      'searchHistory': list('searchHistory', strings: true),
    };
  }

  static Map<String, dynamic> flatten(Map<String, dynamic> library) {
    final result = <String, dynamic>{};
    void mapList(
      String kind,
      Object? raw, {
      String parent = '',
      bool strings = false,
      bool order = true,
    }) {
      if (raw == null) return;
      if (raw is! List) throw FormatException('Invalid $kind list');
      final ids = <String>[];
      for (final item in raw) {
        final id = strings
            ? item.toString()
            : item is Map
            ? item['ytid']?.toString()
            : null;
        if (id == null || id.isEmpty) throw FormatException('Missing $kind id');
        if (ids.contains(id)) continue;
        ids.add(id);
        result[_key(kind, parent, id)] = strings
            ? true
            : _portableMap(item as Map);
      }
      if (order) result[_key('${kind}Order', '', parent)] = ids;
    }

    mapList('likedSongs', library['likedSongs']);
    mapList('likedRadioStations', library['likedRadioStations'], strings: true);
    mapList('playlists', library['playlists'], strings: true);
    mapList('likedPlaylists', library['likedPlaylists']);
    mapList('pinnedPlaylistIds', library['pinnedPlaylistIds'], strings: true);
    mapList(
      'recentlyPlayedSongs',
      library['recentlyPlayedSongs'],
      order: false,
    );
    mapList('searchHistory', library['searchHistory'], strings: true);
    void playlist(Map item, String? folder) {
      final id = item['ytid']?.toString();
      if (id == null || id.isEmpty || item['list'] is! List) {
        throw const FormatException('Invalid custom playlist');
      }
      final metadata = _portableMap(item)..remove('list');
      result[_key('customPlaylists', '', id)] = metadata;
      result[_key('playlistLocation', '', id)] = folder;
      final ids = <String>[];
      for (final song in item['list']) {
        if (song is! Map || song['ytid'] == null) {
          throw const FormatException('Invalid playlist song');
        }
        final songId = song['ytid'].toString();
        if (!ids.contains(songId)) ids.add(songId);
        result[_key('playlistSong', id, songId)] = _portableMap(song);
      }
      result[_key('playlistSongOrder', id, '')] = ids;
    }

    final top = library['customPlaylists'] ?? [];
    final folders = library['playlistFolders'] ?? [];
    if (top is! List || folders is! List) {
      throw const FormatException('Invalid playlists');
    }
    for (final item in top) {
      if (item is! Map) throw const FormatException('Invalid playlist');
      playlist(item, null);
    }
    result[_key('customPlaylistsOrder', '', '')] = top
        .map((e) => e['ytid'].toString())
        .toList();
    for (final item in folders) {
      if (item is! Map || item['id'] is! String || item['playlists'] is! List) {
        throw const FormatException('Invalid folder');
      }
      final id = item['id'] as String;
      result[_key('playlistFolders', '', id)] = _portableMap(item)
        ..remove('playlists');
      for (final nested in item['playlists']) {
        playlist(nested as Map, id);
      }
      result[_key('folderPlaylistOrder', id, '')] = (item['playlists'] as List)
          .map((e) => e['ytid'].toString())
          .toList();
    }
    result[_key('playlistFoldersOrder', '', '')] = folders
        .map((e) => e['id'].toString())
        .toList();
    final recap = library['wrappedListeningStats'];
    if (recap != null) {
      if (recap is! Map ||
          recap['schemaVersion'] != 2 ||
          recap['history'] is! Map ||
          recap['currentMonth'] is! Map ||
          recap['currentMonthKey'] is! String) {
        throw const FormatException('Invalid listening recap');
      }
      if (recap['syncResetId'] is String) {
        result[_key('recapReset', '', '')] = recap['syncResetId'];
      }
      final months = {
        ...recap['history'] as Map,
        recap['currentMonthKey']: recap['currentMonth'],
      };
      for (final e in months.entries) {
        _validateMonth(e.key.toString(), e.value);
        result[_key('recapMonth', '', e.key.toString())] = _portableMap(
          e.value as Map,
        );
      }
    }
    return result;
  }

  static int _compareMonth(Map a, Map b) {
    final seconds = _integer(a['totalSeconds'])
        .compareTo(_integer(b['totalSeconds']));
    if (seconds != 0) return seconds;
    int plays(Map month) => (month['songs'] as Map).values.fold(
      0,
      (int n, song) => n + _integer(song['playCount']),
    );
    final count = plays(a).compareTo(plays(b));
    return count != 0 ? count : canonicalSync(a).compareTo(canonicalSync(b));
  }

  static void _validateMonth(String key, Object? value) {
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(key) ||
        value is! Map ||
        value['totalSeconds'] is! num ||
        value['totalSeconds'] < 0 ||
        value['songs'] is! Map) {
      throw const FormatException('Invalid recap month');
    }
    for (final song in value['songs'].values) {
      if (song is! Map ||
          song['playCount'] is! num ||
          song['playCount'] < 0 ||
          song['seconds'] is! num ||
          song['seconds'] < 0) {
        throw const FormatException('Invalid recap song');
      }
    }
  }

  static Map<String, dynamic> _portableMap(Map raw) {
    final map = Map<String, dynamic>.from(encodeSyncValue(raw) as Map);
    for (final key in [
      'audioPath',
      'filePath',
      'downloadPath',
      'localPath',
      'path',
    ]) {
      map.remove(key);
    }
    return map;
  }

  static void _validateValue(List<String> parts, Object? value) {
    final kind = parts[0];
    if (parts[1].length > 1024 || parts[2].length > 1024) {
      throw const FormatException('Invalid record id');
    }
    if (kind.endsWith('Order')) {
      if (value is! List || value.any((e) => e is! String)) {
        throw const FormatException('Invalid order');
      }
    } else if (kind == 'recapMonth') {
      _validateMonth(parts[2], value);
    } else if (kind == 'recapReset') {
      if (value is! String || value.isEmpty || value.length > 128) {
        throw const FormatException('Invalid recap reset');
      }
    } else if (kind == 'playlistLocation') {
      if (value != null && value is! String) {
        throw const FormatException('Invalid folder reference');
      }
    } else if ([
      'playlists',
      'pinnedPlaylistIds',
      'likedRadioStations',
      'searchHistory',
    ].contains(kind)) {
      if (value != true) throw const FormatException('Invalid membership');
    } else {
      if (value is! Map) throw const FormatException('Invalid library item');
      final idKey = kind == 'playlistFolders' ? 'id' : 'ytid';
      if (value[idKey]?.toString() != parts[2]) {
        throw const FormatException('Invalid item identity');
      }
      if ((kind == 'customPlaylists' && value.containsKey('list')) ||
          (kind == 'playlistFolders' && value.containsKey('playlists'))) {
        throw const FormatException('Nested metadata');
      }
    }
  }

  static List<dynamic> _epoch(dynamic cell) =>
      cell is Map ? [cell['clock'], cell['device']] : [0, ''];

  static int _compareEpoch(dynamic a, dynamic b) {
    final left = a is List ? a : [0, ''];
    final right = b is List ? b : [0, ''];
    final clock = (left[0] as int).compareTo(right[0] as int);
    return clock != 0
        ? clock
        : (left[1] as String).compareTo(right[1] as String);
  }

  static int _compare(Map a, Map b) {
    final clock = (a['clock'] as int).compareTo(b['clock'] as int);
    if (clock != 0) return clock;
    final device = (a['device'] as String).compareTo(b['device'] as String);
    if (device != 0) return device;
    if (a['deleted'] != b['deleted']) return a['deleted'] == true ? 1 : -1;
    return canonicalSync(a['value']).compareTo(canonicalSync(b['value']));
  }

  static String _key(String kind, String parent, String id) =>
      jsonEncode([kind, parent, id]);
  static List<String> _parts(String raw) {
    final value = jsonDecode(raw);
    if (value is! List || value.length != 3 || value.any((e) => e is! String)) {
      throw const FormatException('Invalid record key');
    }
    return value.cast<String>();
  }

  static int _integer(Object? value) => value is num ? value.toInt() : 0;
  static int _max(int a, int b) => a > b ? a : b;
  static String _date(Object? value) =>
      value is Map ? value['value']?.toString() ?? '' : value?.toString() ?? '';
}
