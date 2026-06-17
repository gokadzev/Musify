import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_music_explode_dart/src/music_client.dart';

/// Library entry point for YouTube Music queries.
class YoutubeMusicExplode {
  YoutubeMusicExplode({YoutubeHttpClient? httpClient})
    : _httpClient = httpClient ?? YoutubeHttpClient() {
    music = MusicClient(_httpClient);
  }

  final YoutubeHttpClient _httpClient;

  /// YouTube Music artist/catalog queries.
  late final MusicClient music;

  /// Closes the underlying HTTP client.
  void close() {
    _httpClient.close();
  }
}
