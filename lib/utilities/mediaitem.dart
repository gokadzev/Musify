import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Map mediaItemToMap(MediaItem mediaItem) => {
      'id': mediaItem.id,
      'ytid': mediaItem.extras!['ytid'],
      'album': mediaItem.album.toString(),
      'artist': mediaItem.artist.toString(),
      'title': mediaItem.title,
      'highResImage': mediaItem.artUri.toString(),
      'lowResImage': mediaItem.extras!['lowResImage'],
      'url': mediaItem.extras!['url'].toString(),
      'isLive': mediaItem.extras!['isLive'],
    };

MediaItem mapToMediaItem(Map song, String songUrl) => MediaItem(
      id: song['id'].toString(),
      album: '',
      artist: song['artist'].toString(),
      title: song['title'].toString(),
      artUri: song['isOffline'] != null && song['isOffline']
          ? Uri.file(
              song['highResImage'].toString(),
            )
          : Uri.parse(
              song['highResImage'].toString(),
            ),
      extras: {
        'url': songUrl,
        'lowResImage': song['lowResImage'],
        'ytid': song['ytid'],
        'isLive': song['isLive'],
        'isOffline': song['isOffline'],
        'artWorkPath': song['highResImage'].toString(),
      },
    );

UriAudioSource createAudioSource(MediaItem mediaItem) => AudioSource.uri(
      Uri.parse(mediaItem.extras!['url'].toString()),
      tag: mediaItem,
    );

List<UriAudioSource> createAudioSources(List<MediaItem> mediaItems) {
  return mediaItems
      .map(
        (mediaItem) => AudioSource.uri(
          Uri.parse(mediaItem.extras!['url'].toString()),
          tag: mediaItem,
        ),
      )
      .toList();
}
