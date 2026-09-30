import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final customClients = [YoutubeApiClient.visionOs];

/// Clients tried, in order, once [customClients] has come up empty.
///
/// visionOs is the only client YouTube still serves without a PO Token, and it
/// refuses outright anything marked "made for kids" — which is most nursery
/// rhymes. The android client does serve those, but only as a muxed 360p
/// stream: ask it for audio-only formats and it answers with a full list whose
/// URLs are all empty strings.
final fallbackClients = [YoutubeApiClient.android];

/// Headers that must accompany any request to a stream URL minted by
/// [customClients]. googlevideo ties a stream URL to the identity (in
/// particular the user-agent) of the client that requested it, so playing it
/// back with the player's own generic user-agent gets a 403 mid-stream.
///
/// The muxed URLs [fallbackClients] hands out carry `ratebypass` and were
/// measured to serve the same bytes under any user-agent, including this one,
/// so a fallback song needs no headers of its own. Clients are still resolved
/// one at a time rather than passed to `getManifest` as a list: given a list
/// it merges the streams of every client that answered, losing which client
/// minted which URL, and the headers no longer match.
final customClientHeaders = clientRequestHeaders(customClients.first);
