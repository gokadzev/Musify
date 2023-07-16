import 'package:musify/utilities/mediaitem.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

String formatSongTitle(String title, {bool removeFileExtension = false}) {
  final patterns = {
    RegExp(r'\[.*\]'): '',
    RegExp(r'\(.*'): '',
    RegExp(r'\|.*'): '',
  };

  for (final pattern in patterns.keys) {
    title = title.replaceFirst(pattern, patterns[pattern]!);
  }

  if (removeFileExtension) {
    final fileExtensions = ['.mp3', '.flac', '.m4a'];
    for (final ext in fileExtensions) {
      title = title.replaceFirst(ext, '');
    }
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

String formatDuration(int durationInMillis) {
  final minutes = (durationInMillis / (1000 * 60)).truncate();
  final seconds = ((durationInMillis / 1000) % 60).truncate();
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
