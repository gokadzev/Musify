import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

Map mediaItemToMap(MediaItem mediaItem) {
  return {
    'id': mediaItem.id,
    'ytid': mediaItem.extras!['ytid'],
    'album': mediaItem.album.toString(),
    'artist': mediaItem.artist.toString(),
    'title': mediaItem.title,
    'highResImage': mediaItem.artUri.toString(),
    'lowResImage': mediaItem.extras!['lowResImage'],
    'url': mediaItem.extras!['url'].toString(),
  };
}

MediaItem songModelToMediaItem(AudioModel song, String songUrl) {
  return MediaItem(
    id: song.id.toString(),
    album: '',
    artist: '',
    title: song.displayName,
    artUri: Uri.parse(''),
    extras: {
      'url': songUrl,
      'lowResImage': '',
      'ytid': '',
      'localSongId': song.id,
      'ogid': song.id
    },
  );
}

MediaItem mapToMediaItem(Map song, String songUrl) {
  return MediaItem(
    id: song['id'].toString(),
    album: '',
    artist: song['artist'].toString(),
    title: song['title'].toString(),
    artUri: Uri.parse(
      song['highResImage'].toString(),
    ),
    extras: {
      'url': songUrl,
      'lowResImage': song['lowResImage'],
      'ytid': song['ytid'],
      'localSongId': song['localSongId']
    },
  );
}

UriAudioSource createAudioSource(MediaItem mediaItem) {
  return AudioSource.uri(
    Uri.parse(mediaItem.extras!['url'].toString()),
    tag: mediaItem,
  );
}
