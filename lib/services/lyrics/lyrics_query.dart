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

import 'package:musify/services/lyrics/lyrics_models.dart';

const _noise =
    r'official|video|audio|lyric|lyrics|visuali[sz]er|music video|\bmv\b|'
    r'\bhd\b|\bhq\b|4k|1080p|remaster(?:ed)?|explicit|clean|karaoke|'
    r'feat\.?|ft\.?|featuring|prod\.?';

final RegExp _noisyBrackets = RegExp(
  r'\s*[\(\[【][^\)\]】]*?(?:' + _noise + r')[^\)\]】]*[\)\]】]',
  caseSensitive: false,
);
final RegExp _remasterSuffix = RegExp(
  r'\s+[-–]\s+(?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?\s*$',
  caseSensitive: false,
);
final RegExp _trailingFeat = RegExp(
  r'\s+(?:feat\.?|ft\.?|featuring)\s+.*$',
  caseSensitive: false,
);
final RegExp _trailingKeyword = RegExp(
  r'\s+(?:lyrics?|karaoke)\s*$',
  caseSensitive: false,
);
final RegExp _dashSeparator = RegExp(r'\s+[-–—]\s+');

/// Removes the decorations YouTube titles usually carry
/// ("(Official Video)", "[Lyrics]", "feat. X", "- Remastered 2011", ...).
String cleanTitle(String input) {
  var t = input.trim();
  final pipe = t.indexOf(' | ');
  if (pipe > 0) t = t.substring(0, pipe);

  t = t.replaceAll(_noisyBrackets, '');
  t = t.replaceAll(_remasterSuffix, '');
  t = t.replaceAll(_trailingFeat, '');

  final stripped = t.replaceAll(_trailingKeyword, '').trim();
  if (stripped.isNotEmpty) t = stripped;

  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.isEmpty ? input.trim() : t;
}

/// Returns the primary artist: drops "- Topic"/"VEVO" channel suffixes and
/// everything after the first comma or "feat.".
String cleanArtist(String input) {
  var a = input.split(',').first.trim();
  a = a.replaceAll(RegExp(r'\s*-\s*topic\s*$', caseSensitive: false), '');
  a = a.replaceAll(RegExp(r'\s*vevo\s*$', caseSensitive: false), '');
  a = a.replaceAll(_trailingFeat, '');
  return a.trim();
}

const _foldMap = <String, String>{
  'àáâãäåāăą': 'a',
  'çćĉċč': 'c',
  'ďđ': 'd',
  'èéêëēĕėęě': 'e',
  'ĝğġģ': 'g',
  'ìíîïĩīĭįı': 'i',
  'ķ': 'k',
  'ĺļľŀł': 'l',
  'ñńņňŉ': 'n',
  'òóôõöøōŏő': 'o',
  'ŕŗř': 'r',
  'śŝşš': 's',
  'ţťŧ': 't',
  'ùúûüũūŭůűų': 'u',
  'ŵ': 'w',
  'ýÿŷ': 'y',
  'źżž': 'z',
  'ß': 'ss',
  'æ': 'ae',
  'œ': 'oe',
};

/// Lower-cases [input] and replaces Latin accents with ASCII equivalents.
/// Characters from other scripts are kept untouched.
String foldDiacritics(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    var replacement = ch;
    for (final entry in _foldMap.entries) {
      if (entry.key.contains(ch)) {
        replacement = entry.value;
        break;
      }
    }
    buffer.write(replacement);
  }
  return buffer.toString();
}

/// `The Weeknd` -> `the-weeknd`. Returns an empty string when nothing ASCII
/// remains (e.g. Arabic or Japanese titles); callers must skip slug based
/// scrapers in that case instead of requesting a broken URL.
String lyricsSlug(String input) {
  var s = foldDiacritics(input).replaceAll(RegExp(r'\s+'), '-');
  s = s.replaceAll(RegExp('[^a-z0-9-]'), '');
  s = s.replaceAll(RegExp('-+'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  return s;
}

/// LyricsMania style slug: lower-case, spaces to underscores.
String lyricsManiaSlug(String input) {
  var s = foldDiacritics(input).trim().replaceAll(RegExp(r'\s+'), '_');
  s = s.replaceAll(RegExp("[^a-z0-9_'-]"), '');
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');
  return s;
}

/// Builds the ordered list of (artist, title) pairs worth searching for.
///
/// Handles titles that already contain the artist ("Artist - Song"), and the
/// reversed form ("Song - Artist"), which is common on label/re-upload
/// channels. At most [maxVariants] distinct pairs are returned.
List<TrackInfo> buildSearchVariants(TrackInfo track, {int maxVariants = 4}) {
  final artist = cleanArtist(track.artist);
  final title = cleanTitle(track.title);
  final result = <TrackInfo>[];
  final seen = <String>{};

  void add(String a, String t) {
    a = a.trim();
    t = t.trim();
    if (a.isEmpty || t.isEmpty) return;
    final key = '${foldDiacritics(a)}|${foldDiacritics(t)}';
    if (seen.add(key)) result.add(track.copyWith(artist: a, title: t));
  }

  final parts = title.split(_dashSeparator);
  final hasDash = parts.length >= 2;
  if (hasDash) {
    final left = parts.first.trim();
    final right = parts.sublist(1).join(' - ').trim();
    if (foldDiacritics(left) == foldDiacritics(artist)) {
      add(artist, right);
    }
    add(artist, title);
    add(left, right);
    add(right, left);
  } else {
    add(artist, title);
  }

  return result.take(maxVariants).toList();
}
