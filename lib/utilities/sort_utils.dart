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

/// Display order offered for the library lists and for folder contents.
enum LibrarySortType { default_, nameAsc, nameDesc }

/// Returns a new list sorted by [sortKey] (case-insensitive), reversed when
/// [descending]. Stable: ties keep their input order (List.sort alone is not).
List<dynamic> sortByKey(
  List<dynamic> items,
  String sortKey, {
  bool descending = false,
}) {
  String keyOf(dynamic item) =>
      (item is Map ? item[sortKey] ?? '' : '').toString().toLowerCase();

  final indexed =
      [for (var i = 0; i < items.length; i++) (index: i, key: keyOf(items[i]))]
        ..sort((a, b) {
          final byKey = descending
              ? b.key.compareTo(a.key)
              : a.key.compareTo(b.key);
          return byKey != 0 ? byKey : a.index.compareTo(b.index);
        });
  return [for (final entry in indexed) items[entry.index]];
}

/// Song flavour of [sortByKey], kept for readability at its call sites.
List<dynamic> sortSongsByKey(List<dynamic> songs, String sortKey) =>
    sortByKey(songs, sortKey);

/// Returns a new list of library entries ordered for [type]. [nameKey] holds
/// the displayed name: 'title' for playlists and artists, 'name' for folders.
/// Display-only: the stored order is never touched.
List<dynamic> sortLibraryItems(
  List<dynamic> items,
  LibrarySortType type, {
  String nameKey = 'title',
}) => switch (type) {
  LibrarySortType.default_ => List<dynamic>.of(items),
  LibrarySortType.nameAsc => sortByKey(items, nameKey),
  LibrarySortType.nameDesc => sortByKey(items, nameKey, descending: true),
};

/// Returns a new list with the most recently appended songs first.
List<dynamic> sortSongsNewestFirst(List<dynamic> songs) =>
    List<dynamic>.of(songs.reversed);

/// Returns a new list ordered by newest [dateKey], preserving ties.
List<dynamic> sortSongsByDateAdded(
  List<dynamic> songs, {
  String dateKey = 'dateAdded',
}) {
  int dateOf(dynamic song) {
    final value = song is Map ? song[dateKey] : null;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  final indexed =
      [
        for (var i = 0; i < songs.length; i++)
          (index: i, date: dateOf(songs[i])),
      ]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : a.index.compareTo(b.index);
      });
  return [for (final entry in indexed) songs[entry.index]];
}
