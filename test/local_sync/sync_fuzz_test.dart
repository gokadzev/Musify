import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_merge.dart';

import 'fixtures.dart';

/// One simulated installation with its library, document and baseline.
class _Device {
  _Device(this.id);

  final String id;
  Map<String, dynamic> library = {};
  final SyncDocument doc = SyncDocument();
  Map<String, dynamic>? baseline;

  Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(decodeSyncValue(encodeSyncValue(value)) as Map);

  // Same sequence as LibraryMergeService.exportLibrary.
  SyncDocument export() {
    doc.capture(library, baseline, id);
    baseline = _copy(library);
    return copyDocument(doc);
  }

  // Same sequence as LibraryMergeService.mergeLibrary.
  void merge(SyncDocument remote) {
    doc.capture(library, baseline, id);
    doc.join(remote);
    final merged = doc.materialize();
    final keys = SyncCategory.values.expand((c) => syncCategoryKeys[c]!);
    final next = _copy(library);
    for (final key in keys) {
      if (canonicalSync(library[key]) != canonicalSync(merged[key])) {
        next[key] = merged[key];
      }
    }
    library = next;
    baseline = _copy(library);
  }

  String get fingerprint => canonicalSync({
    for (final key in SyncCategory.values.expand((c) => syncCategoryKeys[c]!))
      // A missing recap and an empty one are the same to the user.
      if (key != 'wrappedListeningStats') key: library[key] ?? [],
  });
}

/// Random user edits that respect the app's invariants.
class _Editor {
  _Editor(this.random);

  final Random random;
  var _counter = 0;
  final Set<String> removedSongs = {};
  final Set<String> addedSongs = {};

  String _id(String prefix) => '$prefix${random.nextInt(14)}';

  List<Map> _list(_Device d, String key) =>
      List<Map>.from((d.library[key] as List?) ?? []);

  List<Map> _allPlaylists(_Device d) => [
    ..._list(d, 'customPlaylists'),
    for (final folder in _list(d, 'playlistFolders'))
      ...(folder['playlists'] as List).cast<Map>(),
  ];

  void _replacePlaylist(_Device d, String id, Map? Function(Map) edit) {
    List<Map> apply(List<Map> items) => [
      for (final item in items)
        if (item['ytid'] == id) ...[edit(item)].whereType<Map>() else item,
    ];
    d.library['customPlaylists'] = apply(_list(d, 'customPlaylists'));
    d.library['playlistFolders'] = [
      for (final folder in _list(d, 'playlistFolders'))
        {
          ...folder,
          'playlists': apply((folder['playlists'] as List).cast<Map>()),
        },
    ];
  }

  void edit(_Device d) {
    switch (random.nextInt(16)) {
      case 0 || 1:
        final id = _id('s');
        final likes = _list(d, 'likedSongs');
        if (likes.any((e) => e['ytid'] == id)) return;
        d.library['likedSongs'] = [...likes, song(id, '${d.id}-${_counter++}')];
        addedSongs.add(id);
      case 2:
        final likes = _list(d, 'likedSongs');
        if (likes.isEmpty) return;
        final gone = likes[random.nextInt(likes.length)];
        removedSongs.add(gone['ytid'] as String);
        d.library['likedSongs'] = likes.where((e) => e != gone).toList();
      case 3:
        final id = _id('p');
        if (_allPlaylists(d).any((e) => e['ytid'] == id)) return;
        d.library['customPlaylists'] = [
          ..._list(d, 'customPlaylists'),
          playlist(
            id,
            {for (var i = 0; i < random.nextInt(4); i++) _id('t')}.toList(),
            title: '${d.id}-${_counter++}',
          ),
        ];
      case 4:
        final all = _allPlaylists(d);
        if (all.isEmpty) return;
        final id = all[random.nextInt(all.length)]['ytid'];
        _replacePlaylist(d, id as String, (_) => null);
        d.library['pinnedPlaylistIds'] = _strings(
          d,
          'pinnedPlaylistIds',
        ).where((e) => e != id).toList();
      case 5:
        final all = _allPlaylists(d);
        if (all.isEmpty) return;
        final id = all[random.nextInt(all.length)]['ytid'] as String;
        _replacePlaylist(
          d,
          id,
          (p) => {...p, 'title': '${d.id}-${_counter++}'},
        );
      case 6:
        final all = _allPlaylists(d);
        if (all.isEmpty) return;
        final id = all[random.nextInt(all.length)]['ytid'] as String;
        final track = _id('t');
        _replacePlaylist(d, id, (p) {
          final tracks = (p['list'] as List).cast<Map>();
          if (tracks.any((e) => e['ytid'] == track)) {
            return {
              ...p,
              'list': tracks.where((e) => e['ytid'] != track).toList(),
            };
          }
          return {
            ...p,
            'list': [...tracks, song(track)],
          };
        });
      case 7:
        final all = _allPlaylists(d);
        if (all.isEmpty) return;
        final id = all[random.nextInt(all.length)]['ytid'] as String;
        _replacePlaylist(d, id, (p) {
          final tracks = (p['list'] as List).cast<Map>().toList()
            ..shuffle(random);
          return {...p, 'list': tracks};
        });
      case 8:
        final all = _allPlaylists(d);
        if (all.isEmpty) return;
        final id = all[random.nextInt(all.length)]['ytid'] as String;
        final pins = _strings(d, 'pinnedPlaylistIds');
        if (pins.contains(id)) {
          d.library['pinnedPlaylistIds'] = pins.where((e) => e != id).toList();
        } else if (pins.length < 5) {
          d.library['pinnedPlaylistIds'] = [...pins, id];
        }
      case 9:
        final term = 'q${random.nextInt(8)}';
        final terms = _strings(d, 'searchHistory');
        d.library['searchHistory'] = terms.contains(term)
            ? terms.where((e) => e != term).toList()
            : [term, ...terms];
      case 10:
        final id = _id('r');
        final stations = _strings(d, 'likedRadioStations');
        d.library['likedRadioStations'] = stations.contains(id)
            ? stations.where((e) => e != id).toList()
            : [...stations, id];
      case 11:
        final id = _id('f');
        final folders = _list(d, 'playlistFolders');
        if (folders.any((e) => e['id'] == id)) return;
        d.library['playlistFolders'] = [
          ...folders,
          {'id': id, 'name': '${d.id}-${_counter++}', 'playlists': <Map>[]},
        ];
      case 12:
        final folders = _list(d, 'playlistFolders');
        final top = _list(d, 'customPlaylists');
        if (folders.isEmpty || top.isEmpty) return;
        final folder = folders[random.nextInt(folders.length)];
        final moved = top[random.nextInt(top.length)];
        d.library['customPlaylists'] = top.where((e) => e != moved).toList();
        d.library['playlistFolders'] = [
          for (final f in folders)
            if (f['id'] == folder['id'])
              {
                ...f,
                'playlists': [...(f['playlists'] as List), moved],
              }
            else
              f,
        ];
      case 13:
        final folders = _list(d, 'playlistFolders');
        if (folders.isEmpty) return;
        final gone = folders[random.nextInt(folders.length)];
        final dropped = (gone['playlists'] as List).cast<Map>();
        d.library['playlistFolders'] = folders.where((e) => e != gone).toList();
        d.library['pinnedPlaylistIds'] = _strings(
          d,
          'pinnedPlaylistIds',
        ).where((e) => !dropped.any((p) => p['ytid'] == e)).toList();
      case 14:
        final id = _id('s');
        final recent = _list(d, 'recentlyPlayedSongs');
        final count = 1 + random.nextInt(9);
        d.library['recentlyPlayedSongs'] = [
          {
            ...song(id, '${d.id}-${_counter++}'),
            'lastPlayed': DateTime.utc(
              2026,
              1,
              1 + _counter % 28,
              12,
              _counter % 60,
            ).toIso8601String(),
            'listeningCount': count,
          },
          ...recent.where((e) => e['ytid'] != id),
        ];
      case 15:
        final recent = _list(d, 'recentlyPlayedSongs');
        if (recent.isEmpty) return;
        d.library['recentlyPlayedSongs'] = recent
          ..removeAt(random.nextInt(recent.length));
    }
  }

  List<String> _strings(_Device d, String key) =>
      List<String>.from((d.library[key] as List?) ?? []);
}

void main() {
  test('random edits on four devices always converge and then go quiet', () {
    for (var seed = 0; seed < 300; seed++) {
      final random = Random(seed);
      final editor = _Editor(random);
      final devices = [
        for (final id in ['a', 'b', 'c', 'd']) _Device(id),
      ];

      void sync(_Device x, _Device y) {
        y.merge(x.export());
        x.merge(y.export());
      }

      for (var step = 0; step < 40; step++) {
        final device = devices[random.nextInt(devices.length)];
        for (var i = random.nextInt(4); i >= 0; i--) {
          editor.edit(device);
        }
        if (random.nextInt(3) == 0) {
          final pair = (devices.toList()..shuffle(random)).take(2).toList();
          sync(pair[0], pair[1]);
        }
      }

      var rounds = 0;
      String state() => devices.map((d) => d.fingerprint).join('|');
      String documents() =>
          devices.map((d) => canonicalSync(d.doc.records)).join('|');
      while (true) {
        final before = '${state()}#${documents()}';
        for (final x in devices) {
          for (final y in devices) {
            if (x != y) sync(x, y);
          }
        }
        if ('${state()}#${documents()}' == before) break;
        rounds++;
        expect(
          rounds,
          lessThan(6),
          reason: 'seed $seed keeps producing new edits after sync',
        );
      }

      for (final d in devices.skip(1)) {
        expect(
          d.fingerprint,
          devices.first.fingerprint,
          reason: 'seed $seed: ${d.id} differs from a',
        );
      }
      // An unchanged library must not be re-captured as edits on every sync.
      final settled = devices.map((d) => d.doc.clock).toList();
      for (final x in devices) {
        for (final y in devices) {
          if (x != y) sync(x, y);
        }
      }
      expect(
        devices.map((d) => d.doc.clock).toList(),
        settled,
        reason: 'seed $seed: clocks advance without user edits',
      );

      // Songs that were liked and never unliked anywhere must survive.
      final liked = {
        for (final e in (devices.first.library['likedSongs'] as List? ?? []))
          (e as Map)['ytid'],
      };
      for (final id in editor.addedSongs.difference(editor.removedSongs)) {
        expect(liked, contains(id), reason: 'seed $seed lost liked song $id');
      }
    }
  });
}
