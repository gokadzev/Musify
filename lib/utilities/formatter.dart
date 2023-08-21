import 'package:musify/utilities/mediaitem.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

String formatSongTitle(String title) {
  final patterns = {
    RegExp(r'\[.*\]'): '',
    RegExp(r'\(.*'): '',
    RegExp(r'\|.*'): '',
  };

  for (final pattern in patterns.keys) {
    title = title.replaceFirst(pattern, patterns[pattern]!);
  }

  return title
      .trim()
      .replaceAll('&amp;', '&')
      .replaceAll('&#039;', "'")
      .replaceAll('&quot;', '"');
}

Map<String, dynamic> returnSongLayout(dynamic index, Video song) => {
      'id': index,
      'ytid': song.id.toString(),
      'title': formatSongTitle(
        song.title.split('-')[song.title.split('-').length - 1],
      ),
      'artist': song.title.split('-')[0],
      'image': song.thumbnails.standardResUrl,
      'lowResImage': song.thumbnails.lowResUrl,
      'highResImage': song.thumbnails.maxResUrl,
      'duration': song.duration?.inMilliseconds,
      'isLive': song.isLive,
    };

Map<String, dynamic> returnSongLayoutFromAudioModel(
  dynamic index,
  AudioModel song,
) {
  return {
    'id': index,
    'ytid': '',
    'title': song.displayNameWOExt,
    'image': noImageVar,
    'artist': song.artist ?? '',
    'lowResImage': noImageVar,
    'highResImage': noImageVar,
    'songUrl': song.data,
    'localSongId': song.id,
    'isLive': false,
  };
}

String? getSongId(String url) => VideoId.parseVideoId(url);

String formatDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  var formattedDuration = '';

  if (hours > 0) {
    formattedDuration += '${hours.toString().padLeft(2, '0')}:';
  }

  formattedDuration += '${minutes.toString().padLeft(2, '0')}:';
  formattedDuration += seconds.toString().padLeft(2, '0');

  return formattedDuration;
}
