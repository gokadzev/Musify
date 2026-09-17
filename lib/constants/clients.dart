import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final customClients = [YoutubeApiClient.visionOs];

/// Headers that must accompany any request to a stream URL minted by
/// [customClients]. googlevideo ties a stream URL to the identity (in
/// particular the user-agent) of the client that requested it, so playing it
/// back with the player's own generic user-agent gets a 403 mid-stream.
final customClientHeaders = clientRequestHeaders(customClients.first);
