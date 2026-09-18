import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/queue_persistence_service.dart';

/// Covers gokadzev/Musify#894: the queue and the point playback reached in it
/// have to survive the app being closed.
void main() {
  late Directory dir;

  List<Map<String, dynamic>> queueOf(int count) => [
    for (var i = 0; i < count; i++)
      {'ytid': 'song$i', 'title': 'Song $i', 'queueEntryId': 'entry-$i'},
  ];

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('musify_queue_test');
    Hive.init(dir.path);
    await Hive.openBox(QueuePersistenceService.storageCategory);
  });

  tearDown(() async {
    await QueuePersistenceService().clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('gives back the queue, the song and the position it was left at', () async {
    final saving = QueuePersistenceService()
      ..saveQueue(queueOf(3), const [], 1)
      ..savePosition(1, 'entry-1', const Duration(seconds: 42), force: true);
    await saving.flush();

    final restored = QueuePersistenceService().read();

    expect(restored, isNotNull);
    expect(restored!.queue.map((song) => song['ytid']), [
      'song0',
      'song1',
      'song2',
    ]);
    expect(restored.index, 1);
    expect(restored.position, const Duration(seconds: 42));
  });

  test('keeps the pre-shuffle order so shuffle can still be turned off', () async {
    final shuffled = queueOf(3).reversed.toList();
    final saving = QueuePersistenceService()..saveQueue(shuffled, queueOf(3), 0);
    await saving.flush();

    final restored = QueuePersistenceService().read();

    expect(restored!.queue.first['ytid'], 'song2');
    expect(restored.originalQueue.map((song) => song['ytid']), [
      'song0',
      'song1',
      'song2',
    ]);
  });

  test('drops a position that belongs to a song no longer under it', () async {
    final saving = QueuePersistenceService()
      ..saveQueue(queueOf(3), const [], 1)
      ..savePosition(1, 'entry-1', const Duration(seconds: 42), force: true);
    await saving.flush();

    // The song is removed in another session; the one now at index 1 never
    // played, so it has to start from its beginning.
    final shortened = queueOf(3)..removeAt(1);
    final resaving = QueuePersistenceService()..saveQueue(shortened, const [], 1);
    await resaving.flush();

    final restored = QueuePersistenceService().read();

    expect(restored!.queue.map((song) => song['ytid']), ['song0', 'song2']);
    expect(restored.index, 1);
    expect(restored.position, Duration.zero);
  });

  test('a restore followed by a save keeps the position it resumed at', () async {
    final saving = QueuePersistenceService()
      ..saveQueue(queueOf(3), const [], 2)
      ..savePosition(2, 'entry-2', const Duration(seconds: 30), force: true);
    await saving.flush();

    // What the audio handler does at launch: read the queue back, then publish
    // it, which saves again before anything is played.
    final service = QueuePersistenceService();
    final restored = service.read();
    service.saveQueue(queueOf(3), const [], restored!.index);
    await service.flush();

    expect(
      QueuePersistenceService().read()!.position,
      const Duration(seconds: 30),
    );
  });

  test('stores a window around the playing song of an oversized queue', () async {
    const size = QueuePersistenceService.maxStoredSongs + 500;
    final saving = QueuePersistenceService()..saveQueue(queueOf(size), const [], size - 1);
    await saving.flush();

    final restored = QueuePersistenceService().read();

    expect(restored!.queue.length, QueuePersistenceService.maxStoredSongs);
    expect(restored.queue.last['ytid'], 'song${size - 1}');
    expect(restored.queue[restored.index]['ytid'], 'song${size - 1}');
  });

  test('an emptied queue leaves nothing behind', () async {
    final saving = QueuePersistenceService()..saveQueue(queueOf(2), const [], 0);
    await saving.flush();

    final clearing = QueuePersistenceService()..saveQueue(const [], const [], 0);
    await clearing.flush();

    expect(QueuePersistenceService().read(), isNull);
  });
}
