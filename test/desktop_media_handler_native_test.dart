import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:media_kit/media_kit.dart';
import 'package:musify/services/audio_service.dart';
import 'package:musify/services/linux_media_controls.dart';
import 'package:musify/services/settings_manager.dart';

import 'support/audio_fixture.dart';

void main() {
  final library = Platform.environment['MUSIFY_TEST_LIBMPV'];
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File wav;
  late MusifyAudioHandler handler;
  LinuxMediaControls? controls;
  DBusServer? bus;
  DBusClient? observer;
  DBusRemoteObject? remote;
  late List<Object> errors;
  const playerInterface = LinuxMediaControls.playerInterface;

  Future<void> waitFor(bool Function() condition) async {
    final timeout = DateTime.now().add(const Duration(seconds: 5));
    while (!condition()) {
      if (DateTime.now().isAfter(timeout)) fail('Player state did not settle');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> navigate(String command) async {
    if (remote != null) {
      await remote!.callMethod(
        playerInterface,
        command,
        [],
        replySignature: DBusSignature(''),
      );
    } else if (command == 'Next') {
      await handler.skipToNext(playWhenReady: handler.shouldContinuePlayback);
    } else {
      await handler.skipToPrevious(
        playWhenReady: handler.shouldContinuePlayback,
      );
    }
  }

  Future<void> loadQueue() async {
    Map<String, dynamic> song(String id) => {
      'ytid': id,
      'title': id,
      'artist': 'Native test',
      'audioPath': wav.path,
      'highResImage': '',
      'lowResImage': '',
      'isLive': false,
    };
    await handler.addPlaylistToQueue([song('first'), song('second')]);
    await handler.skipToSong(0);
    await waitFor(() => handler.audioPlayer.playing);
    await handler.pause();
    await waitFor(() => !handler.playbackState.value.playing);
  }

  group(
    'real desktop handler',
    () {
      setUpAll(() async {
        NativePlayer.test = true;
        JustAudioMediaKit.ensureInitialized(libmpv: library);
        directory = await Directory.systemTemp.createTemp(
          'musify_native_handler',
        );
        Hive.init(directory.path);
        for (final name in ['settings', 'user', 'userNoBackup', 'cache']) {
          await Hive.openBox(name);
        }
        wav = File('${directory.path}/silence.wav');
        await wav.writeAsBytes(silentWav(size: 320000));
      });
      tearDownAll(() async {
        await Future<void>.delayed(const Duration(seconds: 2));
        await Hive.close();
        await directory.delete(recursive: true);
      });
      setUp(() async {
        debugDefaultTargetPlatformOverride = Platform.isWindows
            ? TargetPlatform.windows
            : TargetPlatform.linux;
        offlineMode.value = true;
        playNextSongAutomatically.value = false;
        repeatNotifier.value = AudioServiceRepeatMode.none;
        handler = MusifyAudioHandler();
        await handler.setVolume(0);
        errors = [];
        if (Platform.isLinux) {
          bus = DBusServer();
          final address = await bus!.listenAddress(
            DBusAddress.unix(dir: directory),
          );
          observer = DBusClient(address);
          controls = LinuxMediaControls(
            handler: handler,
            skipToNext: () => handler.skipToNext(
              playWhenReady: handler.shouldContinuePlayback,
            ),
            skipToPrevious: () => handler.skipToPrevious(
              playWhenReady: handler.shouldContinuePlayback,
            ),
            bus: DBusClient(address),
            name: 'org.mpris.MediaPlayer2.musify.native',
            volume: () => handler.volume,
            volumeStream: handler.volumeStream,
            setVolume: handler.setVolume,
            canGoNext: () => handler.canSkipToNext,
            canGoPrevious: () => handler.hasPrevious,
            position: () => handler.audioPlayer.position,
            onError: (error, _) => errors.add(error),
          );
          await controls!.start();
          remote = DBusRemoteObject(
            observer!,
            name: controls!.name,
            path: controls!.path,
          );
        }
        await loadQueue();
      });
      tearDown(() async {
        await controls?.dispose();
        await observer?.close();
        await bus?.close();
        controls = null;
        observer = null;
        bus = null;
        remote = null;
        await handler.stop();
        await handler.audioPlayer.dispose();
        debugDefaultTargetPlatformOverride = null;
        expect(errors, isEmpty);
      });

      test('paused Next and Previous never start playback', () async {
        final playing = <bool>[];
        final states = handler.audioPlayer.playingStream.listen(playing.add);
        addTearDown(states.cancel);
        await navigate('Next');
        expect(handler.currentQueueIndex, 1);
        expect(handler.mediaItem.value!.title, 'second');
        expect(handler.audioPlayer.playing, false);
        await navigate('Previous');
        expect(handler.currentQueueIndex, 0);
        expect(handler.mediaItem.value!.title, 'first');
        expect(handler.audioPlayer.playing, false);
        expect(playing, isNot(contains(true)));
        await handler.play();
        await waitFor(() => handler.audioPlayer.playing);
        expect(handler.currentQueueIndex, 0);
      });

      test('playing Next and Previous continue playback', () async {
        await handler.play();
        await waitFor(() => handler.audioPlayer.playing);
        await navigate('Next');
        expect(handler.currentQueueIndex, 1);
        expect(handler.audioPlayer.playing, true);
        await navigate('Previous');
        expect(handler.currentQueueIndex, 0);
        expect(handler.audioPlayer.playing, true);
      });

      test('paused repeat-all wraps without playing', () async {
        repeatNotifier.value = AudioServiceRepeatMode.all;
        await navigate('Next');
        await navigate('Next');
        expect(handler.currentQueueIndex, 0);
        expect(handler.audioPlayer.playing, false);
      });

      test(
        'pause during a playing track change prevents automatic resume',
        () async {
          await handler.play();
          await waitFor(() => handler.audioPlayer.playing);
          var pausedDuringLoad = false;
          final subscription = handler.audioPlayer.processingStateStream.listen(
            (state) {
              if (state.name == 'loading' && !pausedDuringLoad) {
                expect(handler.shouldContinuePlayback, true);
                pausedDuringLoad = true;
                handler.pause();
              }
            },
          );
          addTearDown(subscription.cancel);
          await navigate('Next');
          expect(pausedDuringLoad, true);
          expect(handler.currentQueueIndex, 1);
          expect(handler.audioPlayer.playing, false);
        },
      );

      test('app navigation retains its existing autoplay default', () async {
        await handler.skipToNext();
        expect(handler.currentQueueIndex, 1);
        expect(handler.audioPlayer.playing, true);
      });

      test(
        'rate reaches native player and the published playback state',
        () async {
          for (final speed in [0.25, 1.5, 3.0]) {
            if (remote != null) {
              await remote!.setProperty(
                playerInterface,
                'Rate',
                DBusDouble(speed),
              );
            } else {
              await handler.setSpeed(speed);
            }
            await waitFor(() => handler.playbackState.value.speed == speed);
            expect(handler.audioPlayer.speed, speed);
            expect(handler.audioPlayer.playing, false);
            if (remote != null) {
              expect(
                (await remote!.getProperty(playerInterface, 'Rate')).asDouble(),
                speed,
              );
            }
          }
        },
      );

      test('MPRIS zero rate pauses and invalid rates are rejected', () async {
        await handler.play();
        await waitFor(() => handler.audioPlayer.playing);
        await remote!.setProperty(playerInterface, 'Rate', const DBusDouble(0));
        expect(handler.audioPlayer.playing, false);
        for (final speed in [-1.0, 0.1, 3.1, double.nan, double.infinity]) {
          await expectLater(
            remote!.setProperty(playerInterface, 'Rate', DBusDouble(speed)),
            throwsA(isA<DBusMethodResponseException>()),
          );
        }
        expect(handler.audioPlayer.speed, 1);
      }, skip: library == null || !Platform.isLinux);
    },
    skip: library == null
        ? 'Set MUSIFY_TEST_LIBMPV to test the real desktop handler'
        : false,
  );
}
