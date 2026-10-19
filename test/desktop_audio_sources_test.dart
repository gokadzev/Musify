import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:just_audio_media_kit/src/audio_sources.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

void main() {
  test('SponsorBlock clips survive the just_audio root playlist wrapper', () {
    final uri = ProgressiveAudioSourceMessage(
      id: 'song',
      uri: 'https://example.com/audio',
      headers: {'User-Agent': 'client', 'Referer': 'https://youtube.com/'},
    );
    final clips = [
      ClippingAudioSourceMessage(
        id: 'first',
        child: uri,
        start: Duration.zero,
        end: const Duration(seconds: 10),
      ),
      ClippingAudioSourceMessage(
        id: 'second',
        child: uri,
        start: const Duration(seconds: 20),
      ),
    ];
    final nested = ConcatenatingAudioSourceMessage(
      id: 'root',
      useLazyPreparation: true,
      shuffleOrder: [0],
      children: [
        ConcatenatingAudioSourceMessage(
          id: 'sponsorblock',
          useLazyPreparation: true,
          shuffleOrder: [0, 1],
          children: clips,
        ),
      ],
    );
    final medias = flattenAudioSource(nested).map(audioSourceToMedia).toList();
    expect(medias, hasLength(2));
    expect(medias.first.start, Duration.zero);
    expect(medias.first.end, const Duration(seconds: 10));
    expect(medias.last.start, const Duration(seconds: 20));
    expect(medias.last.end, isNull);
    for (final media in medias) {
      expect(media.httpHeaders, uri.headers);
      expect(media.uri, uri.uri);
    }
  });
}
