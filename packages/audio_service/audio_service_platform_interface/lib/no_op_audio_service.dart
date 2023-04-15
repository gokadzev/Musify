import 'package:flutter/foundation.dart';

import 'audio_service_platform_interface.dart';

class NoOpAudioService extends AudioServicePlatform {
  @override
  Future<void> configure(ConfigureRequest request) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> setState(SetStateRequest request) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> setQueue(SetQueueRequest request) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> setMediaItem(SetMediaItemRequest request) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> stopService(StopServiceRequest request) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> androidForceEnableMediaButtons(
      AndroidForceEnableMediaButtonsRequest request) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> notifyChildrenChanged(NotifyChildrenChangedRequest request) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> setAndroidPlaybackInfo(SetAndroidPlaybackInfoRequest request) {
    return SynchronousFuture(null);
  }

  @override
  void setHandlerCallbacks(AudioHandlerCallbacks callbacks) {}
}
