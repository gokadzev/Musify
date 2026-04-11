import '../models/audio_track.dart';
import '../streams.dart';

/// YouTube media stream that contains audio.
mixin AudioStreamInfo on StreamInfo {
  String get audioCodec;

  /// Audio track which describes the language of the audio.
  AudioTrack? get audioTrack;
}
