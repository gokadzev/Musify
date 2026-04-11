import '../streams.dart';

/// YouTube media stream that contains video.
mixin VideoStreamInfo on StreamInfo {
  /// Video codec.
  String get videoCodec;

  /// Video quality label, as seen on YouTube.
  @Deprecated('Use qualityLabel')
  String get videoQualityLabel;

  /// Video quality.
  VideoQuality get videoQuality;

  /// Video resolution.
  VideoResolution get videoResolution;

  /// Video framerate.
  Framerate get framerate;
}

/// Extensions for Iterables of [VideoStreamInfo]
extension VideoStreamInfoExtension<T extends VideoStreamInfo> on Iterable<T> {
  /// Gets all video qualities available in a collection of video streams.
  Set<VideoQuality> getAllVideoQualities() =>
      map((e) => e.videoQuality).toSet();

  /// Gets video quality labels of all streams available in
  /// a collection of video streams.
  /// This could be longer than [getAllVideoQualities] since this gives also all
  /// the different framerate values.
  Set<String> getAllVideoQualitiesLabel() => map((e) => e.qualityLabel).toSet();

  /// Gets the stream with best video quality.
  T get bestQuality => sortByVideoQuality().first;

  /// Gets the video streams sorted by highest video quality
  /// (then by framerate) in ascending order.
  /// This returns new list without editing the original list.
  List<T> sortByVideoQuality() => toList()
    ..sort((a, b) => b.framerate.compareTo(a.framerate))
    ..sort((a, b) => b.videoResolution.compareTo(a.videoResolution));
}
