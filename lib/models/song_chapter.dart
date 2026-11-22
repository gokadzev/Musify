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

/// One track inside a long video, as announced by the uploader's tracklist.
///
/// [end] is where the next track takes over, or the end of the video for the
/// last one.
class SongChapter {
  const SongChapter({
    required this.start,
    required this.end,
    required this.title,
  });

  final Duration start;
  final Duration end;
  final String title;

  bool contains(Duration position) => position >= start && position < end;
}

/// The tracklist of one song, kept together with the id it was read from so a
/// late answer can be dropped once the song has already changed.
class SongChapters {
  const SongChapters({required this.songId, required this.chapters});

  const SongChapters.none(this.songId) : chapters = const [];

  final String songId;
  final List<SongChapter> chapters;

  bool get isEmpty => chapters.isEmpty;
  bool get isNotEmpty => chapters.isNotEmpty;
  int get length => chapters.length;

  /// Index of the chapter playing at [position], or -1 when there is none.
  int indexAt(Duration position) {
    for (var i = chapters.length - 1; i >= 0; i--) {
      if (position >= chapters[i].start) return i;
    }
    return -1;
  }
}
