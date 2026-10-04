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

import 'dart:math';

Map<String, dynamic> cloneMap(Map source) {
  return Map<String, dynamic>.from(source);
}

List<Map<String, dynamic>> cloneMaps(Iterable<Map> sources) {
  return sources.map(cloneMap).toList();
}

String? songYtid(Map song) {
  final ytid = song['ytid']?.toString();
  return ytid == null || ytid.isEmpty ? null : ytid;
}

Map? findSongByYtid(Iterable<dynamic> songs, String ytid) {
  for (final song in songs) {
    if (song is Map && songYtid(song) == ytid) return song;
  }
  return null;
}

List<Map> sampleUniqueSongs(
  Iterable<Iterable<dynamic>> sources,
  int count, {
  Random? random,
}) {
  if (count <= 0) return const [];

  final sampler = random ?? Random();
  final seenYtids = <String>{};
  final reservoir = <Map>[];
  var uniqueSongCount = 0;

  for (final source in sources) {
    for (final song in source) {
      if (song is! Map) continue;
      final ytid = songYtid(song);
      if (ytid == null || !seenYtids.add(ytid)) continue;

      uniqueSongCount++;
      if (reservoir.length < count) {
        reservoir.add(song);
      } else {
        final slot = sampler.nextInt(uniqueSongCount);
        if (slot < count) reservoir[slot] = song;
      }
    }
  }

  reservoir.shuffle(sampler);
  return reservoir;
}
