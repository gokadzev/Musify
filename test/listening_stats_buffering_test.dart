import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/settings_manager.dart';

void main() {
  late Directory dir;
  late DateTime now;
  late ListeningStatsService stats;
  final song = {'ytid': 'track', 'title': 'Track', 'duration': 300};
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('zenify_stats_gaps');
    Hive.init(dir.path);
    await Hive.openBox('settings');
    await Hive.openBox('user');
    wrappedEnabled.value = true;
    now = DateTime(2026, 10, 29, 12);
    stats = ListeningStatsService(now: () => now);
  });
  tearDown(() async {
    await stats.flush();
    await Hive.close();
    await dir.delete(recursive: true);
  });
  int seconds() => stats.monthStats('2026-10')?['totalSeconds'] as int? ?? 0;
  void advance(int seconds) => now = now.add(Duration(seconds: seconds));
  void state(bool playing, ProcessingState processing) =>
      stats.handlePlayerStateForListeningStats(
        PlayerState(playing, processing),
        currentSong: song,
      );

  test(
    'buffering/loading never count, even at explicit playback checkpoints',
    () {
      stats.startListeningSession(song);
      state(true, ProcessingState.ready);
      advance(10);
      state(true, ProcessingState.buffering);
      expect(seconds(), 10);
      advance(100);
      stats.recordListeningSessionProgress(wasPlaying: true);
      expect(seconds(), 10);
      state(true, ProcessingState.loading);
      advance(20);
      stats.recordListeningSessionProgress(wasPlaying: true);
      expect(seconds(), 10);
      state(true, ProcessingState.ready);
      advance(5);
      state(false, ProcessingState.ready);
      expect(seconds(), 15);
      advance(60);
      stats.finishListeningSession(countCurrentTick: true, wasPlaying: true);
      expect(seconds(), 15);
    },
  );

  test(
    'a prepared paused source waits for actual playback before counting',
    () {
      stats.startListeningSession(song, isPlaying: false);
      advance(90);
      stats.recordListeningSessionProgress(wasPlaying: true);
      expect(seconds(), 0);
      state(true, ProcessingState.ready);
      advance(12);
      state(true, ProcessingState.completed);
      expect(seconds(), 12);
      advance(100);
      stats.finishListeningSession(countCurrentTick: true, wasPlaying: true);
      expect(seconds(), 12);
    },
  );

  test('a track already ready and playing when its session starts counts', () {
    final ready = PlayerState(true, ProcessingState.ready);
    // The ready event can arrive while the previous session is still active.
    state(ready.playing, ready.processingState);
    stats
      ..finishListeningSession(countCurrentTick: true)
      ..startListeningSession(
        song,
        isPlaying:
            ready.playing && ready.processingState == ProcessingState.ready,
      );
    advance(45);
    stats.recordListeningSessionProgress(wasPlaying: true);
    expect(seconds(), 45);
    expect(stats.monthStats('2026-10')!['songs']['track']['playCount'], 1);
  });
}
