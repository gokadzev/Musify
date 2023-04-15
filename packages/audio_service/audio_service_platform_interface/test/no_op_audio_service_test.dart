import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service_platform_interface/no_op_audio_service.dart';

import 'stubs.dart';
import 'method_channel_audio_service_test.mocks.dart';

void main() {
  final platform = NoOpAudioService();

  var futureEnded = false;
  void runFuture() {
    Future<void>.value().then((value) {
      return futureEnded = true;
    });
  }

  setUp(() {
    futureEnded = false;
  });

  tearDown(() {
    futureEnded = false;
  });

  // Checking that functions run synchronously

  test('configure is no-op', () async {
    runFuture();
    await platform
        .configure(ConfigureRequest(config: AudioServiceConfigMessage()));
    expect(futureEnded, false);
  });

  test('setState is no-op', () async {
    runFuture();
    await platform.setState(SetStateRequest(state: PlaybackStateMessage()));
    expect(futureEnded, false);
  });

  test('setQueue is no-op', () async {
    runFuture();
    await platform.setQueue(const SetQueueRequest(queue: Stubs.queue));
    expect(futureEnded, false);
  });

  test('setMediaItem is no-op', () async {
    runFuture();
    await platform
        .setMediaItem(const SetMediaItemRequest(mediaItem: Stubs.mediaItem));
    expect(futureEnded, false);
  });

  test('stopService is no-op', () async {
    runFuture();
    await platform.stopService(const StopServiceRequest());
    expect(futureEnded, false);
  });

  test('androidForceEnableMediaButtons is no-op', () async {
    runFuture();
    await platform.androidForceEnableMediaButtons(
        const AndroidForceEnableMediaButtonsRequest());
    expect(futureEnded, false);
  });

  test('notifyChildrenChanged is no-op', () async {
    runFuture();
    await platform.notifyChildrenChanged(const NotifyChildrenChangedRequest(
      parentMediaId: Stubs.parentMediaId,
      options: Stubs.map,
    ));
    expect(futureEnded, false);
  });

  test('setAndroidPlaybackInfo is no-op', () async {
    runFuture();
    await platform.setAndroidPlaybackInfo(const SetAndroidPlaybackInfoRequest(
      playbackInfo: LocalAndroidPlaybackInfoMessage(),
    ));
    expect(futureEnded, false);
  });

  // This function returns void, so just check it doesn't throw

  test('setHandlerCallbacks is no-op', () async {
    platform.setHandlerCallbacks(MockAudioHandlerCallbacks());
  });
}
