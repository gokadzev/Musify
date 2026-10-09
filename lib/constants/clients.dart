import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Clients tried in order - the next one is used only if the previous fails
const fallbackClients = [YoutubeApiClient.visionOs, YoutubeApiClient.android];

// Client that produced the stream URL of each song, so playback can send
// the matching headers.
final Map<String, YoutubeApiClient> _songClients = {};

Future<StreamManifest> getManifestWithFallback(
  YoutubeExplode yt,
  String songId, {
  required Duration timeout,
}) async {
  Object? lastError;
  StackTrace? lastStack;

  for (final client in fallbackClients) {
    try {
      final manifest = await yt.videos.streams
          .getManifest(songId, ytClients: [client])
          .timeout(timeout);
      if (manifest.audioOnly.isEmpty) {
        throw VideoUnavailableException('No audio streams for "$songId"');
      }
      _songClients[songId] = client;
      return manifest;
    } catch (e, s) {
      lastError = e;
      lastStack = s;
    }
  }

  Error.throwWithStackTrace(lastError!, lastStack!);
}

/// Headers googlevideo.com expects for URLs minted by the client that served
/// [songId]; a mismatched User-Agent can cause HTTP 403.
Map<String, String> streamPlaybackHeaders(String? songId) {
  final client = _songClients[songId] ?? fallbackClients.first;
  final userAgent = client.payload['context']?['client']?['userAgent'];
  return {
    if (userAgent is String) 'user-agent': userAgent,
    for (final entry in client.headers.entries) entry.key: '${entry.value}',
  };
}
