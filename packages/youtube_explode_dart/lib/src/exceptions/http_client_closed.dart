import 'youtube_explode_exception.dart';

/// An exception is thrown when the http-client is closed
/// and the request is still running.
class HttpClientClosedException extends YoutubeExplodeException {
  HttpClientClosedException()
      : super('The request could not be completed because '
            "the YoutubeExplode's http-client was closed.");
}
