import 'package:youtube_explode_dart/youtube_explode_dart.dart';

String formatSongTitle(String title) {
  final patterns = {
    r'\[.*\]': '',
    r'\(.*': '',
    r'\|.*': '',
  };

  for (var pattern in patterns.keys) {
    title = title.replaceFirst(RegExp(pattern), patterns[pattern]!);
  }

  return title
      .trim()
      .replaceAll('&amp;', '&')
      .replaceAll('&#039;', "'")
      .replaceAll('&quot;', '"');
}

Map<String, dynamic> returnSongLayout(dynamic index, Video song) {
  return {
    'id': index,
    'ytid': song.id.toString(),
    'title': formatSongTitle(
      song.title.split('-')[song.title.split('-').length - 1],
    ),
    'image': song.thumbnails.standardResUrl,
    'lowResImage': song.thumbnails.lowResUrl,
    'highResImage': song.thumbnails.maxResUrl,
    'album': '',
    'type': 'song',
    'more_info': {
      'primary_artists': song.title.split('-')[0],
      'singers': song.title.split('-')[0],
    }
  };
}
