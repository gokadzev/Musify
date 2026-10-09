import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final customClients = [YoutubeApiClient.visionOs];

Map<String, String> get streamPlaybackHeaders {
  final client = customClients.first;
  final userAgent = client.payload['context']?['client']?['userAgent'];
  return {
    if (userAgent is String) 'user-agent': userAgent,
    for (final entry in client.headers.entries) entry.key: '${entry.value}',
  };
}
