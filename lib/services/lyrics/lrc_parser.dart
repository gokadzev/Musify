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

final RegExp _timeTag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final RegExp _offsetTag = RegExp(
  r'^\s*\[offset:\s*([+-]?\d+)\s*\]\s*$',
  caseSensitive: false,
);
final RegExp _wordTag = RegExp(r'<\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?>');

/// Parses LRC text into time-sorted lines.
///
/// Supports `[mm:ss]`, `[mm:ss.xx]`, `[mm:ss.xxx]`, several timestamps on one
/// line, the `[offset:ms]` header and enhanced `<mm:ss.xx>` word tags (which
/// are stripped). Metadata tags such as `[ar:...]` are ignored.
List<LyricLine> parseLrc(String input) {
  final lines = <LyricLine>[];
  var offsetMs = 0;

  for (final raw in input.split(RegExp(r'\r?\n'))) {
    final offsetMatch = _offsetTag.firstMatch(raw);
    if (offsetMatch != null) {
      offsetMs = int.tryParse(offsetMatch.group(1)!) ?? 0;
      continue;
    }

    final matches = _timeTag.allMatches(raw).toList();
    if (matches.isEmpty) continue;

    final text = raw
        .substring(matches.last.end)
        .replaceAll(_wordTag, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    for (final m in matches) {
      final minutes = int.parse(m.group(1)!);
      final seconds = int.parse(m.group(2)!);
      final fraction = m.group(3);
      var millis = 0;
      if (fraction != null) {
        // "5" -> 500ms, "50" -> 500ms, "500" -> 500ms
        millis = int.parse(fraction.padRight(3, '0').substring(0, 3));
      }
      final total =
          Duration(minutes: minutes, seconds: seconds, milliseconds: millis) -
          // LRC offset: positive values make lyrics appear sooner.
          Duration(milliseconds: offsetMs);
      lines.add(LyricLine(total.isNegative ? Duration.zero : total, text));
    }
  }

  // Stable sort so equal timestamps keep their file order.
  final indexed = lines.asMap().entries.toList()
    ..sort((a, b) {
      final c = a.value.start.compareTo(b.value.start);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return indexed.map((e) => e.value).toList();
}
