import 'dart:isolate';

import 'package:audio_service/audio_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

Isolate? isolate;

class Data {
  static final playbackState = PlaybackState(
    processingState: AudioProcessingState.buffering,
    playing: true,
    controls: [MediaControl.pause],
    androidCompactActionIndices: [0],
    systemActions: {MediaAction.seek},
    updatePosition: const Duration(seconds: 30),
    bufferedPosition: const Duration(seconds: 35),
    speed: 1.5,
    updateTime: DateTime.now(),
    errorCode: 3,
    errorMessage: 'error message',
    repeatMode: AudioServiceRepeatMode.all,
    shuffleMode: AudioServiceShuffleMode.all,
    captioningEnabled: true,
    queueIndex: 0,
  );
  static final playbackStates = [
    PlaybackState(playing: true),
    PlaybackState(processingState: AudioProcessingState.buffering),
    PlaybackState(speed: 1.5),
  ];
  static const query = 'query';
  static final uri = Uri.parse('https://example.com/foo');
  static const mediaId = '1';
  static const mediaItem = MediaItem(id: '1', title: 'title1');
  static final mediaItems = [
    const MediaItem(id: '1', title: 'title1'),
    const MediaItem(id: '2', title: 'title2'),
    const MediaItem(id: '3', title: 'title3'),
  ];
  static final remotePlaybackInfo = RemoteAndroidPlaybackInfo(
    volumeControlType: AndroidVolumeControlType.absolute,
    maxVolume: 10,
    volume: 5,
  );
}

void main() {
  group('isolates', () {
    late AudioHandler proxy;

    late bool spawningIsolate;

    setUp(() async {
      if (spawningIsolate) {
        await runIsolateHandler();
      } else {
        IsolatedAudioHandler(_MockAudioHandler());
      }
      proxy = await IsolatedAudioHandler.lookup();
    });

    tearDown(() async {
      await proxy.unregister();
      if (spawningIsolate) {
        await killIsolate();
      }
    });

    // We need to run the tests not only in different isolates but also in the
    // same isolate since coverage is only collected by the main isolate:
    // https://github.com/dart-lang/test/issues/1108
    for (var differentIsolate in [true, false]) {
      spawningIsolate = differentIsolate;
      final isolateLabel =
          differentIsolate ? ' (different isolate)' : ' (same isolate)';

      test('init $isolateLabel', () async {
        final playbackState = await proxy.playbackState.first;
        fakeAsync((async) {
          // ignore the updateTime
          expect(playbackState.copyWith(), PlaybackState());
        });
        expect(await proxy.queue.first, const <MediaItem>[]);
        expect(await proxy.queueTitle.first, '');
        expect(await proxy.mediaItem.first, null);
        expect(proxy.ratingStyle.hasValue, false);
        expect(proxy.androidPlaybackInfo.hasValue, false);
        expect(proxy.customState.hasValue, false);
      });

      test('method invocations $isolateLabel', () async {
        Future<void> testMethod(String method, dynamic Function() function,
            {dynamic expectedResult}) async {
          final startCount = await proxy.count(method);
          final dynamic result = await function();
          expect(await proxy.count(method), startCount + 1);
          if (expectedResult != null) {
            expect(result, expectedResult);
          }
        }

        await testMethod('prepare', () => proxy.prepare());
        await testMethod('prepareFromMediaId',
            () => proxy.prepareFromMediaId('1', <String, dynamic>{}));
        await testMethod('prepareFromSearch',
            () => proxy.prepareFromSearch(Data.query, <String, dynamic>{}));
        await testMethod('prepareFromUri',
            () => proxy.prepareFromUri(Data.uri, <String, dynamic>{}));
        await testMethod('play', () => proxy.play());
        await testMethod('playFromMediaId',
            () => proxy.playFromMediaId(Data.mediaId, <String, dynamic>{}));
        await testMethod('playFromSearch',
            () => proxy.playFromSearch(Data.query, <String, dynamic>{}));
        await testMethod('playFromUri',
            () => proxy.playFromUri(Data.uri, <String, dynamic>{}));
        await testMethod(
            'playMediaItem', () => proxy.playMediaItem(Data.mediaItem));
        await testMethod('pause', () => proxy.pause());
        await testMethod('click', () => proxy.click());
        await testMethod('stop', () => proxy.stop());
        await testMethod(
            'addQueueItem', () => proxy.addQueueItem(Data.mediaItem));
        await testMethod(
            'addQueueItems', () => proxy.addQueueItems(Data.mediaItems));
        await testMethod(
            'insertQueueItem', () => proxy.insertQueueItem(0, Data.mediaItem));
        await testMethod(
            'updateQueue', () => proxy.updateQueue(Data.mediaItems));
        await testMethod(
            'updateMediaItem', () => proxy.updateMediaItem(Data.mediaItem));
        await testMethod(
            'removeQueueItem', () => proxy.removeQueueItem(Data.mediaItem));
        await testMethod('removeQueueItemAt', () => proxy.removeQueueItemAt(0));
        await testMethod('skipToNext', () => proxy.skipToNext());
        await testMethod('skipToPrevious', () => proxy.skipToPrevious());
        await testMethod('fastForward', () => proxy.fastForward());
        await testMethod('rewind', () => proxy.rewind());
        await testMethod('skipToQueueItem', () => proxy.skipToQueueItem(0));
        await testMethod('seek', () => proxy.seek(Duration.zero));
        await testMethod(
            'setRating',
            () => proxy.setRating(
                const Rating.newHeartRating(true), <String, dynamic>{}));
        await testMethod(
            'setCaptioningEnabled', () => proxy.setCaptioningEnabled(true));
        await testMethod('setRepeatMode',
            () => proxy.setRepeatMode(AudioServiceRepeatMode.all));
        await testMethod('setShuffleMode',
            () => proxy.setShuffleMode(AudioServiceShuffleMode.all));
        await testMethod('seekBackward', () => proxy.seekBackward(true));
        await testMethod('seekForward', () => proxy.seekForward(true));
        await testMethod('setSpeed', () => proxy.setSpeed(1.5));
        await testMethod('onTaskRemoved', () => proxy.onTaskRemoved());
        await testMethod(
            'onNotificationDeleted', () => proxy.onNotificationDeleted());
        await testMethod('getChildren',
            () => proxy.getChildren(Data.mediaId, <String, dynamic>{}),
            expectedResult: Data.mediaItems);
        await testMethod('subscribeToChildren',
            () => proxy.subscribeToChildren(Data.mediaId));
        await testMethod('getMediaItem', () => proxy.getMediaItem(Data.mediaId),
            expectedResult: Data.mediaItem);
        await testMethod(
            'search', () => proxy.search(Data.query, <String, dynamic>{}),
            expectedResult: Data.mediaItems);
        await testMethod(
            'androidSetRemoteVolume', () => proxy.androidSetRemoteVolume(3));
        await testMethod(
            'androidAdjustRemoteVolume',
            () =>
                proxy.androidAdjustRemoteVolume(AndroidVolumeDirection.raise));
        await testMethod('customAction',
            () => proxy.customAction('echo', <String, dynamic>{'arg': 'foo'}),
            expectedResult: 'foo');
        await testMethod('customAction',
            () => proxy.customAction('echo', <String, dynamic>{'arg': 'bar'}),
            expectedResult: 'bar');
      });

      test('stream values $isolateLabel', () async {
        Future<void> testStream<T>(
            String name, ValueStream<T> stream, T value) async {
          await proxy.add(name, value);
          expect(stream.nvalue, value);
        }

        await testStream(
            'playbackState', proxy.playbackState, Data.playbackState);
        await testStream('queue', proxy.queue, Data.mediaItems);
        await testStream('queueTitle', proxy.queueTitle, 'Queue');
        await testStream('androidPlaybackInfo', proxy.androidPlaybackInfo,
            Data.remotePlaybackInfo);
        await testStream('ratingStyle', proxy.ratingStyle, RatingStyle.heart);
        await testStream<dynamic>('customState', proxy.customState, 'foo');
      });

      test('streams $isolateLabel', () async {
        Future<void> testStream<T>(String name, Stream<T> stream,
            bool skipFirst, List<T> values) async {
          final actualValues = <T>[];
          final subscription =
              stream.skip(skipFirst ? 1 : 0).listen(actualValues.add);
          for (var value in values) {
            await proxy.add(name, value);
          }
          expect(actualValues, values);
          subscription.cancel();
        }

        await testStream(
            'playbackState', proxy.playbackState, true, Data.playbackStates);
        await testStream('queue', proxy.queue, true, [
          Data.mediaItems,
          Data.mediaItems
              .map((item) =>
                  item.copyWith(displayDescription: '${item.id} description'))
              .toList(),
        ]);
        await testStream('queueTitle', proxy.queueTitle, true, ['a', 'b', 'c']);
        await testStream('mediaItem', proxy.mediaItem, true, Data.mediaItems);
        await testStream(
            'androidPlaybackInfo', proxy.androidPlaybackInfo, false, [
          Data.remotePlaybackInfo,
          LocalAndroidPlaybackInfo(),
        ]);
        await testStream('ratingStyle', proxy.ratingStyle, false, [
          RatingStyle.heart,
          RatingStyle.percentage,
        ]);
        await testStream<dynamic>(
            'customEvent', proxy.customEvent, false, <dynamic>[
          'a',
          'b',
          'c',
        ]);
        await testStream<dynamic>(
            'customState', proxy.customState, false, <dynamic>[
          'a',
          'b',
          'c',
        ]);
      });
    }
  });
}

Future<void> runIsolateHandler() async {
  final receivePort = ReceivePort();
  isolate = await Isolate.spawn(isolateEntryPoint, receivePort.sendPort);
  final success = (await receivePort.first) as bool;
  assert(success);
}

Future<void> killIsolate() async {
  isolate!.kill();
  isolate = null;
}

void isolateEntryPoint(SendPort sendPort) {
  IsolatedAudioHandler(_MockAudioHandler());
  sendPort.send(true);
}

class _MockAudioHandler implements BaseAudioHandler {
  @override
  // ignore: close_sinks
  final BehaviorSubject<PlaybackState> playbackState =
      BehaviorSubject.seeded(PlaybackState());

  @override
  final BehaviorSubject<List<MediaItem>> queue =
      BehaviorSubject.seeded(<MediaItem>[]);

  @override
  // ignore: close_sinks
  final BehaviorSubject<String> queueTitle = BehaviorSubject.seeded('');

  @override
  // ignore: close_sinks
  final BehaviorSubject<MediaItem?> mediaItem = BehaviorSubject.seeded(null);

  @override
  // ignore: close_sinks
  final BehaviorSubject<AndroidPlaybackInfo> androidPlaybackInfo =
      BehaviorSubject();

  @override
  // ignore: close_sinks
  final BehaviorSubject<RatingStyle> ratingStyle = BehaviorSubject();

  @override
  // ignore: close_sinks
  final PublishSubject<dynamic> customEvent = PublishSubject<dynamic>();

  @override
  // ignore: close_sinks
  final BehaviorSubject<dynamic> customState = BehaviorSubject<dynamic>();

  final Map<String, int> invocationCounts = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final member = invocation.memberName.toString().split('"')[1];
    if (invocation.isMethod) {
      if (member != 'customAction' ||
          invocation.positionalArguments[0] != 'count') {
        // count invocations of everything except for 'count' itself.
        invocationCounts[member] = (invocationCounts[member] ?? 0) + 1;
      }
      switch (member) {
        case 'customAction':
          return _handleCustomAction(invocation);
        case 'getChildren':
        case 'search':
          return Future.value(Data.mediaItems);
        case 'subscribeToChildren':
          return BehaviorSubject.seeded(<String, dynamic>{});
        case 'getMediaItem':
          return Future.value(Data.mediaItem);
        default:
          return Future.value(null);
      }
    }
    return super.noSuchMethod(invocation);
  }

  Future<dynamic> _handleCustomAction(Invocation invocation) async {
    final args = invocation.positionalArguments;
    final name = args[0] as String;
    final extras = args[1] as Map<String, dynamic>?;
    switch (name) {
      case 'count':
        final method = extras!['method'] as String;
        return invocationCounts[method] ?? 0;
      case 'echo':
        return extras!['arg'] as String;
      case 'add':
        final streamName = extras!['stream'] as String;
        final dynamic arg = extras['arg'];
        <String, Subject>{
          'playbackState': playbackState,
          'queue': queue,
          'queueTitle': queueTitle,
          'mediaItem': mediaItem,
          'androidPlaybackInfo': androidPlaybackInfo,
          'ratingStyle': ratingStyle,
          'customEvent': customEvent,
          'customState': customState,
        }[streamName]!
            .add(arg);
        break;
    }
  }
}

extension AudioHandlerExtension on AudioHandler {
  Future<int> count(String method) async =>
      (await customAction('count', <String, dynamic>{'method': method}) as int);

  Future<String> echo(String arg) async =>
      (await customAction('echo', <String, dynamic>{'arg': arg}) as String);

  Future<void> add(String stream, dynamic arg) =>
      customAction('add', <String, dynamic>{'stream': stream, 'arg': arg});

  Future<void> unregister() => customAction('unregister');
}

/// Backwards compatible extensions on rxdart's ValueStream
extension _ValueStreamExtension<T> on ValueStream<T> {
  /// Backwards compatible version of valueOrNull.
  T? get nvalue => hasValue ? value : null;
}
