import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';

import 'stubs.dart';
import 'method_channel_audio_service_test.mocks.dart';

class ImplementsAudioServicePlatform implements AudioServicePlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ExtendsAudioServicePlatform extends AudioServicePlatform {}

void main() {
  test('cannot be implemented with `implements`', () {
    expect(() {
      AudioServicePlatform.instance = ImplementsAudioServicePlatform();
    }, throwsNoSuchMethodError);
  });

  test('can set custom platform', () {
    final platform = ExtendsAudioServicePlatform();
    AudioServicePlatform.instance = platform;
    expect(AudioServicePlatform.instance, platform);
  });

  test('default implementations of the methods throw unimplemented errors', () {
    final platform = ExtendsAudioServicePlatform();
    expect(
      () => platform
          .configure(ConfigureRequest(config: AudioServiceConfigMessage())),
      throwsUnimplementedError,
    );
    expect(
      () => platform.setState(SetStateRequest(state: PlaybackStateMessage())),
      throwsUnimplementedError,
    );
    expect(
      () => platform.setQueue(const SetQueueRequest(queue: Stubs.queue)),
      throwsUnimplementedError,
    );
    expect(
      () => platform
          .setMediaItem(const SetMediaItemRequest(mediaItem: Stubs.mediaItem)),
      throwsUnimplementedError,
    );
    expect(
      () => platform.stopService(const StopServiceRequest()),
      throwsUnimplementedError,
    );
    expect(
      () => platform.setAndroidPlaybackInfo(const SetAndroidPlaybackInfoRequest(
          playbackInfo: LocalAndroidPlaybackInfoMessage())),
      throwsUnimplementedError,
    );
    expect(
      () => platform.androidForceEnableMediaButtons(
          const AndroidForceEnableMediaButtonsRequest()),
      throwsUnimplementedError,
    );
    expect(
      () => platform.notifyChildrenChanged(const NotifyChildrenChangedRequest(
          parentMediaId: Stubs.parentMediaId, options: Stubs.map)),
      throwsUnimplementedError,
    );
    expect(
      () => platform.setHandlerCallbacks(MockAudioHandlerCallbacks()),
      throwsUnimplementedError,
    );
  });
}
