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

  // A head unit draws a tick on a row already listened to and a progress bar
  // on the one playing, from extras androidx.media defines. Without them the
  // whole queue looks like it is still waiting its turn.
  group('the marks a car draws on the queue rows', () {
    const statusKey = 'android.media.extra.PLAYBACK_STATUS';
    const percentageKey =
        'androidx.media.MediaItem.Extras.COMPLETION_PERCENTAGE';

    setUp(() {
      host.queue.addAll([
        _song(title: 'First'),
        _song(ytid: 'video-2', title: 'Second'),
        _song(ytid: 'video-3', title: 'Third'),
      ]);
    });

    test('what is behind is ticked, what is ahead is left alone', () async {
      host
        ..playbackIndex = 1
        ..playbackProgress = 0.25;

      final rows = await browser.children('current_queue');

      expect(rows[0].extras?[statusKey], 2, reason: 'played');
      expect(rows[1].extras?[statusKey], 1, reason: 'playing');
      expect(rows[2].extras?[statusKey], 0, reason: 'still to come');
    });

    test('the song playing carries how far into it playback is', () async {
      host
        ..playbackIndex = 1
        ..playbackProgress = 0.25;

      final rows = await browser.children('current_queue');

      expect(rows[1].extras?[percentageKey], 0.25);
      expect(rows[0].extras?.containsKey(percentageKey), isFalse);
      expect(rows[2].extras?.containsKey(percentageKey), isFalse);
    });

    test('an unknown duration still marks the song as being played', () async {
      host
        ..playbackIndex = 0
        ..playbackProgress = null;

      final rows = await browser.children('current_queue');

      expect(rows[0].extras?[statusKey], 1);
      expect(rows[0].extras?.containsKey(percentageKey), isFalse);
    });

    test('nothing playing leaves every row unmarked', () async {
      final rows = await browser.children('current_queue');

      for (final row in rows) {
        expect(row.extras?.containsKey(statusKey), isFalse);
      }
    });

    // Everywhere else is a library: what was played earlier says nothing
    // about the row, so marking it would only mislead.
    test('only the queue is marked, not the rest of the tree', () async {
      host
        ..playbackIndex = 1
        ..playbackProgress = 0.25;

      final rows = await browser.children('liked_songs');

      for (final row in rows) {
        expect(row.extras?.containsKey(statusKey), isFalse);
      }
    });
  });
}

Map<String, dynamic> _song({String ytid = 'video-1', String title = 'Song'}) => {
  'ytid': ytid,
  'id': ytid,
  'title': title,
  'artist': 'Artist',
  'highResImage': 'https://example.com/song.jpg',
  'lowResImage': 'https://example.com/song-small.jpg',
  'isLive': false,
};

class _FakeAndroidAutoHost implements AndroidAutoHost {
  final List<Map> queue = [];
  final Map<Object, String> _entryIds = {};
  MediaItem? preparedItem;

  /// Where playback stands, as the handler would report it.
  int playbackIndex = -1;
  double? playbackProgress;

  @override
  List<Map> get browserQueue => queue;

  @override
  Stream<List<MediaItem>> get browserQueueStream => const Stream.empty();

  @override
  Stream<void> get browserNowPlayingStream => const Stream.empty();

  @override
  ({int index, double? progress}) get browserPlaybackProgress =>
      (index: playbackIndex, progress: playbackProgress);

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
  String ensureBrowserQueueEntryId(Map song) =>
      _entryIds.putIfAbsent(song, () => 'entry-${_entryIds.length + 1}');

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
