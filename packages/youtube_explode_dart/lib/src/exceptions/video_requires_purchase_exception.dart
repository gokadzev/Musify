import '../videos/video_id.dart';
import 'video_unplayable_exception.dart';

/// Exception thrown when the requested video requires purchase.
class VideoRequiresPurchaseException extends VideoUnplayableException {
  /// VideoId instance
  final VideoId? previewVideoId;

  /// Initializes an instance of [VideoRequiresPurchaseException].
  VideoRequiresPurchaseException(VideoId videoId)
      : previewVideoId = null,
        super('Video `$videoId` is unplayable because it requires purchase.');

  /// Initializes an instance of [VideoRequiresPurchaseException].
  VideoRequiresPurchaseException.preview(VideoId videoId, this.previewVideoId)
      : super('Video `$videoId` is unplayable because it requires purchase.\n'
            'Streams are not available for this video.\n'
            'There is a preview video available: `$previewVideoId`.');
}
