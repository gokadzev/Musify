import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/playback_failure_recovery.dart';
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
        plan(consecutiveErrors: 3),
        PlaybackRecovery.stop,
      );
    });
  });

  // Long enough that the queue still has somewhere to go after three
  // failures in a row, so what stops playback is the count and not the end.
  final longQueue = <String?>[
    'entry-0',
    'entry-1',
    'entry-2',
    'entry-3',
    'entry-4',
  ];

  // The two groups above test the reasoning in isolation. This one drives the
  // handler itself: the failure count it keeps, the error it clears, the
  // recovery it leaves waiting and the queue it reads when that wait is over.
  group('the handler a failure is reported to', () {
    test('it steps past the song that failed once the delay is out', () {
      final session = _Session()..failOn('entry-0');

      expect(
        session.resumedAt,
        isEmpty,
        reason: 'the recovery waits out its delay first',
      );

      session.letTheDelayRunOut();
      expect(session.resumedAt, [1]);
      expect(session.skipped, 0);
    });

    // The failure used to stay set, so the player falling idle over it was
    // taken for a fresh one and scheduled the blind skip this fix replaces —
    // straight back onto the song that had just failed.
    test('the failure is cleared as soon as it has been accounted for', () {
      final session = _Session()..failOn('entry-0');

      expect(session.recovery.lastError, isNull);
    });

    test('the repeat report an idle player makes is no second recovery', () {
      final session = _Session()
        ..failOn('entry-0')
        ..failOn(null)
        ..letTheDelayRunOut();

      expect(session.resumedAt, [1]);
      expect(
        session.skipped,
        0,
        reason: 'the repeat must not schedule a skip of its own',
      );
      expect(
        session.recovery.consecutiveErrors,
        1,
        reason: 'one failure, however many times it is reported',
      );
    });

    test('a queue reordered during the delay still resumes behind the song', () {
      // The queue moves while the recovery waits out its delay.
      final session = _Session()
        ..failOn('entry-0')
        ..queue = ['entry-2', 'entry-0', 'entry-1']
        ..letTheDelayRunOut();

      expect(session.resumedAt, [2]);
    });

    test('a song pulled out of the queue takes its recovery with it', () {
      // The queue moves while the recovery waits out its delay.
      final session = _Session()
        ..failOn('entry-0')
        ..queue = ['entry-1', 'entry-2']
        ..letTheDelayRunOut();

      expect(session.resumedAt, isEmpty);
    });

    test('a transition started during the delay retires the recovery', () {
      final session = _Session()
        ..failOn('entry-0')
        ..transitionStarted()
        ..letTheDelayRunOut();

      expect(session.resumedAt, isEmpty);
      expect(session.skipped, 0);
    });

    test('stopping retires a recovery still waiting', () {
      final session = _Session()..failOn('entry-0');

      session.recovery.reset();
      session.letTheDelayRunOut();

      expect(session.resumedAt, isEmpty);
      expect(session.recovery.consecutiveErrors, 0);
    });

    test('a failure outside the queue falls back to the ordinary skip', () {
      final session = _Session()
        ..failOn(null)
        ..letTheDelayRunOut();

      expect(session.skipped, 1);
      expect(session.resumedAt, isEmpty);
    });

    test('nothing to retry counts the failure and leaves the queue alone', () {
      final session = _Session(canRetry: false)
        ..failOn('entry-0')
        ..letTheDelayRunOut();

      expect(session.resumedAt, isEmpty);
      expect(session.skipped, 0);
      expect(session.recovery.consecutiveErrors, 1);
      expect(session.recovery.lastError, isNull);
    });

    test('failures in a row stop playback rather than grind on', () {
      final session = _Session(queue: longQueue)
        ..failOn('entry-0')
        ..letTheDelayRunOut()
        ..failOn('entry-1')
        ..letTheDelayRunOut();
      expect(session.resumedAt, [1, 2]);
      expect(session.stopped, 0);

      session
        ..failOn('entry-2')
        ..letTheDelayRunOut();
      expect(session.stopped, 1);
      expect(
        session.resumedAt,
        [1, 2],
        reason: 'stopping wins over a queue that has somewhere to go',
      );
    });

    test('a song starting clears the run of failures', () {
      final session = _Session(queue: longQueue)
        ..failOn('entry-0')
        ..letTheDelayRunOut()
        ..failOn('entry-1')
        ..letTheDelayRunOut();

      session.recovery.songStarted();

      session
        ..failOn('entry-2')
        ..letTheDelayRunOut();

      expect(session.stopped, 0);
      expect(session.resumedAt, [1, 2, 3]);
    });
  });
}

/// Drives [PlaybackFailureRecovery] the way the audio handler does, with the
/// retry delay in the test's hands rather than the clock's and the player
/// replaced by a record of what it was asked to do.
class _Session {
  _Session({List<String?>? queue, this.canRetry = true})
    : queue = queue ?? ['entry-0', 'entry-1', 'entry-2'] {
    recovery = PlaybackFailureRecovery(
      queueEntryIds: () => this.queue,
      onStop: () => stopped++,
      onSkipToNext: () => skipped++,
      onResumeAt: resumedAt.add,
      scheduler: (_, action) => _waiting.add(action),
    );
  }

  late final PlaybackFailureRecovery recovery;
  List<String?> queue;
  final bool canRetry;

  int stopped = 0;
  int skipped = 0;
  final List<int> resumedAt = [];

  /// The recoveries waiting out their delay, oldest first.
  final List<void Function()> _waiting = [];

  void failOn(String? entryId, {String error = 'boom'}) {
    recovery.lastError = error;
    recovery.report(canRetry: canRetry, failedEntryId: entryId);
  }

  /// The delay runs out: every recovery that was waiting fires.
  void letTheDelayRunOut() {
    final due = List.of(_waiting);
    _waiting.clear();
    for (final recovery in due) {
      recovery();
    }
  }

  void transitionStarted() => recovery.retirePending();
}
