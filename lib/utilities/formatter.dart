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

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const _noiseTerms =
    'official music video|official lyric video|official lyrics video|'
    'official video|official 4k video|official audio|lyric video|'
    'lyrics video|official hd video|lyric visualizer|lyric vizualizer|'
    'official visualizer|official vizualizer|official visualiser|official vizualiser|lyrics|lyric|official song clip|'
    'official|karaoke';

// Bracket groups that contain a noise term anywhere inside: (Official Video)
final _bracketedNoisePattern = RegExp(
  r'[\(\[][^\)\]]*(?:' + _noiseTerms + r')[^\)\]]*[\)\]]',
  caseSensitive: false,
);

// Same noise phrases unbracketed at the end of a title, e.g. after | is stripped.
final _trailingNoisePattern = RegExp(
  r'\s*[-–—]?\s*\b(?:' + _noiseTerms + r'|audio)\b\s*$',
  caseSensitive: false,
);

String formatSongTitle(String title) {
  // Remove bracketed groups first to avoid false matches on real title words.
  var t = title.replaceAll(_bracketedNoisePattern, '');

  // Strip lone brackets, pipes, and decode HTML entities.
  t = t
      .replaceAll(RegExp(r'[\[\]()|]'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&#039;', "'")
      .replaceAll('&quot;', '"')
      .trimLeft();

  // Strip trailing unbracketed noise; loop to handle stacked suffixes.
  String prev;
  do {
    prev = t;
    t = t.replaceAll(_trailingNoisePattern, '');
  } while (t != prev);

  return t.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

Map<String, dynamic> returnSongLayout(
  int index,
  Video song, {
  String? playlistImage,
}) {
  // Split only on the first ' - ' so dashes inside the title are preserved.
  final sep = song.title.indexOf(' - ');
  final artist = sep != -1 ? song.title.substring(0, sep) : song.title;
  final rawTitle = sep != -1 ? song.title.substring(sep + 3) : song.title;

  return {
    'id': index,
    'ytid': song.id.toString(),
    'title': formatSongTitle(rawTitle),
    'artist': artist,
    'image': playlistImage ?? song.thumbnails.standardResUrl,
    'lowResImage': playlistImage ?? song.thumbnails.lowResUrl,
    'highResImage': playlistImage ?? song.thumbnails.maxResUrl,
    'duration': song.duration?.inSeconds,
    'isLive': song.isLive,
  };
}

String? getSongId(String url) => VideoId.parseVideoId(url);

String formatDuration(int audioDurationInSeconds) {
  final duration = Duration(seconds: audioDurationInSeconds);

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  return [
    if (hours > 0) hours.toString().padLeft(2, '0'),
    minutes.toString().padLeft(2, '0'),
    seconds.toString().padLeft(2, '0'),
  ].join(':');
}
