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

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/models/song_chapter.dart';
import 'package:musify/services/proxy_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/chapter_parser.dart';
import 'package:musify/utilities/media_duration.dart';

/// Below this length a song is a song, not a run of them, and is not worth a
/// description lookup.
const Duration minimumChapteredSongLength = Duration(minutes: 10);

const Duration _lookupTimeout = Duration(seconds: 15);
const int _maxCachedSongs = 50;

/// Keeps the tracklist of the song being played, so an hour-long compilation
/// can be walked track by track instead of only dragged through.
class ChaptersService {
  factory ChaptersService() => _instance;

  ChaptersService._();

  static final ChaptersService _instance = ChaptersService._();

  /// The tracklist of the current song: `null` while nothing is known, and a
  /// set with no chapters once the song has been looked up and has none.
  final ValueNotifier<SongChapters?> current = ValueNotifier<SongChapters?>(
    null,
  );

  final Map<String, List<SongChapter>> _cache = {};

  List<SongChapter> get currentChapters => current.value?.chapters ?? const [];

  /// Publishes the tracklist of [song], fetching its description once when the
  /// song is long enough to hold several tracks.
  Future<void> loadFor(Map? song) async {
    final songId = song?['ytid']?.toString();
    if (song == null || songId == null || songId.isEmpty) {
      current.value = null;
      return;
    }
    if (current.value?.songId == songId) return;

    final cached = _cache[songId];
    if (cached != null) {
      current.value = SongChapters(songId: songId, chapters: cached);
      return;
    }

    // Until the description comes back, the song is one single track.
    current.value = SongChapters.none(songId);

    final duration = readMediaDuration(song['duration']);
    if (duration == null || duration < minimumChapteredSongLength) return;
    if (offlineMode.value) return;

    try {
      final video = await ytClient.videos.get(songId).timeout(_lookupTimeout);
      final chapters = parseChapters(video.description, duration: duration);
      _remember(songId, chapters);

      // The song may well have changed while the description was in flight.
      if (current.value?.songId == songId) {
        current.value = SongChapters(songId: songId, chapters: chapters);
      }
    } catch (e, stackTrace) {
      logger.log(
        'Error while getting chapters for $songId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void clear() {
    current.value = null;
  }

  void _remember(String songId, List<SongChapter> chapters) {
    if (_cache.length >= _maxCachedSongs) {
      _cache.remove(_cache.keys.first);
    }
    _cache[songId] = chapters;
  }
}

final chaptersService = ChaptersService();
