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

/// Represents a single line of lyrics with its timestamp
class LyricLine {
  LyricLine({required this.timeInMs, required this.text});

  /// Timestamp in milliseconds
  final int timeInMs;

  /// Lyric text for this line
  final String text;

  @override
  String toString() => 'LyricLine($timeInMs, $text)';
}

/// Parser for LRC format lyrics
class LrcParser {
  /// Parses LRC format lyrics into a list of [LyricLine]
  ///
  /// LRC format example:
  /// ```
  /// [00:12.34]First line
  /// [00:15.67]Second line
  /// [01:23.45]Third line
  /// ```
  static List<LyricLine> parse(String lyrics) {
    final lines = <LyricLine>[];

    if (lyrics.isEmpty) return lines;

    // Add empty first line so nothing is highlighted until first line is sung
    lines.add(LyricLine(timeInMs: 0, text: ''));

    final pattern = RegExp(
      r'^\[(\d{2}):(\d{2})\.(\d{2})\](.*)$',
      multiLine: true,
    );

    for (final match in pattern.allMatches(lyrics)) {
      try {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        final timeInMs = (minutes * 60 + seconds) * 1000 + centiseconds * 10;

        if (text.isNotEmpty) {
          lines.add(LyricLine(timeInMs: timeInMs, text: text));
        }
      } catch (_) {
        // Skip malformed lines
        continue;
      }
    }

    // Sort lines by timestamp
    lines.sort((a, b) => a.timeInMs.compareTo(b.timeInMs));

    return lines;
  }

  /// Checks if the lyrics are in LRC format (synced)
  static bool isSynced(String lyrics) {
    return RegExp(
      r'^\[(\d{2}):(\d{2})\.(\d{2})\]',
      multiLine: true,
    ).hasMatch(lyrics);
  }

  /// Finds the current line index based on position.
  /// Returns the last line whose timestamp is <= positionMs, with a small
  /// delay to compensate for the position stream reporting slightly ahead.
  static int findCurrentLineIndex(List<LyricLine> lines, int positionMs) {
    if (lines.isEmpty) return 0;

    // Subtract a small delay so lines don't advance before they're audible
    const delayMs = 1900;
    final adjustedMs = positionMs - delayMs;

    for (var i = lines.length - 1; i >= 0; i--) {
      if (lines[i].timeInMs <= adjustedMs) {
        return i;
      }
    }

    return 0;
  }
}
