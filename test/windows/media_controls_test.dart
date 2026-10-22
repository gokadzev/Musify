import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/windows_media_controls.dart';

const _channel = MethodChannel('musify/media_controls');

class _NavigationChanges extends ChangeNotifier {
  bool get observed => hasListeners;
}

class _Handler extends BaseAudioHandler {
  final commands = <String>[];

  @override
  Future<void> play() async => commands.add('play');
  @override
  Future<void> pause() async => commands.add('pause');
  @override
  Future<void> skipToNext() async => commands.add('next');
  @override
  Future<void> skipToPrevious() async => commands.add('previous');
  @override
  Future<void> stop() async => commands.add('stop');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _Handler handler;
  late WindowsMediaControls controls;
  late List<MethodCall> calls;
  late List<Object> errors;
  var failNextUpdate = false;
  var canNext = true;
  var canPrevious = true;
  late _NavigationChanges navigationChanges;

  Future<void> flush() => Future<void>.delayed(Duration.zero);
  Map<dynamic, dynamic> getUpdate() =>
      calls.lastWhere((call) => call.method == 'update').arguments as Map;
  Future<void> press(String button) async {
    final reply = Completer<void>();
    await messenger.handlePlatformMessage(
      _channel.name,
      _channel.codec.encodeMethodCall(MethodCall('button', button)),
      (_) => reply.complete(),
    );
    await reply.future;
  }

  setUp(() async {
    handler = _Handler();
    calls = [];
    errors = [];
    failNextUpdate = false;
    canNext = true;
    canPrevious = true;
    navigationChanges = _NavigationChanges();
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (call.method == 'update' && failNextUpdate) {
        failNextUpdate = false;
        throw PlatformException(code: 'smtc_error', message: 'Test failure');
      }
      return null;
    });
    controls = WindowsMediaControls(
      canGoNext: () => canNext,
      canGoPrevious: () => canPrevious,
      navigationChanges: navigationChanges,
      onError: (error, _) => errors.add(error),
    );
    await controls.start(handler);
    await flush();
  });

  tearDown(() async {
    await controls.dispose();
    navigationChanges.dispose();
    messenger.setMockMethodCallHandler(_channel, null);
  });

  void play({Uri? artwork}) {
    handler.mediaItem.add(
      MediaItem(
        id: 'track-1',
        title: 'Song',
        artist: 'Artist',
        artUri: artwork,
      ),
    );
    handler.playbackState.add(
      PlaybackState(processingState: AudioProcessingState.ready, playing: true),
    );
  }

  test('does not claim a system media session before playback', () {
    expect(calls.first.method, 'initialize');
    expect(getUpdate()['enabled'], false);
    expect(getUpdate()['status'], 'stopped');
  });

  test('publishes track info and artwork, including nullable album', () async {
    play(artwork: Uri.parse('https://example.com/cover.jpg'));
    await flush();
    expect(getUpdate(), {
      'enabled': true,
      'canGoNext': true,
      'canGoPrevious': true,
      'status': 'playing',
      'title': 'Song',
      'artist': 'Artist',
      'album': '',
      'artUri': 'https://example.com/cover.jpg',
      'artPath': '',
    });
    expect(errors, isEmpty);
  });

  test('queue edits refresh navigation while paused', () async {
    play();
    handler.playbackState.add(
      handler.playbackState.value.copyWith(playing: false),
    );
    await flush();
    canNext = false;
    canPrevious = false;
    handler.queue.add([]);
    await flush();
    expect(getUpdate()['status'], 'paused');
    expect(getUpdate()['canGoNext'], false);
    expect(getUpdate()['canGoPrevious'], false);
    await press('next');
    await press('previous');
    expect(handler.commands, isEmpty);
    canNext = true;
    handler.queue.add([const MediaItem(id: 'added', title: 'Added')]);
    await flush();
    expect(getUpdate()['canGoNext'], true);
    expect(getUpdate()['canGoPrevious'], false);
    await press('next');
    expect(handler.commands, ['next']);
  });

  test('settings refresh navigation without playback progress', () async {
    play();
    handler.playbackState.add(
      handler.playbackState.value.copyWith(playing: false),
    );
    await flush();
    canNext = false;
    navigationChanges.notifyListeners();
    await flush();
    expect(getUpdate()['canGoNext'], false);
    canNext = true;
    navigationChanges.notifyListeners();
    await flush();
    expect(getUpdate()['canGoNext'], true);
  });

  test('stale system clicks are checked against current navigation', () async {
    play();
    await flush();
    canNext = false;
    canPrevious = false;
    await press('next');
    await press('previous');
    expect(handler.commands, isEmpty);
  });

  test('passes a decoded Windows path for offline artwork', () async {
    play(artwork: Uri.parse('file:///C:/Music/Caf%C3%A9%20%2B/cover.jpg'));
    await flush();
    expect(getUpdate()['artPath'], r'C:\Music\Café +\cover.jpg');
    expect(getUpdate()['artUri'], '');
  });

  test(
    'routes every system transport button through the audio handler',
    () async {
      play();
      await flush();
      for (final button in ['play', 'pause', 'next', 'previous', 'stop']) {
        await press(button);
      }
      await press('unknown');
      expect(handler.commands, ['play', 'pause', 'next', 'previous', 'stop']);
    },
  );

  test(
    'keeps paused sessions available and ignores progress-only ticks',
    () async {
      play();
      await flush();
      final count = calls.length;
      handler.playbackState.add(
        handler.playbackState.value.copyWith(
          updatePosition: const Duration(seconds: 10),
        ),
      );
      await flush();
      expect(calls, hasLength(count));
      handler.playbackState.add(
        handler.playbackState.value.copyWith(playing: false),
      );
      await flush();
      expect(getUpdate()['enabled'], true);
      expect(getUpdate()['status'], 'paused');
      await press('play');
      expect(handler.commands, ['play']);
    },
  );

  for (final state in [
    AudioProcessingState.idle,
    AudioProcessingState.completed,
    AudioProcessingState.error,
  ]) {
    test(
      '$state releases the session even if the player reports playing',
      () async {
        play();
        await flush();
        handler.playbackState.add(
          PlaybackState(processingState: state, playing: true),
        );
        await flush();
        expect(getUpdate()['enabled'], false);
        expect(getUpdate()['canGoNext'], false);
        expect(getUpdate()['canGoPrevious'], false);
        expect(getUpdate()['status'], 'stopped');
        await press('next');
        expect(handler.commands, isEmpty);
      },
    );
  }

  test(
    'rapid track changes publish the latest metadata without stale artwork',
    () async {
      play(artwork: Uri.parse('https://example.com/old.jpg'));
      handler.mediaItem.add(const MediaItem(id: 'track-2', title: 'New song'));
      await flush();
      expect(getUpdate()['title'], 'New song');
      expect(getUpdate()['artUri'], '');
      handler.mediaItem.add(null);
      await flush();
      expect(getUpdate()['enabled'], false);
    },
  );

  test(
    'a native update failure is logged and later updates still work',
    () async {
      failNextUpdate = true;
      play();
      await flush();
      expect(errors, hasLength(1));
      handler.mediaItem.add(const MediaItem(id: 'track-2', title: 'Recovered'));
      await flush();
      expect(getUpdate()['title'], 'Recovered');
      expect(getUpdate()['enabled'], true);
    },
  );

  test(
    'disposal stops subscriptions and removes native button handling',
    () async {
      play();
      await flush();
      await controls.dispose();
      final count = calls.length;
      expect(navigationChanges.observed, false);
      navigationChanges.notifyListeners();
      handler.queue.add([]);
      handler.mediaItem.add(
        const MediaItem(id: 'track-2', title: 'After dispose'),
      );
      await flush();
      expect(calls, hasLength(count));
      expect(calls.last.method, 'dispose');
      await press('play');
      expect(handler.commands, isEmpty);
    },
  );
  test('resolved square artwork reaches Windows as a local file', () async {
    await controls.dispose();
    final square = Uri.file(r'C:\Musify\cover.png', windows: true);
    controls = WindowsMediaControls(
      canGoNext: () => canNext,
      canGoPrevious: () => canPrevious,
      navigationChanges: navigationChanges,
      onError: (error, _) => errors.add(error),
      resolveArtwork: (_) async => square,
    );
    await controls.start(handler);
    play(artwork: Uri.parse('https://example.com/wide.jpg'));
    await flush();
    expect(getUpdate()['artUri'], '');
    expect(getUpdate()['artPath'], r'C:\Musify\cover.png');
    expect(getUpdate()['title'], 'Song');
  });
}
