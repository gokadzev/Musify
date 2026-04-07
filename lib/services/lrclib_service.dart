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
import 'package:http/http.dart' as http;

/// Track model from LrcLib API
class Track {
  Track({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    this.syncedLyrics,
    this.plainLyrics,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    // Convert duration to int, handling both int and double types from API
    final durationValue = json['duration'] ?? 0;
    final duration = durationValue is double
        ? durationValue.toInt()
        : durationValue as int;

    return Track(
      id: json['id'] ?? 0,
      trackName: json['trackName'] ?? '',
      artistName: json['artistName'] ?? '',
      albumName: json['albumName'] ?? '',
      duration: duration,
      syncedLyrics: json['syncedLyrics'],
      plainLyrics: json['plainLyrics'],
    );
  }
  final int id;
  final String trackName;
  final String artistName;
  final String albumName;
  final int duration;
  final String? syncedLyrics;
  final String? plainLyrics;
}

/// LrcLib service for fetching lyrics (both synced and plain)
class LrcLibService {
  static const String _baseUrl = 'https://lrclib.net/api/search';

  // Patterns to clean from title
  static final List<RegExp> _titleCleanupPatterns = [
    RegExp(
      r'\s*\(.*?(official|video|audio|lyrics|lyric|visualizer|hd|hq|4k|remaster|remix|live|acoustic|version|edit|extended|radio|clean|explicit).*?\)',
      caseSensitive: false,
    ),
    RegExp(
      r'\s*\[.*?(official|video|audio|lyrics|lyric|visualizer|hd|hq|4k|remaster|remix|live|acoustic|version|edit|extended|radio|clean|explicit).*?\]',
      caseSensitive: false,
    ),
    RegExp(r'\s*【.*?】'),
    RegExp(r'\s*\|.*$'),
    RegExp(
      r'\s*-\s*(official|video|audio|lyrics|lyric|visualizer).*$',
      caseSensitive: false,
    ),
    RegExp(r'\s*\(feat\..*?\)', caseSensitive: false),
    RegExp(r'\s*\(ft\..*?\)', caseSensitive: false),
    RegExp(r'\s*feat\..*$', caseSensitive: false),
    RegExp(r'\s*ft\..*$', caseSensitive: false),
  ];

  // Artists separators for extracting primary artist
  static final List<String> _artistSeparators = [
    ' & ',
    ' and ',
    ', ',
    ' x ',
    ' X ',
    ' feat. ',
    ' feat ',
    ' ft. ',
    ' ft ',
    ' featuring ',
    ' with ',
  ];

  /// Clean title by removing common patterns
  static String _cleanTitle(String title) {
    var cleaned = title.trim();
    for (final pattern in _titleCleanupPatterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }
    return cleaned.trim();
  }

  /// Extract primary artist from the given string
  static String _cleanArtist(String artist) {
    var cleaned = artist.trim();
    // Get primary artist (first one before any separator)
    for (final separator in _artistSeparators) {
      final idx = cleaned.toLowerCase().indexOf(separator.toLowerCase());
      if (idx != -1) {
        cleaned = cleaned.substring(0, idx);
        break;
      }
    }
    return cleaned.trim();
  }

  /// Query LrcLib API with specific parameters
  static Future<List<Track>> _queryLyricsWithParams({
    String? trackName,
    String? artistName,
    String? albumName,
    String? query,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final queryParams = <String, String>{};

      if (query != null) queryParams['q'] = query;
      if (trackName != null) queryParams['track_name'] = trackName;
      if (artistName != null) queryParams['artist_name'] = artistName;
      if (albumName != null) queryParams['album_name'] = albumName;

      final uriWithQuery = uri.replace(queryParameters: queryParams);
      final response = await http
          .get(uriWithQuery)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);

        // Handle both array and object responses
        late List<dynamic> jsonList;
        if (jsonData is List) {
          jsonList = jsonData;
        } else if (jsonData is Map && jsonData['tracks'] != null) {
          jsonList = jsonData['tracks'];
        } else if (jsonData is Map) {
          // Single track response, wrap in list
          jsonList = [jsonData];
        } else {
          jsonList = [];
        }

        return jsonList
            .whereType<Map<String, dynamic>>()
            .map(Track.fromJson)
            .toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  /// Query LrcLib for lyrics using multiple strategies
  static Future<List<Track>> _queryLyrics({
    required String artist,
    required String title,
    String? album,
  }) async {
    final cleanedTitle = _cleanTitle(title);
    final cleanedArtist = _cleanArtist(artist);

    // Strategy 1: Search with cleaned title and artist
    var results =
        (await _queryLyricsWithParams(
              trackName: cleanedTitle,
              artistName: cleanedArtist,
              albumName: album,
            ))
            .where(
              (track) =>
                  track.syncedLyrics != null || track.plainLyrics != null,
            )
            .toList();

    if (results.isNotEmpty) return results;

    // Strategy 2: Search with cleaned title only
    results = (await _queryLyricsWithParams(trackName: cleanedTitle))
        .where(
          (track) => track.syncedLyrics != null || track.plainLyrics != null,
        )
        .toList();

    if (results.isNotEmpty) return results;

    // Strategy 3: Use query parameter with combined search
    results =
        (await _queryLyricsWithParams(query: '$cleanedArtist $cleanedTitle'))
            .where(
              (track) =>
                  track.syncedLyrics != null || track.plainLyrics != null,
            )
            .toList();

    if (results.isNotEmpty) return results;

    // Strategy 4: Use query parameter with just title
    results = (await _queryLyricsWithParams(query: cleanedTitle))
        .where(
          (track) => track.syncedLyrics != null || track.plainLyrics != null,
        )
        .toList();

    if (results.isNotEmpty) return results;

    // Strategy 5: Try original title if different from cleaned
    if (cleanedTitle != title.trim()) {
      results =
          (await _queryLyricsWithParams(
                trackName: title.trim(),
                artistName: artist.trim(),
              ))
              .where(
                (track) =>
                    track.syncedLyrics != null || track.plainLyrics != null,
              )
              .toList();

      if (results.isNotEmpty) return results;
    }

    return results;
  }

  /// Calculate string similarity ratio (0.0 to 1.0)
  static double _calculateStringSimilarity(String str1, String str2) {
    final s1 = str1.trim().toLowerCase();
    final s2 = str2.trim().toLowerCase();

    if (s1 == s2) return 1;
    if (s1.isEmpty || s2.isEmpty) return 0;

    if (s1.contains(s2) || s2.contains(s1)) return 0.8;

    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    final distance = _levenshteinDistance(s1, s2);
    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    final matrix = List<List<int>>.generate(
      s1.length + 1,
      (i) => List<int>.filled(s2.length + 1, 0),
    );

    for (var i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= s1.length; i++) {
      for (var j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + cost;
        matrix[i][j] = [
          deletion,
          insertion,
          substitution,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Fetch lyrics for a song - returns synced lyrics if available, otherwise plain lyrics
  static Future<String?> getLyrics({
    required String title,
    required String artist,
    int duration = -1,
    String? album,
  }) async {
    try {
      final tracks = await _queryLyrics(
        artist: artist,
        title: title,
        album: album,
      );

      if (tracks.isEmpty) {
        return null;
      }

      final cleanedTitle = _cleanTitle(title);
      final cleanedArtist = _cleanArtist(artist);

      Track? bestMatch;

      if (duration == -1) {
        // Find best match based on similarity scores
        bestMatch = tracks.isEmpty
            ? null
            : tracks.reduce((best, current) {
                var bestScore = 0.0;
                if (best.syncedLyrics != null) bestScore += 1.0;
                bestScore +=
                    (_calculateStringSimilarity(cleanedTitle, best.trackName) +
                        _calculateStringSimilarity(
                          cleanedArtist,
                          best.artistName,
                        )) /
                    2.0;

                var currentScore = 0.0;
                if (current.syncedLyrics != null) currentScore += 1.0;
                currentScore +=
                    (_calculateStringSimilarity(
                          cleanedTitle,
                          current.trackName,
                        ) +
                        _calculateStringSimilarity(
                          cleanedArtist,
                          current.artistName,
                        )) /
                    2.0;

                return bestScore >= currentScore ? best : current;
              });
      } else {
        // Find match with duration closest to the requested one (±5 seconds)
        bestMatch = tracks.isEmpty
            ? null
            : tracks.reduce((best, current) {
                final bestDiff = (best.duration - duration).abs();
                final currentDiff = (current.duration - duration).abs();
                return bestDiff <= currentDiff ? best : current;
              });

        // Only accept if within 5 seconds
        if (bestMatch != null && (bestMatch.duration - duration).abs() > 5) {
          bestMatch = null;
        }
      }

      if (bestMatch != null) {
        // Prefer synced lyrics over plain lyrics
        return bestMatch.syncedLyrics ?? bestMatch.plainLyrics;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
