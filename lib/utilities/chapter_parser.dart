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

import 'package:musify/models/song_chapter.dart';

/// Reads the tracklist an uploader writes in the description of a long video:
///
///     00:00 Une souris verte
///     02:14 Ainsi font font font
///     04:51 Petit escargot
///
/// This is the very list YouTube turns into chapters, so following its rules
/// keeps the result in step with what the site itself shows: at least three
/// entries, the first one on the opening seconds, and none shorter than ten
/// seconds.

/// Timestamps as they appear in a tracklist: `3:12`, `03:12` or `1:02:33`.
final RegExp _timestamp = RegExp(r'(?:(\d{1,2}):)?(\d{1,3}):([0-5]\d)');

final RegExp _digitOrColon = RegExp(r'[\d:]');
final RegExp _whitespace = RegExp(r'\s+');
final RegExp _leadingJunk = RegExp(r'^[\s\-–—•·*|:.,)\]}>#]+');
final RegExp _trailingJunk = RegExp(r'[\s\-–—•·*|:,(\[{<]+$');
final RegExp _trackNumber = RegExp(r'^\d{1,2}\s*[.)\-–—]\s*(?=\S)');

const int _minimumChapters = 3;
const Duration _minimumChapterLength = Duration(seconds: 10);

/// How late the first timestamp may be and still be read as the opening of the
/// video rather than a timestamp that merely happens to be mentioned.
const Duration _firstChapterTolerance = Duration(seconds: 30);

const int _maximumTitleLength = 150;

/// Stands in for the end of the last chapter when the song length is unknown.
const Duration _openEnd = Duration(hours: 24);

/// Returns the tracks listed in [description], or an empty list when it holds
/// no usable tracklist.
List<SongChapter> parseChapters(String? description, {Duration? duration}) {
  if (description == null || description.isEmpty) return const [];

  final matches = _timestamp
      .allMatches(description)
      .where((match) => _isStandalone(description, match))
      .toList();
  if (matches.length < _minimumChapters) return const [];

  final starts = <Duration>[];
  final titles = <String>[];

  for (var i = 0; i < matches.length; i++) {
    final match = matches[i];
    final start = _toDuration(match);

    if (starts.isEmpty) {
      // A tracklist covers the whole video, so it opens on its first seconds.
      // Earlier timestamps that do not are something else entirely.
      if (start > _firstChapterTolerance) continue;
    } else {
      if (duration != null && start >= duration) continue;
      // Skips entries out of order or too close to the previous one, which a
      // real tracklist never is.
      if (start - starts.last < _minimumChapterLength) continue;
    }

    starts.add(starts.isEmpty ? Duration.zero : start);
    titles.add(
      _titleFor(
        description,
        match,
        previous: i > 0 ? matches[i - 1] : null,
        next: i + 1 < matches.length ? matches[i + 1] : null,
      ),
    );
  }

  if (starts.length < _minimumChapters) return const [];

  // Timestamps without anything written next to them are not a tracklist.
  final named = titles.where((title) => title.isNotEmpty).length;
  if (named * 2 <= titles.length) return const [];

  final lastEnd = duration != null && duration > starts.last
      ? duration
      : _openEnd;

  return List.unmodifiable([
    for (var i = 0; i < starts.length; i++)
      SongChapter(
        start: starts[i],
        end: i + 1 < starts.length ? starts[i + 1] : lastEnd,
        title: titles[i],
      ),
  ]);
}

/// Rejects the digits of a longer run such as `12:34:56:78` or `2024:01`.
bool _isStandalone(String text, RegExpMatch match) {
  final before = match.start == 0 ? '' : text[match.start - 1];
  final after = match.end == text.length ? '' : text[match.end];
  return !_digitOrColon.hasMatch(before) && !_digitOrColon.hasMatch(after);
}

Duration _toDuration(RegExpMatch match) => Duration(
  hours: int.parse(match.group(1) ?? '0'),
  minutes: int.parse(match.group(2)!),
  seconds: int.parse(match.group(3)!),
);

/// The text written next to a timestamp, taken from after it — `00:00 Title` —
/// and from before it when that side is empty — `Title - 00:00`.
String _titleFor(
  String text,
  RegExpMatch match, {
  required RegExpMatch? previous,
  required RegExpMatch? next,
}) {
  var limit = _lineEnd(text, match.end);
  if (next != null && next.start < limit) limit = next.start;
  final after = _clean(text.substring(match.end, limit));
  if (after.isNotEmpty) return after;

  var lineStart = _lineStart(text, match.start);
  if (previous != null && previous.end > lineStart) lineStart = previous.end;
  return _clean(text.substring(lineStart, match.start));
}

int _lineStart(String text, int index) => text.lastIndexOf('\n', index) + 1;

int _lineEnd(String text, int index) {
  final newline = text.indexOf('\n', index);
  return newline == -1 ? text.length : newline;
}

String _clean(String raw) {
  var title = raw.replaceAll(_whitespace, ' ').trim();
  title = title.replaceFirst(_leadingJunk, '');
  title = title.replaceFirst(_trackNumber, '');
  title = title.replaceFirst(_leadingJunk, '');
  title = title.replaceFirst(_trailingJunk, '');
  if (title.length > _maximumTitleLength) {
    title = title.substring(0, _maximumTitleLength).trimRight();
  }
  return title;
}
