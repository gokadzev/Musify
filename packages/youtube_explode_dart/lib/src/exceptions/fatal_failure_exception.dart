import 'package:http/http.dart';

import 'youtube_explode_exception.dart';

/// Exception thrown when a fatal failure occurs.
class FatalFailureException extends YoutubeExplodeException {
  final int statusCode;

  /// Initializes an instance of [FatalFailureException]
  FatalFailureException(super.message, this.statusCode);

  /// Initializes an instance of [FatalFailureException] with a [Response]
  FatalFailureException.httpRequest(BaseResponse response)
      : statusCode = response.statusCode,
        super('''
Failed to perform an HTTP request to YouTube due to a fatal failure.
In most cases, this error indicates that YouTube most likely changed something, which broke the library.
If this issue persists, please report it on the project's GitHub page.
Request: ${response.request}
Response: (${response.statusCode})
''');
}
