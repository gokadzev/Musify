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

final wordsPatternForSongTitle = RegExp(
  r'\b(official music video|official lyric video|official lyrics video|official video|official 4k video|official audio|lyric video|lyrics video|official hd video|lyric visualizer|lyric vizualizer|official visualizer|lyrics|lyric|official song clip)\b',
  caseSensitive: false,
);

final replacementsForSongTitle = {
  '[': '',
  ']': '',
  '(': '',
  ')': '',
  '|': '',
  '&amp;': '&',
  '&#039;': "'",
  '&quot;': '"',
};

String formatSongTitle(String title) {
  final pattern = RegExp(
    replacementsForSongTitle.keys.map(RegExp.escape).join('|'),
  );

  var finalTitle = title
      .replaceAllMapped(
        pattern,
        (match) => replacementsForSongTitle[match.group(0)] ?? '',
      )
      .trimLeft();

  finalTitle = finalTitle.replaceAll(wordsPatternForSongTitle, '');

  return finalTitle;
}

Map<String, dynamic> returnSongLayout(
  int index,
  Video song, {
  String? playlistImage,
}) {
  final titleParts = song.title.split('-');

  return {
    'id': index,
    'ytid': song.id.toString(),
    'title': formatSongTitle(titleParts[titleParts.length - 1]),
    'artist': titleParts[0],
    'image': playlistImage ?? song.thumbnails.standardResUrl,
    'lowResImage': playlistImage ?? song.thumbnails.lowResUrl,
    'highResImage': playlistImage ?? song.thumbnails.maxResUrl,
    'duration': song.duration?.inSeconds,
    'isLive': song.isLive,
  };
}

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
