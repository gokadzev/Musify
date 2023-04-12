import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'audio_service_platform_interface.dart';

class MethodChannelAudioService extends AudioServicePlatform {
  final MethodChannel _clientChannel =
      const MethodChannel('com.ryanheise.audio_service.client.methods');
  @visibleForTesting
  final MethodChannel handlerChannel =
      const MethodChannel('com.ryanheise.audio_service.handler.methods');

  @override
  Future<void> configure(ConfigureRequest request) async {
    await _clientChannel.invokeMethod<void>('configure', request.toMap());
  }

  @override
  Future<void> setState(SetStateRequest request) async {
    await handlerChannel.invokeMethod<void>('setState', request.toMap());
  }

  @override
  Future<void> setQueue(SetQueueRequest request) async {
    await handlerChannel.invokeMethod<void>('setQueue', request.toMap());
  }

  @override
  Future<void> setMediaItem(SetMediaItemRequest request) async {
    await handlerChannel.invokeMethod<void>('setMediaItem', request.toMap());
  }

  @override
  Future<void> stopService(StopServiceRequest request) async {
    await handlerChannel.invokeMethod<void>('stopService', request.toMap());
  }

  @override
  Future<void> androidForceEnableMediaButtons(
      AndroidForceEnableMediaButtonsRequest request) async {
    await handlerChannel.invokeMethod<void>(
        'androidForceEnableMediaButtons', request.toMap());
  }

  @override
  Future<void> notifyChildrenChanged(
      NotifyChildrenChangedRequest request) async {
    await handlerChannel.invokeMethod<void>(
        'notifyChildrenChanged', request.toMap());
  }

  @override
  Future<void> setAndroidPlaybackInfo(
      SetAndroidPlaybackInfoRequest request) async {
    await handlerChannel.invokeMethod<void>(
        'setAndroidPlaybackInfo', request.toMap());
  }

  @override
  void setHandlerCallbacks(AudioHandlerCallbacks callbacks) {
    handlerChannel.setMethodCallHandler((call) async {
      return handlerCallbacksCallHandler(callbacks, call);
    });
  }

  /// Used in tests within mock method channel.
  @visibleForTesting
  Future<dynamic> handlerCallbacksCallHandler(
      AudioHandlerCallbacks callbacks, MethodCall call) async {
    switch (call.method) {
      case 'prepare':
        await callbacks.prepare(const PrepareRequest());
        return null;
      case 'prepareFromMediaId':
        await callbacks.prepareFromMediaId(PrepareFromMediaIdRequest(
            mediaId: call.arguments['mediaId'] as String,
            extras: _castMap(call.arguments['extras'] as Map?)));
        return null;
      case 'prepareFromSearch':
        await callbacks.prepareFromSearch(PrepareFromSearchRequest(
            query: call.arguments['query'] as String,
            extras: _castMap(call.arguments['extras'] as Map?)));
        return null;
      case 'prepareFromUri':
        await callbacks.prepareFromUri(PrepareFromUriRequest(
            uri: Uri.parse(call.arguments['uri'] as String),
            extras: _castMap(call.arguments['extras'] as Map?)));
        return null;
      case 'play':
        await callbacks.play(const PlayRequest());
        return null;
      case 'playFromMediaId':
        await callbacks.playFromMediaId(PlayFromMediaIdRequest(
            mediaId: call.arguments['mediaId'] as String,
            extras: _castMap(call.arguments['extras'] as Map?)));
        return null;
      case 'playFromSearch':
        await callbacks.playFromSearch(PlayFromSearchRequest(
            query: call.arguments['query'] as String,
            extras: _castMap(call.arguments['extras'] as Map?)));
        return null;
      case 'playFromUri':
        await callbacks.playFromUri(PlayFromUriRequest(
            uri: Uri.parse(call.arguments['uri'] as String),
            extras: _castMap(call.arguments['extras'] as Map?)));
        return null;
      case 'playMediaItem':
        await callbacks.playMediaItem(PlayMediaItemRequest(
            mediaItem: MediaItemMessage.fromMap(
                _castMap(call.arguments['mediaItem'] as Map)!)));
        return null;
      case 'pause':
        await callbacks.pause(const PauseRequest());
        return null;
      case 'click':
        await callbacks.click(ClickRequest(
            button:
                MediaButtonMessage.values[call.arguments['button'] as int]));
        return null;
      case 'stop':
        await callbacks.stop(const StopRequest());
        return null;
      case 'addQueueItem':
        await callbacks.addQueueItem(AddQueueItemRequest(
            mediaItem: MediaItemMessage.fromMap(
                _castMap(call.arguments['mediaItem'] as Map)!)));
        return null;
      case 'insertQueueItem':
        await callbacks.insertQueueItem(InsertQueueItemRequest(
            index: call.arguments['index'] as int,
            mediaItem: MediaItemMessage.fromMap(
                _castMap(call.arguments['mediaItem'] as Map)!)));
        return null;
      case 'removeQueueItem':
        await callbacks.removeQueueItem(RemoveQueueItemRequest(
            mediaItem: MediaItemMessage.fromMap(
                _castMap(call.arguments['mediaItem'] as Map)!)));
        return null;
      case 'removeQueueItemAt':
        await callbacks.removeQueueItemAt(
            RemoveQueueItemAtRequest(index: call.arguments['index'] as int));
        return null;
      case 'skipToNext':
        await callbacks.skipToNext(const SkipToNextRequest());
        return null;
      case 'skipToPrevious':
        await callbacks.skipToPrevious(const SkipToPreviousRequest());
        return null;
      case 'fastForward':
        await callbacks.fastForward(const FastForwardRequest());
        return null;
      case 'rewind':
        await callbacks.rewind(const RewindRequest());
        return null;
      case 'skipToQueueItem':
        await callbacks.skipToQueueItem(
            SkipToQueueItemRequest(index: call.arguments['index'] as int));
        return null;
      case 'seek':
        await callbacks.seek(SeekRequest(
            position:
                Duration(microseconds: call.arguments['position'] as int)));
        return null;
      case 'setRating':
        await callbacks.setRating(SetRatingRequest(
            rating: RatingMessage.fromMap(
                _castMap(call.arguments['rating'] as Map)!),
            extras: _castMap(call.arguments['extras'] as Map?)));
        return null;
      case 'setCaptioningEnabled':
        await callbacks.setCaptioningEnabled(SetCaptioningEnabledRequest(
            enabled: call.arguments['enabled'] as bool));
        return null;
      case 'setRepeatMode':
        await callbacks.setRepeatMode(SetRepeatModeRequest(
            repeatMode: AudioServiceRepeatModeMessage
                .values[call.arguments['repeatMode'] as int]));
        return null;
      case 'setShuffleMode':
        await callbacks.setShuffleMode(SetShuffleModeRequest(
            shuffleMode: AudioServiceShuffleModeMessage
                .values[call.arguments['shuffleMode'] as int]));
        return null;
      case 'seekBackward':
        await callbacks.seekBackward(
            SeekBackwardRequest(begin: call.arguments['begin'] as bool));
        return null;
      case 'seekForward':
        await callbacks.seekForward(
            SeekForwardRequest(begin: call.arguments['begin'] as bool));
        return null;
      case 'setSpeed':
        await callbacks.setSpeed(
            SetSpeedRequest(speed: call.arguments['speed'] as double));
        return null;
      case 'customAction':
        await callbacks.customAction(CustomActionRequest(
            name: call.arguments['name'] as String,
            extras: _castMap(call.arguments['extras'] as Map?)));
        return null;
      case 'onTaskRemoved':
        await callbacks.onTaskRemoved(const OnTaskRemovedRequest());
        return null;
      case 'onNotificationDeleted':
        await callbacks
            .onNotificationDeleted(const OnNotificationDeletedRequest());
        return null;
      case 'onNotificationClicked':
        await callbacks.onNotificationClicked(OnNotificationClickedRequest(
            clicked: call.arguments['clicked'] as bool));
        return null;
      case 'getChildren':
        return (await callbacks.getChildren(GetChildrenRequest(
                parentMediaId: call.arguments['parentMediaId'] as String,
                options: _castMap(call.arguments['options'] as Map?))))
            .toMap();
      case 'getMediaItem':
        return (await callbacks.getMediaItem(GetMediaItemRequest(
                mediaId: call.arguments['mediaId'] as String)))
            .toMap();
      case 'search':
        return (await callbacks.search(SearchRequest(
                query: call.arguments['query'] as String,
                extras: _castMap(call.arguments['extras'] as Map?))))
            .toMap();
      case 'androidSetRemoteVolume':
        await callbacks.androidSetRemoteVolume(AndroidSetRemoteVolumeRequest(
            volumeIndex: call.arguments['volumeIndex'] as int));
        return null;
      case 'androidAdjustRemoteVolume':
        await callbacks.androidAdjustRemoteVolume(
            AndroidAdjustRemoteVolumeRequest(
                direction: AndroidVolumeDirectionMessage
                    .values[call.arguments['direction']]!));
        return null;
      default:
        throw PlatformException(
            code: 'unimplemented',
            message: 'Method not implemented: ${call.method}');
    }
  }
}

/// Casts `Map<dynamic, dynamic>` into `Map<String, dynamic>`.
///
/// Used mostly to unwrap [MethodCall.arguments] which in case with maps
/// is always `Map<Object?, Object?>`.
@pragma('vm:prefer-inline')
Map<String, dynamic>? _castMap(Map? map) => map?.cast<String, dynamic>();
