import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';
import 'package:audio_service_platform_interface/method_channel_audio_service.dart';

import 'method_channel_audio_service_test.mocks.dart';
import 'method_channel_mock.dart';
import 'stubs.dart';

class MockMethodChannelAudioService extends MethodChannelAudioService
    implements MockPlatformInterfaceMixin {
  @override
  void setHandlerCallbacks(AudioHandlerCallbacks callbacks) {
    handlerChannel.setMockMethodCallHandler((call) async {
      return handlerCallbacksCallHandler(callbacks, call);
    });
  }
}

@GenerateMocks([AudioHandlerCallbacks])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sendClientChannel = MockMethodChannel(
    channelName: 'com.ryanheise.audio_service.client.methods',
  );
  final sendHandlerChannel = MockMethodChannel(
    channelName: 'com.ryanheise.audio_service.handler.methods',
  );

  final platform = MockMethodChannelAudioService();
  final handlerChannel = platform.handlerChannel;
  late MockAudioHandlerCallbacks callbacks;

  setUp(() {
    callbacks = MockAudioHandlerCallbacks();
    platform.setHandlerCallbacks(callbacks);
  });

  group('Client channel $asciiSquare to native $asciiSquare', () {
    test('configure', () async {
      final request = ConfigureRequest(config: AudioServiceConfigMessage());
      final methods = {'configure': null};
      final channel = sendClientChannel.copyWith(methods);
      await platform.configure(request);
      expect(channel.log, [
        isMethodCall(
          'configure',
          arguments: request.toMap(),
        )
      ]);
    });
  });

  group('Handler channel $asciiSquare to native $asciiSquare', () {
    test('setState', () async {
      final request = SetStateRequest(state: PlaybackStateMessage());
      final methods = {'setState': null};
      final channel = sendHandlerChannel.copyWith(methods);
      await platform.setState(request);
      expect(channel.log, [
        isMethodCall(
          'setState',
          arguments: request.toMap(),
        )
      ]);
    });

    test('setQueue', () async {
      const request = SetQueueRequest(queue: Stubs.queue);
      final methods = {'setQueue': null};
      final channel = sendHandlerChannel.copyWith(methods);
      await platform.setQueue(request);
      expect(channel.log, [
        isMethodCall(
          'setQueue',
          arguments: request.toMap(),
        )
      ]);
    });

    test('setMediaItem', () async {
      const request = SetMediaItemRequest(mediaItem: Stubs.mediaItem);
      final methods = {'setMediaItem': null};
      final channel = sendHandlerChannel.copyWith(methods);
      await platform.setMediaItem(request);
      expect(channel.log, [
        isMethodCall(
          'setMediaItem',
          arguments: request.toMap(),
        )
      ]);
    });

    test('stopService', () async {
      const request = StopServiceRequest();
      final methods = {'stopService': null};
      final channel = sendHandlerChannel.copyWith(methods);
      await platform.stopService(request);
      expect(channel.log, [
        isMethodCall(
          'stopService',
          arguments: request.toMap(),
        )
      ]);
    });

    test('androidForceEnableMediaButtons', () async {
      const request = AndroidForceEnableMediaButtonsRequest();
      final methods = {'androidForceEnableMediaButtons': null};
      final channel = sendHandlerChannel.copyWith(methods);
      await platform.androidForceEnableMediaButtons(request);
      expect(channel.log, [
        isMethodCall(
          'androidForceEnableMediaButtons',
          arguments: request.toMap(),
        )
      ]);
    });

    test('notifyChildrenChanged', () async {
      const request = NotifyChildrenChangedRequest(
        parentMediaId: Stubs.parentMediaId,
        options: Stubs.map,
      );
      final methods = {'notifyChildrenChanged': null};
      final channel = sendHandlerChannel.copyWith(methods);
      await platform.notifyChildrenChanged(request);
      expect(channel.log, [
        isMethodCall(
          'notifyChildrenChanged',
          arguments: request.toMap(),
        )
      ]);
    });

    test('local setAndroidPlaybackInfo', () async {
      const request = SetAndroidPlaybackInfoRequest(
        playbackInfo: LocalAndroidPlaybackInfoMessage(),
      );
      final methods = {'setAndroidPlaybackInfo': null};
      final channel = sendHandlerChannel.copyWith(methods);
      await platform.setAndroidPlaybackInfo(request);
      expect(channel.log, [
        isMethodCall(
          'setAndroidPlaybackInfo',
          arguments: request.toMap(),
        )
      ]);
    });

    test('remote setAndroidPlaybackInfo', () async {
      const request = SetAndroidPlaybackInfoRequest(
        playbackInfo: RemoteAndroidPlaybackInfoMessage(
          volumeControlType: AndroidVolumeControlTypeMessage.absolute,
          maxVolume: 100,
          volume: 0,
        ),
      );
      final methods = {'setAndroidPlaybackInfo': null};
      final channel = sendHandlerChannel.copyWith(methods);
      await platform.setAndroidPlaybackInfo(request);
      expect(channel.log, [
        isMethodCall(
          'setAndroidPlaybackInfo',
          arguments: request.toMap(),
        )
      ]);
    });
  });

  group('Handler $asciiSquare to dart $asciiSquare', () {
    test('prepare', () async {
      const request = PrepareRequest();
      await handlerChannel.invokeMethod<void>('prepare', request.toMap());
      final captured = verify(callbacks.prepare(captureAny)).captured.first
          as PrepareRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('prepareFromMediaId', () async {
      const request = PrepareFromMediaIdRequest(mediaId: Stubs.mediaId);
      await handlerChannel.invokeMethod<void>(
          'prepareFromMediaId', request.toMap());
      final captured = verify(callbacks.prepareFromMediaId(captureAny))
          .captured
          .first as PrepareFromMediaIdRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('prepareFromSearch', () async {
      const request = PrepareFromSearchRequest(query: Stubs.searchQuery);
      await handlerChannel.invokeMethod<void>(
          'prepareFromSearch', request.toMap());
      final captured = verify(callbacks.prepareFromSearch(captureAny))
          .captured
          .first as PrepareFromSearchRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('prepareFromUri', () async {
      final request = PrepareFromUriRequest(
        uri: Stubs.uri,
        extras: Stubs.map,
      );
      await handlerChannel.invokeMethod<void>(
          'prepareFromUri', request.toMap());
      final captured = verify(callbacks.prepareFromUri(captureAny))
          .captured
          .first as PrepareFromUriRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('play', () async {
      const request = PlayRequest();
      await handlerChannel.invokeMethod<void>('play', request.toMap());
      final captured =
          verify(callbacks.play(captureAny)).captured.first as PlayRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('playFromMediaId', () async {
      const request = PlayFromMediaIdRequest(
        mediaId: Stubs.mediaId,
        extras: Stubs.map,
      );
      await handlerChannel.invokeMethod<void>(
          'playFromMediaId', request.toMap());
      final captured = verify(callbacks.playFromMediaId(captureAny))
          .captured
          .first as PlayFromMediaIdRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('playFromSearch', () async {
      const request = PlayFromSearchRequest(
        query: Stubs.searchQuery,
        extras: Stubs.map,
      );
      await handlerChannel.invokeMethod<void>(
          'playFromSearch', request.toMap());
      final captured = verify(callbacks.playFromSearch(captureAny))
          .captured
          .first as PlayFromSearchRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('playFromUri', () async {
      final request = PlayFromUriRequest(
        uri: Stubs.uri,
        extras: Stubs.map,
      );
      await handlerChannel.invokeMethod<void>('playFromUri', request.toMap());
      final captured = verify(callbacks.playFromUri(captureAny)).captured.first
          as PlayFromUriRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('playMediaItem', () async {
      const request = PlayMediaItemRequest(
        mediaItem: Stubs.mediaItem,
      );
      await handlerChannel.invokeMethod<void>('playMediaItem', request.toMap());
      final captured = verify(callbacks.playMediaItem(captureAny))
          .captured
          .first as PlayMediaItemRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('pause', () async {
      const request = PauseRequest();
      await handlerChannel.invokeMethod<void>('pause', request.toMap());
      final captured =
          verify(callbacks.pause(captureAny)).captured.first as PauseRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('click', () async {
      const request = ClickRequest(
        button: MediaButtonMessage.media,
      );
      await handlerChannel.invokeMethod<void>('click', request.toMap());
      final captured =
          verify(callbacks.click(captureAny)).captured.first as ClickRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('stop', () async {
      const request = StopRequest();
      await handlerChannel.invokeMethod<void>('stop', request.toMap());
      final captured =
          verify(callbacks.stop(captureAny)).captured.first as StopRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('addQueueItem', () async {
      const request = AddQueueItemRequest(
        mediaItem: Stubs.mediaItem,
      );
      await handlerChannel.invokeMethod<void>('addQueueItem', request.toMap());
      final captured = verify(callbacks.addQueueItem(captureAny)).captured.first
          as AddQueueItemRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('insertQueueItem', () async {
      const request = InsertQueueItemRequest(
        mediaItem: Stubs.mediaItem,
        index: Stubs.index,
      );
      await handlerChannel.invokeMethod<void>(
          'insertQueueItem', request.toMap());
      final captured = verify(callbacks.insertQueueItem(captureAny))
          .captured
          .first as InsertQueueItemRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('removeQueueItem', () async {
      const request = RemoveQueueItemRequest(
        mediaItem: Stubs.mediaItem,
      );
      await handlerChannel.invokeMethod<void>(
          'removeQueueItem', request.toMap());
      final captured = verify(callbacks.removeQueueItem(captureAny))
          .captured
          .first as RemoveQueueItemRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('removeQueueItemAt', () async {
      const request = RemoveQueueItemAtRequest(
        index: Stubs.index,
      );
      await handlerChannel.invokeMethod<void>(
          'removeQueueItemAt', request.toMap());
      final captured = verify(callbacks.removeQueueItemAt(captureAny))
          .captured
          .first as RemoveQueueItemAtRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('skipToNext', () async {
      const request = SkipToNextRequest();
      await handlerChannel.invokeMethod<void>('skipToNext', request.toMap());
      final captured = verify(callbacks.skipToNext(captureAny)).captured.first
          as SkipToNextRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('skipToPrevious', () async {
      const request = SkipToPreviousRequest();
      await handlerChannel.invokeMethod<void>(
          'skipToPrevious', request.toMap());
      final captured = verify(callbacks.skipToPrevious(captureAny))
          .captured
          .first as SkipToPreviousRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('fastForward', () async {
      const request = FastForwardRequest();
      await handlerChannel.invokeMethod<void>('fastForward', request.toMap());
      final captured = verify(callbacks.fastForward(captureAny)).captured.first
          as FastForwardRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('rewind', () async {
      const request = RewindRequest();
      await handlerChannel.invokeMethod<void>('rewind', request.toMap());
      final captured =
          verify(callbacks.rewind(captureAny)).captured.first as RewindRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('skipToQueueItem', () async {
      const request = SkipToQueueItemRequest(index: Stubs.index);
      await handlerChannel.invokeMethod<void>(
          'skipToQueueItem', request.toMap());
      final captured = verify(callbacks.skipToQueueItem(captureAny))
          .captured
          .first as SkipToQueueItemRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('seek', () async {
      const request = SeekRequest(position: Duration.zero);
      await handlerChannel.invokeMethod<void>('seek', request.toMap());
      final captured =
          verify(callbacks.seek(captureAny)).captured.first as SeekRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('setRating', () async {
      const request = SetRatingRequest(
        rating: RatingMessage(
          type: RatingStyleMessage.heart,
          value: false,
        ),
      );
      await handlerChannel.invokeMethod<void>('setRating', request.toMap());
      final captured = verify(callbacks.setRating(captureAny)).captured.first
          as SetRatingRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('setCaptioningEnabled', () async {
      const request = SetCaptioningEnabledRequest(
        enabled: false,
      );
      await handlerChannel.invokeMethod<void>(
          'setCaptioningEnabled', request.toMap());
      final captured = verify(callbacks.setCaptioningEnabled(captureAny))
          .captured
          .first as SetCaptioningEnabledRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('setRepeatMode', () async {
      const request = SetRepeatModeRequest(
        repeatMode: AudioServiceRepeatModeMessage.one,
      );
      await handlerChannel.invokeMethod<void>('setRepeatMode', request.toMap());
      final captured = verify(callbacks.setRepeatMode(captureAny))
          .captured
          .first as SetRepeatModeRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('setShuffleMode', () async {
      const request = SetShuffleModeRequest(
        shuffleMode: AudioServiceShuffleModeMessage.all,
      );
      await handlerChannel.invokeMethod<void>(
          'setShuffleMode', request.toMap());
      final captured = verify(callbacks.setShuffleMode(captureAny))
          .captured
          .first as SetShuffleModeRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('seekBackward', () async {
      const request = SeekBackwardRequest(begin: true);
      await handlerChannel.invokeMethod<void>('seekBackward', request.toMap());
      final captured = verify(callbacks.seekBackward(captureAny)).captured.first
          as SeekBackwardRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('seekForward', () async {
      const request = SeekForwardRequest(begin: true);
      await handlerChannel.invokeMethod<void>('seekForward', request.toMap());
      final captured = verify(callbacks.seekForward(captureAny)).captured.first
          as SeekForwardRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('setSpeed', () async {
      const request = SetSpeedRequest(speed: 1.0);
      await handlerChannel.invokeMethod<void>('setSpeed', request.toMap());
      final captured = verify(callbacks.setSpeed(captureAny)).captured.first
          as SetSpeedRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('customAction', () async {
      const request = CustomActionRequest(
        name: 'name',
        extras: Stubs.map,
      );
      when(callbacks.customAction(captureAny))
          .thenAnswer((_) => Future<void>.value());
      await handlerChannel.invokeMethod<void>('customAction', request.toMap());
      final captured = verify(callbacks.customAction(captureAny)).captured.first
          as CustomActionRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('onTaskRemoved', () async {
      const request = OnTaskRemovedRequest();
      await handlerChannel.invokeMethod<void>('onTaskRemoved', request.toMap());
      final captured = verify(callbacks.onTaskRemoved(captureAny))
          .captured
          .first as OnTaskRemovedRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('onNotificationDeleted', () async {
      const request = OnNotificationDeletedRequest();
      await handlerChannel.invokeMethod<void>(
          'onNotificationDeleted', request.toMap());
      final captured = verify(callbacks.onNotificationDeleted(captureAny))
          .captured
          .first as OnNotificationDeletedRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('onNotificationClicked', () async {
      for (var clicked in [true, false]) {
        final request = OnNotificationClickedRequest(clicked: clicked);
        await handlerChannel.invokeMethod<void>(
            'onNotificationClicked', request.toMap());
        final captured = verify(callbacks.onNotificationClicked(captureAny))
            .captured
            .first as OnNotificationClickedRequest;
        expect(
          captured.toMap(),
          equals(request.toMap()),
        );
      }
    });

    test('getChildren', () async {
      const request = GetChildrenRequest(
        parentMediaId: Stubs.parentMediaId,
        options: Stubs.map,
      );
      const response = GetChildrenResponse(
        children: Stubs.queue,
      );
      when(callbacks.getChildren(any))
          .thenAnswer((_) => SynchronousFuture(response));
      final result = await handlerChannel.invokeMapMethod<String, dynamic>(
        'getChildren',
        request.toMap(),
      );
      expect(
        result,
        equals(response.toMap()),
      );
    });

    test('getMediaItem', () async {
      const request = GetMediaItemRequest(mediaId: Stubs.mediaId);
      const response = GetMediaItemResponse(mediaItem: Stubs.mediaItem);
      when(callbacks.getMediaItem(any))
          .thenAnswer((_) => SynchronousFuture(response));
      final result = await handlerChannel.invokeMapMethod<String, dynamic>(
        'getMediaItem',
        request.toMap(),
      );
      expect(
        result,
        equals(response.toMap()),
      );
    });

    test('search', () async {
      const request = SearchRequest(
        query: Stubs.searchQuery,
        extras: Stubs.map,
      );
      const response = SearchResponse(mediaItems: Stubs.queue);
      when(callbacks.search(any))
          .thenAnswer((_) => SynchronousFuture(response));
      final result = await handlerChannel.invokeMapMethod<String, dynamic>(
        'search',
        request.toMap(),
      );
      expect(
        result,
        equals(response.toMap()),
      );
    });

    test('androidSetRemoteVolume', () async {
      const request = AndroidSetRemoteVolumeRequest(volumeIndex: 0);
      await handlerChannel.invokeMethod<void>(
          'androidSetRemoteVolume', request.toMap());
      final captured = verify(callbacks.androidSetRemoteVolume(captureAny))
          .captured
          .first as AndroidSetRemoteVolumeRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('androidAdjustRemoteVolume', () async {
      const request = AndroidAdjustRemoteVolumeRequest(
          direction: AndroidVolumeDirectionMessage.lower);
      await handlerChannel.invokeMethod<void>(
          'androidAdjustRemoteVolume', request.toMap());
      final captured = verify(callbacks.androidAdjustRemoteVolume(captureAny))
          .captured
          .first as AndroidAdjustRemoteVolumeRequest;
      expect(
        captured.toMap(),
        equals(request.toMap()),
      );
    });

    test('unimplemented error is thrown on unknown method call', () {
      expect(
        () => handlerChannel.invokeMethod<void>('someUnimplementedMethod'),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'unimplemented')
              .having((e) => e.message, 'message',
                  'Method not implemented: someUnimplementedMethod'),
        ),
      );
    });
  });
}
