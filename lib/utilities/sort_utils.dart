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

/// Returns a new list sorted by [sortKey] (case-insensitive).
/// Stable: ties keep their input order (List.sort alone is not stable).
List<dynamic> sortSongsByKey(List<dynamic> songs, String sortKey) {
  String keyOf(dynamic song) =>
      (song is Map ? song[sortKey] ?? '' : '').toString().toLowerCase();

  final indexed =
      [for (var i = 0; i < songs.length; i++) (index: i, key: keyOf(songs[i]))]
        ..sort((a, b) {
          final byKey = a.key.compareTo(b.key);
          return byKey != 0 ? byKey : a.index.compareTo(b.index);
        });
  return [for (final entry in indexed) songs[entry.index]];
}

/// Returns a new list with the most recently appended songs first.
List<dynamic> sortSongsNewestFirst(List<dynamic> songs) =>
    List<dynamic>.of(songs.reversed);
