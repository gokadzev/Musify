import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:media_kit/media_kit.dart';

/// just_audio wraps even a single source in a root concatenation.
Iterable<AudioSourceMessage> flattenAudioSource(
  AudioSourceMessage source,
) sync* {
  if (source is ConcatenatingAudioSourceMessage) {
    for (final child in source.children) {
      yield* flattenAudioSource(child);
    }
  } else if (source is LoopingAudioSourceMessage) {
    for (var i = 0; i < source.count; i++) {
      yield* flattenAudioSource(source.child);
    }
  } else {
    yield source;
  }
}

Media audioSourceToMedia(AudioSourceMessage source) => switch (source) {
  UriAudioSourceMessage() => Media(source.uri, httpHeaders: source.headers),
  ClippingAudioSourceMessage() => Media(
    source.child.uri,
    httpHeaders: source.child.headers,
    start: source.start,
    end: source.end,
  ),
  _ => throw UnsupportedError(
    '${source.runtimeType} is currently not supported',
  ),
};
