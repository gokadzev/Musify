import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

const asciiSquare = '▮';

void main() {
  group('$PlaybackState $asciiSquare', () {
    // Set initial values for nullable parameters
    final state = PlaybackState(
      androidCompactActionIndices: const [2, 3],
      errorCode: 0,
      errorMessage: 'errorMessage',
      queueIndex: 0,
    );

    test('position getter', () {
      fakeAsync((async) {
        const duration = Duration(milliseconds: 550);

        var localState = PlaybackState(
          processingState: AudioProcessingState.ready,
          playing: true,
        );
        async.elapse(duration);
        expect(localState.position, duration);

        const speed = 2.0;
        localState = localState.copyWith(speed: speed);
        async.elapse(duration);
        expect(
          localState.position,
          Duration(milliseconds: (duration.inMilliseconds * speed).toInt()),
        );

        // Playing set to false or not [AudioProcessingState.ready] should
        // return the [updatePosition]
        localState = localState.copyWith(playing: false);
        async.elapse(duration);
        expect(state.position, Duration.zero);

        localState = localState.copyWith(
          playing: true,
          processingState: AudioProcessingState.buffering,
        );
        async.elapse(duration);
        expect(state.position, Duration.zero);
      });
    });

    test('throws with invalid `androidCompactActionIndices`', () {
      expect(
        () => PlaybackState(androidCompactActionIndices: [1, 2, 3, 4]),
        throwsAssertionError,
      );
    });

    test('equality', () {
      fakeAsync((async) {
        expect(
          PlaybackState(
            controls: [MediaControl.play],
            androidCompactActionIndices: [1, 2, 3],
            systemActions: {MediaAction.fastForward},
          ),
          PlaybackState(
            controls: [MediaControl.play],
            androidCompactActionIndices: [1, 2, 3],
            systemActions: {MediaAction.fastForward},
          ),
        );
        expect(
          PlaybackState(controls: [MediaControl.pause]),
          isNot(PlaybackState(controls: [MediaControl.play])),
        );
      });
    });

    test('empty copyWith does nothing', () {
      final actual = state.copyWith();
      expect(
        actual,
        PlaybackState(
          androidCompactActionIndices: const [2, 3],
          updateTime: actual.updateTime,
          errorCode: 0,
          errorMessage: 'errorMessage',
          queueIndex: 0,
        ),
      );
    });

    test('copyWith works', () {
      final actual = state.copyWith(
        processingState: AudioProcessingState.buffering,
        playing: true,
        controls: const [MediaControl.play],
        androidCompactActionIndices: null,
        systemActions: const {MediaAction.fastForward},
        updatePosition: const Duration(seconds: 1),
        bufferedPosition: const Duration(seconds: 1),
        speed: 2.0,
        errorCode: null,
        errorMessage: null,
        repeatMode: AudioServiceRepeatMode.one,
        shuffleMode: AudioServiceShuffleMode.all,
        captioningEnabled: false,
        queueIndex: null,
      );

      // Verify that nullable values can be nulled out,
      // other values can be changed
      expect(
        actual,
        PlaybackState(
          processingState: AudioProcessingState.buffering,
          playing: true,
          controls: const [MediaControl.play],
          androidCompactActionIndices: null,
          systemActions: const {MediaAction.fastForward},
          updatePosition: const Duration(seconds: 1),
          bufferedPosition: const Duration(seconds: 1),
          speed: 2.0,
          updateTime: actual.updateTime,
          errorCode: null,
          errorMessage: null,
          repeatMode: AudioServiceRepeatMode.one,
          shuffleMode: AudioServiceShuffleMode.all,
          captioningEnabled: false,
          queueIndex: null,
        ),
      );
    });
  });

  group('$Rating $asciiSquare', () {
    test('equality', () {
      expect(
        Rating.newStarRating(RatingStyle.range3stars, 3),
        Rating.newStarRating(RatingStyle.range3stars, 3),
      );
      expect(
        Rating.newStarRating(RatingStyle.range3stars, 3),
        isNot(const Rating.newPercentageRating(3)),
      );
    });

    test('percentage style', () {
      // not percentage style should return -1
      expect(
        const Rating.newHeartRating(false).getPercentRating(),
        -1,
      );
      // unset rating should return -1
      expect(
        const Rating.newUnratedRating(RatingStyle.percentage)
            .getPercentRating(),
        -1,
      );
      // invalid values throw
      expect(
        () => Rating.newPercentageRating(-1),
        throwsAssertionError,
      );
      expect(
        () => Rating.newPercentageRating(101),
        throwsAssertionError,
      );
      // should return a valid value otherwise
      expect(
        const Rating.newPercentageRating(100).getPercentRating(),
        100,
      );
    });

    test('star style', () {
      // not star style should return -1
      expect(
        const Rating.newHeartRating(false).getStarRating(),
        -1,
      );
      // unset rating should return -1
      expect(
        const Rating.newUnratedRating(RatingStyle.range3stars).getStarRating(),
        -1,
      );
      // invalid values throw
      expect(
        () => Rating.newStarRating(RatingStyle.heart, 0),
        throwsAssertionError,
      );
      expect(
        () => Rating.newStarRating(RatingStyle.range3stars, 4),
        throwsAssertionError,
      );
      expect(
        () => Rating.newStarRating(RatingStyle.range4stars, 5),
        throwsAssertionError,
      );
      expect(
        () => Rating.newStarRating(RatingStyle.range5stars, 6),
        throwsAssertionError,
      );
      // should return a valid value otherwise
      expect(
        Rating.newStarRating(RatingStyle.range3stars, 3).getStarRating(),
        3,
      );
    });

    test('heart style', () {
      // not heart style should return false
      expect(
        const Rating.newPercentageRating(0).hasHeart(),
        false,
      );
      // unset rating should return false
      expect(
        const Rating.newUnratedRating(RatingStyle.heart).hasHeart(),
        false,
      );
      // should return a valid value otherwise
      expect(
        const Rating.newHeartRating(true).hasHeart(),
        true,
      );
    });

    test('thumb style', () {
      // not thumb style should return false
      expect(
        const Rating.newPercentageRating(0).isThumbUp(),
        false,
      );
      // unset rating should return false
      expect(
        const Rating.newUnratedRating(RatingStyle.thumbUpDown).isThumbUp(),
        false,
      );
      // should return a valid value otherwise
      expect(
        const Rating.newThumbRating(true).isThumbUp(),
        true,
      );
    });

    test('is rated', () {
      expect(
        const Rating.newUnratedRating(RatingStyle.percentage).isRated(),
        false,
      );
      expect(
        const Rating.newPercentageRating(0).isRated(),
        true,
      );
    });
  });

  group('$MediaItem $asciiSquare', () {
    // Set initial values for nullable parameters
    final mediaItem = MediaItem(
      id: 'id',
      title: 'title',
      album: 'album',
      artist: 'artist',
      genre: 'genre',
      duration: const Duration(seconds: 1),
      artUri: Uri.file('file'),
      playable: true,
      displayTitle: 'displayTitle',
      displaySubtitle: 'displaySubtitle',
      displayDescription: 'displayDescription',
      rating: const Rating.newHeartRating(false),
      extras: <String, dynamic>{'key': 'value'},
    );

    test('equality', () {
      expect(
        mediaItem,
        const MediaItem(id: 'id', title: 'title'),
      );
      expect(
        mediaItem,
        const MediaItem(id: 'id', title: 'otherTitle'),
      );
      expect(
        mediaItem,
        isNot(const MediaItem(id: 'otherId', title: 'title')),
      );
    });

    test('empty copyWith does nothing', () {
      final actual = mediaItem.copyWith();
      expect(actual, mediaItem);
    });

    test('copyWith works', () {
      final actual = mediaItem.copyWith(
        id: '_id',
        title: '_title',
        album: null,
        artist: null,
        genre: null,
        duration: null,
        artUri: null,
        playable: null,
        displayTitle: null,
        displaySubtitle: null,
        displayDescription: null,
        rating: null,
        extras: null,
      );

      // Verify that nullable values can be nulled out,
      // other values can be changed
      expect(
        actual,
        const MediaItem(
          id: '_id',
          title: '_title',
          album: null,
          artist: null,
          genre: null,
          duration: null,
          artUri: null,
          playable: null,
          displayTitle: null,
          displaySubtitle: null,
          displayDescription: null,
          rating: null,
          extras: null,
        ),
      );
    });
  });

  group('$MediaControl $asciiSquare', () {
    const mediaControl = MediaControl(
      androidIcon: 'androidIcon',
      label: 'label',
      action: MediaAction.pause,
    );

    test('equality', () {
      expect(
        mediaControl,
        // ignore: prefer_const_constructors
        MediaControl(
          androidIcon: 'androidIcon',
          label: 'label',
          action: MediaAction.pause,
        ),
      );
      expect(
        mediaControl,
        isNot(MediaControl.pause),
      );
    });
  });

  group('$AudioServiceConfig $asciiSquare', () {
    test('asserts proper notification ongoing config', () {
      expect(
        () {
          AudioServiceConfig(
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: false,
          );
        },
        throwsAssertionError,
      );
    });
  });
}
