import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/app_utils.dart';

/// A song YouTube refuses to hand over — anything marked made for children,
/// among others — used to take the whole session down with it: the queue index
/// is rolled back on failure, so the retry asked for "the next song" and got
/// the one that had just failed, three times over, until playback stopped.
void main() {
  List<String?> queueOf(int count) => [
    for (var i = 0; i < count; i++) 'entry-$i',
  ];

  group('where recovery picks the queue up', () {
    test('it steps past the song that failed, not back onto it', () {
      expect(queuePositionAfterFailure(queueOf(5), 'entry-0'), 1);
      expect(queuePositionAfterFailure(queueOf(5), 'entry-3'), 4);
    });

    test('a failure on the last song leaves nothing to resume at', () {
      expect(queuePositionAfterFailure(queueOf(5), 'entry-4'), isNull);
    });

    test('the only song in the queue failing leaves nothing to resume at', () {
      expect(queuePositionAfterFailure(queueOf(1), 'entry-0'), isNull);
    });

    test('an empty queue or a nameless entry give nothing back', () {
      expect(queuePositionAfterFailure(queueOf(0), 'entry-0'), isNull);
      expect(queuePositionAfterFailure(queueOf(5), null), isNull);
      expect(queuePositionAfterFailure(queueOf(5), ''), isNull);
    });

    // Recovery waits out a delay before it runs, and the queue is free to
    // change while it waits. A position captured beforehand would by then
    // point at another song, so the entry is looked up again instead.
    test('a queue reordered during the delay still resumes behind the song', () {
      final reordered = <String?>['entry-3', 'entry-0', 'entry-1', 'entry-2'];
      expect(queuePositionAfterFailure(reordered, 'entry-0'), 2);
    });

    test('a song that failed last is recoverable once the queue grows', () {
      expect(queuePositionAfterFailure(queueOf(5), 'entry-4'), isNull);
      expect(queuePositionAfterFailure(queueOf(6), 'entry-4'), 5);
    });

    test('an entry that left the queue takes its recovery with it', () {
      final withoutIt = <String?>['entry-1', 'entry-2'];
      expect(queuePositionAfterFailure(withoutIt, 'entry-0'), isNull);
    });

    test('a queue replaced wholesale during the delay recovers nothing', () {
      final anotherPlaylist = <String?>['other-0', 'other-1'];
      expect(queuePositionAfterFailure(anotherPlaylist, 'entry-0'), isNull);
    });
  });

  group('what a playback failure leads to', () {
    PlaybackRecovery plan({
      int consecutiveErrors = 1,
      bool canRetry = true,
      bool recoveryPending = false,
      bool cameFromQueue = true,
    }) => planPlaybackRecovery(
      consecutiveErrors: consecutiveErrors,
      maxConsecutiveErrors: 3,
      canRetry: canRetry,
      recoveryPending: recoveryPending,
      cameFromQueue: cameFromQueue,
    );

    test('a failure in the queue steps past the song that caused it', () {
      expect(plan(), PlaybackRecovery.resumeAfterFailure);
    });

    test('a failure outside the queue falls back to the ordinary skip', () {
      expect(plan(cameFromQueue: false), PlaybackRecovery.skipToNext);
    });

    // The same failure is reported twice: once by the transition that saw it,
    // once by the player falling idle over it. The second report used to
    // schedule its own recovery, which skipped blindly to the next song —
    // the one that had just failed.
    test('a repeat report while a recovery waits is ignored', () {
      expect(plan(recoveryPending: true), PlaybackRecovery.ignore);
      expect(
        plan(recoveryPending: true, cameFromQueue: false),
        PlaybackRecovery.ignore,
      );
    });

    test('a repeat report does not count towards stopping playback', () {
      expect(
        plan(consecutiveErrors: 3, recoveryPending: true),
        PlaybackRecovery.ignore,
      );
    });

    test('failures in a row stop playback rather than grind on', () {
      expect(plan(consecutiveErrors: 2), PlaybackRecovery.resumeAfterFailure);
      expect(plan(consecutiveErrors: 3), PlaybackRecovery.stop);
      expect(plan(consecutiveErrors: 4), PlaybackRecovery.stop);
    });

    test('nothing to retry leaves the queue where it stands', () {
      expect(plan(canRetry: false), PlaybackRecovery.standStill);
      expect(
        plan(canRetry: false, cameFromQueue: false),
        PlaybackRecovery.standStill,
      );
    });

    test('stopping wins over a queue that has somewhere to go', () {
      expect(
        plan(consecutiveErrors: 3, canRetry: true),
        PlaybackRecovery.stop,
      );
    });
  });
}
