/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:musify/utilities/app_utils.dart';

/// Runs [action] once [delay] is out. Named so that a test can drive the wait
/// instead of sitting through it.
typedef RecoveryScheduler =
    void Function(Duration delay, void Function() action);

/// Where the playback failures of a session are accounted for, and what is
/// done about them.
///
/// Apart from the audio handler so that the reasoning a failure goes through
/// can be exercised without a player: the same failure reported twice, a
/// queue that moved under a recovery still waiting, one failure too many.
class PlaybackFailureRecovery {
  PlaybackFailureRecovery({
    required this.queueEntryIds,
    required this.onStop,
    required this.onSkipToNext,
    required this.onResumeAt,
    void Function(String message, {Object? error})? log,
    RecoveryScheduler? scheduler,
    this.retryDelay = const Duration(seconds: 2),
    this.maxConsecutiveErrors = 3,
  }) : _log = log ?? _noLog,
       _scheduler = scheduler ?? _delayedScheduler;

  /// The queue as it stands, read when a recovery fires rather than when it
  /// is scheduled.
  final List<String?> Function() queueEntryIds;

  /// Playback gives up after [maxConsecutiveErrors] failures in a row.
  final void Function() onStop;

  /// A failure the queue cannot place: the ordinary skip handles it.
  final void Function() onSkipToNext;

  /// Pick the queue up at that position.
  final void Function(int index) onResumeAt;

  final void Function(String message, {Object? error}) _log;
  final RecoveryScheduler _scheduler;

  final Duration retryDelay;
  final int maxConsecutiveErrors;

  /// What the player last failed on, kept until the failure is accounted for:
  /// the player falling idle over an error still set is how a failure gets
  /// noticed when nothing else reported it.
  String? lastError;

  int _consecutiveErrors = 0;
  int get consecutiveErrors => _consecutiveErrors;

  /// The recovery waiting out [retryDelay], if any. Held as a token rather
  /// than a flag so that a transition started in the meantime can retire it:
  /// the queue it was going to resume may no longer be the one playing by the
  /// time it fires.
  int? _pendingToken;
  int _tokenCounter = 0;

  bool get isPending => _pendingToken != null;

  /// Accounts for a failure and acts on it.
  ///
  /// [failedEntryId] is the queue entry the song that failed was playing
  /// from, when the failure came from the queue at all. Recovery cannot just
  /// ask the queue for its next song: the index has by then been rolled back
  /// to where playback stood, so the next song is the one that just failed,
  /// and it would keep being it until the error count stopped playback
  /// altogether.
  void report({required bool canRetry, String? failedEntryId}) {
    final plan = planPlaybackRecovery(
      consecutiveErrors: _consecutiveErrors + 1,
      maxConsecutiveErrors: maxConsecutiveErrors,
      canRetry: canRetry,
      recoveryPending: isPending,
      cameFromQueue: failedEntryId != null,
    );

    if (plan == PlaybackRecovery.ignore) {
      // The same failure reaches here twice: once from the transition that
      // saw it, once from the player falling idle with lastError still set.
      // Letting the second one through would schedule a second recovery on
      // top of the first, and a blind skip back onto the failed song.
      _log('A recovery is already pending, ignoring the repeat report.');
      return;
    }

    _consecutiveErrors++;
    _log(
      'Playback error occurred. Consecutive errors: $_consecutiveErrors',
      error: lastError,
    );

    // Whatever happens next, the failure has been taken into account. Leaving
    // it set is what let the idle player report it all over again.
    lastError = null;

    switch (plan) {
      // ignore was dealt with above, it is only named here for exhaustiveness.
      case PlaybackRecovery.ignore:
      case PlaybackRecovery.standStill:
        return;
      case PlaybackRecovery.stop:
        _log('Max consecutive errors reached. Stopping playback.');
        onStop();
      case PlaybackRecovery.skipToNext:
        _schedule(onSkipToNext);
      case PlaybackRecovery.resumeAfterFailure:
        _schedule(() => _resumeAfter(failedEntryId!));
    }
  }

  /// A song started playing: the run of failures is over.
  void songStarted() {
    _consecutiveErrors = 0;
  }

  /// A transition began, so whatever recovery was waiting was aiming at a
  /// queue this transition is about to make obsolete.
  void retirePending() {
    _pendingToken = null;
  }

  /// Playback stopped, by the user or by this class giving up: nothing of the
  /// run of failures is worth carrying over, and a recovery still waiting
  /// would pull playback back up from under the stop.
  void reset() {
    lastError = null;
    _consecutiveErrors = 0;
    _pendingToken = null;
  }

  void _schedule(void Function() recovery) {
    final token = ++_tokenCounter;
    _pendingToken = token;

    _scheduler(retryDelay, () {
      if (_pendingToken != token) return;
      _pendingToken = null;
      recovery();
    });
  }

  /// Picks the queue up after the entry that failed, looking up where that
  /// entry sits *now*: the delay recovery waits out is long enough for the
  /// queue to be reordered, added to or replaced, and an index captured
  /// before it would by then point at another song.
  void _resumeAfter(String failedEntryId) {
    final resumeAt = queuePositionAfterFailure(queueEntryIds(), failedEntryId);

    if (resumeAt == null) {
      // Either the song that failed is no longer queued, or it was the last
      // one: nothing to step onto, so the queue is left where it stands
      // rather than wrapped around and played again.
      _log('Nothing left after the song that failed, staying put.');
      return;
    }

    onResumeAt(resumeAt);
  }

  static void _noLog(String message, {Object? error}) {}

  static void _delayedScheduler(Duration delay, void Function() action) {
    Future.delayed(delay, action);
  }
}
