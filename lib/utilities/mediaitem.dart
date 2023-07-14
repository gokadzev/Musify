import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

const noImageVar =
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8bXVzaWN8ZW58MHx8MHx8&w=500&q=80';

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

MediaItem songModelToMediaItem(AudioModel song, String songUrl) => MediaItem(
      id: song.id.toString(),
      album: '',
      artist: '',
      title: song.displayName,
      artUri: Uri.parse(noImageVar),
      extras: {
        'url': songUrl,
        'lowResImage': '',
        'ytid': '',
        'localSongId': song.id,
        'ogid': song.id,
      },
    );

MediaItem mapToMediaItem(Map song, String songUrl) => MediaItem(
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
        'localSongId': song['localSongId'],
        'isLive': song['isLive'],
      },
    );

UriAudioSource createAudioSource(MediaItem mediaItem) => AudioSource.uri(
      Uri.parse(mediaItem.extras!['url'].toString()),
      tag: mediaItem,
    );
