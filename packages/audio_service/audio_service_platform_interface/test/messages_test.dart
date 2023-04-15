import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';

import 'stubs.dart';

const mediaControlMessage = MediaControlMessage(
  androidIcon: 'androidIcon',
  label: 'label',
  action: MediaActionMessage.play,
);

void main() {
  test('$MediaControlMessage maps', () {
    expect(mediaControlMessage.toMap(), <String, dynamic>{
      'androidIcon': 'androidIcon',
      'label': 'label',
      'action': MediaActionMessage.play.index,
    });
  });

  test('$PlaybackStateMessage maps', () {
    final message = PlaybackStateMessage(
      processingState: AudioProcessingStateMessage.idle,
      playing: false,
      controls: const <MediaControlMessage>[
        mediaControlMessage,
      ],
      androidCompactActionIndices: [1, 2, 3],
      systemActions: const <MediaActionMessage>{
        MediaActionMessage.fastForward,
        MediaActionMessage.play,
      },
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
      updateTime: DateTime.now(),
      errorCode: 0,
      errorMessage: '',
      repeatMode: AudioServiceRepeatModeMessage.none,
      shuffleMode: AudioServiceShuffleModeMessage.none,
      captioningEnabled: false,
      queueIndex: 0,
    );
    final map = message.toMap();
    expect(
      PlaybackStateMessage.fromMap(map).toMap(),
      map
        ..['androidCompactActionIndices'] = null
        ..['controls'] = const <MediaControlMessage>[],
    );

    final messageWithAllNulls = PlaybackStateMessage(
      processingState: AudioProcessingStateMessage.idle,
      playing: false,
      controls: const <MediaControlMessage>[mediaControlMessage],
      androidCompactActionIndices: null,
      systemActions: const <MediaActionMessage>{
        MediaActionMessage.fastForward,
        MediaActionMessage.play,
      },
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
      updateTime: null,
      errorCode: null,
      errorMessage: null,
      repeatMode: AudioServiceRepeatModeMessage.none,
      shuffleMode: AudioServiceShuffleModeMessage.none,
      captioningEnabled: false,
      queueIndex: null,
    );
    final mapWithAllNulls = messageWithAllNulls.toMap();
    expect(
      PlaybackStateMessage.fromMap(mapWithAllNulls).toMap(),
      mapWithAllNulls
        ..['androidCompactActionIndices'] = null
        ..['controls'] = const <MediaControlMessage>[],
    );
  });

  test('$MediaItemMessage maps', () {
    const messageWithAllNulls = MediaItemMessage(
      id: 'id',
      title: 'title',
    );
    final mapWithAllNulls = messageWithAllNulls.toMap();
    expect(
      MediaItemMessage.fromMap(mapWithAllNulls).toMap(),
      mapWithAllNulls,
    );

    final message = MediaItemMessage(
      id: 'id',
      title: 'title',
      album: 'album',
      artist: 'artist',
      genre: 'genre',
      duration: Duration.zero,
      artUri: Stubs.uri,
      playable: false,
      displayTitle: 'displayTitle',
      displaySubtitle: 'displaySubtitle',
      displayDescription: 'displayDescription',
      rating: const RatingMessage(
        type: RatingStyleMessage.heart,
        value: false,
      ),
      extras: Stubs.map,
    );
    final map = message.toMap();
    expect(
      MediaItemMessage.fromMap(map).toMap(),
      map,
    );
  });

  test('$AudioServiceConfigMessage asserts proper notification ongoing config',
      () {
    expect(
      () {
        AudioServiceConfigMessage(
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
        );
      },
      throwsAssertionError,
    );
  });

  group('$RatingMessage $asciiSquare', () {
    test('maps', () {
      const messageWithAllNulls = RatingMessage(
        type: RatingStyleMessage.heart,
        value: null,
      );
      final mapWithAllNulls = messageWithAllNulls.toMap();
      expect(
        RatingMessage.fromMap(mapWithAllNulls).toMap(),
        mapWithAllNulls,
      );

      const message = RatingMessage(
        type: RatingStyleMessage.heart,
        value: false,
      );
      final map = message.toMap();
      expect(
        RatingMessage.fromMap(map).toMap(),
        map,
      );
    });

    test('percentage style', () {
      // not percentage style should return -1
      expect(
        const RatingMessage(
          type: RatingStyleMessage.heart,
          value: false,
        ).percentRating,
        -1,
      );
      // unset rating should return -1
      expect(
        const RatingMessage(
          type: RatingStyleMessage.percentage,
          value: null,
        ).percentRating,
        -1,
      );
      // invalid values should return -1
      expect(
        const RatingMessage(
          type: RatingStyleMessage.percentage,
          value: -1.0,
        ).percentRating,
        -1,
      );
      expect(
        const RatingMessage(
          type: RatingStyleMessage.percentage,
          value: 101.0,
        ).percentRating,
        -1,
      );
      // should return a valid value otherwise
      expect(
        const RatingMessage(
          type: RatingStyleMessage.percentage,
          value: 100.0,
        ).percentRating,
        100,
      );
    });

    test('star style', () {
      // not star style should return -1
      expect(
        const RatingMessage(
          type: RatingStyleMessage.heart,
          value: false,
        ).starRating,
        -1,
      );
      // unset rating should return -1
      expect(
        const RatingMessage(
          type: RatingStyleMessage.range3stars,
          value: null,
        ).starRating,
        -1,
      );
      // should return a valid value otherwise
      expect(
        const RatingMessage(
          type: RatingStyleMessage.range3stars,
          value: 3,
        ).starRating,
        3,
      );
    });

    test('heart style', () {
      // not heart style should return false
      expect(
        const RatingMessage(
          type: RatingStyleMessage.percentage,
          value: 0,
        ).hasHeart,
        false,
      );
      // unset rating should return false
      expect(
        const RatingMessage(
          type: RatingStyleMessage.heart,
          value: null,
        ).hasHeart,
        false,
      );
      // should return a valid value otherwise
      expect(
        const RatingMessage(
          type: RatingStyleMessage.heart,
          value: true,
        ).hasHeart,
        true,
      );
    });

    test('thumb style', () {
      // not thumb style should return false
      expect(
        const RatingMessage(
          type: RatingStyleMessage.percentage,
          value: 0,
        ).isThumbUp,
        false,
      );
      // unset rating should return false
      expect(
        const RatingMessage(
          type: RatingStyleMessage.thumbUpDown,
          value: null,
        ).isThumbUp,
        false,
      );
      // should return a valid value otherwise
      expect(
        const RatingMessage(
          type: RatingStyleMessage.thumbUpDown,
          value: true,
        ).isThumbUp,
        true,
      );
    });

    test('is rated', () {
      expect(
        const RatingMessage(
          type: RatingStyleMessage.percentage,
          value: null,
        ).isRated,
        false,
      );
      expect(
        const RatingMessage(
          type: RatingStyleMessage.percentage,
          value: 0,
        ).isRated,
        true,
      );
    });
  });
}
