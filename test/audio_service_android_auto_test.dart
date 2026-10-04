import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/audio_service_android_auto.dart';

void main() {
  late Directory temporaryDirectory;
  late _FakeAndroidAutoHost host;
  late AndroidAutoBrowser browser;

  setUpAll(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'musify_android_auto_test',
    );
    Hive.init(temporaryDirectory.path);
    await Hive.openBox('userNoBackup');
  });

  setUp(() {
    host = _FakeAndroidAutoHost();
    browser = AndroidAutoBrowser(host);
  });

  tearDownAll(() async {
    await Hive.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('browsable root exposes the expected categories', () async {
    final children = await browser.children(AudioService.browsableRootId);

    expect(children.map((item) => item.id), [
      'current_queue',
      'liked_songs',
      'playlists',
      'offline_songs',
      'recently_played',
    ]);
    expect(children.every((item) => item.playable == false), isTrue);
  });

  test('queue item media IDs resolve back to their song', () async {
    host.queue.add(_song());

    final queueItems = await browser.children('current_queue');
    expect(queueItems, hasLength(1));
    expect(queueItems.single.id, 'song:current_queue:entry-1');
    expect(queueItems.single.playable, isTrue);

    final resolved = await browser.mediaItemForId(queueItems.single.id);
    expect(resolved?.id, 'song:current_queue:entry-1');
    expect(resolved?.title, 'Song');
  });

  test('prepareFromId publishes the resolved item through the host', () async {
    host.queue.add(_song());

    await browser.prepareFromId('song:current_queue:entry-1');

    expect(host.preparedItem?.id, 'song:current_queue:entry-1');
    expect(host.preparedItem?.title, 'Song');
  });
}

Map<String, dynamic> _song() => {
  'ytid': 'video-1',
  'id': 'video-1',
  'title': 'Song',
  'artist': 'Artist',
  'highResImage': 'https://example.com/song.jpg',
  'lowResImage': 'https://example.com/song-small.jpg',
  'isLive': false,
};

class _FakeAndroidAutoHost implements AndroidAutoHost {
  final List<Map> queue = [];
  MediaItem? preparedItem;

  @override
  List<Map> get browserQueue => queue;

  @override
  Stream<List<MediaItem>> get browserQueueStream => const Stream.empty();

  @override
  Map? latestResumableSong() => queue.isEmpty ? null : queue.first;

  @override
  Map<String, dynamic>? normaliseResumableSong(Map song) {
    final ytid = song['ytid']?.toString();
    if (ytid == null || ytid.isEmpty) return null;
    return {
      ...Map<String, dynamic>.from(song),
      'id': ytid,
      'ytid': ytid,
      'highResImage': song['highResImage'] ?? song['lowResImage'] ?? '',
      'lowResImage': song['lowResImage'] ?? song['highResImage'] ?? '',
      'isLive': song['isLive'] ?? false,
    };
  }

  @override
  Future<void> playResumableSong(Map song) =>
      playBrowserPlaylist([song], songIndex: 0);

  @override
  String ensureBrowserQueueEntryId(Map song) => 'entry-1';

  @override
  void logBrowserError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  Future<void> resumeAudio() async {}

  @override
  Future<void> skipToQueueItem(int index) async {}

  @override
  Future<void> playBrowserPlaylist(
    List<Map> songs, {
    required int songIndex,
  }) async {}

  @override
  void publishPreparedBrowserItem(MediaItem item) {
    preparedItem = item;
  }
}
