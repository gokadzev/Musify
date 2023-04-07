import 'package:youtube_explode_dart/youtube_explode_dart.dart';

String formatSongTitle(String title, {bool removeFileExtension = false}) {
  final patterns = {
    RegExp(r'\[.*\]'): '',
    RegExp(r'\(.*'): '',
    RegExp(r'\|.*'): '',
  };

  for (var pattern in patterns.keys) {
    title = title.replaceFirst(pattern, patterns[pattern]!);
  }

  if (removeFileExtension) {
    final fileExtensions = ['.mp3', '.flac', '.m4a'];
    for (var ext in fileExtensions) {
      title = title.replaceFirst(ext, '');
    }
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
    'artist': song.title.split('-')[0],
    'image': song.thumbnails.standardResUrl,
    'lowResImage': song.thumbnails.lowResUrl,
    'highResImage': song.thumbnails.maxResUrl,
    'isLive': song.isLive,
  };
}

String getSongId(String url) {
  return VideoId.parseVideoId(url)!;
}
