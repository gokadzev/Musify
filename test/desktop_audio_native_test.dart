import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:just_audio_media_kit/mediakit_player.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:media_kit/media_kit.dart';

Uint8List _silentWav() {
  const size = 32000;
  final bytes = ByteData(44 + size);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  text(8, 'WAVE');
  text(12, 'fmt ');
  text(36, 'data');
  bytes
    ..setUint32(4, 36 + size, Endian.little)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, 8000, Endian.little)
    ..setUint32(28, 16000, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(40, size, Endian.little);
  return bytes.buffer.asUint8List();
}

void main() {
  final library = Platform.environment['MUSIFY_TEST_LIBMPV'];
  test(
    'native MPV loads nested clips repeatedly with headers and no disk cache errors',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final previousMode = NativePlayer.test;
      NativePlayer.test = true;
      addTearDown(() => NativePlayer.test = previousMode);
      MediaKit.ensureInitialized(libmpv: library);
      final wav = _silentWav();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      var authorized = 0;
      final serving = server.listen((request) async {
        requests++;
        if (request.headers.value('X-Musify-Test') != 'required') {
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
          return;
        }
        authorized++;
        final range = RegExp(r'bytes=(\d+)-(\d*)')
            .firstMatch(request.headers.value('range') ?? '');
        final start = range == null ? 0 : int.parse(range[1]!);
        final end = range == null || range[2]!.isEmpty
            ? wav.length - 1
            : int.parse(range[2]!).clamp(0, wav.length - 1);
        request.response.headers.contentType = ContentType('audio', 'wav');
        request.response.headers.set('accept-ranges', 'bytes');
        if (range != null) {
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set(
            'content-range',
            'bytes $start-$end/${wav.length}',
          );
        }
        request.response.contentLength = end - start + 1;
        request.response.add(wav.sublist(start, end + 1));
        await request.response.close();
      });
      addTearDown(() async {
        await server.close(force: true);
        await serving.cancel();
      });
      final logs = <String>[];
      await runZoned(
        () async {
          final player = MediaKitPlayer('native-regression');
          addTearDown(player.release);
          await player.ready();
          await player.setVolume(SetVolumeRequest(volume: 0));
          final events = <PlaybackEventMessage>[];
          final subscription = player.playbackEventMessageStream.listen(
            events.add,
          );
          addTearDown(subscription.cancel);
          for (var attempt = 0; attempt < 4; attempt++) {
            final uri = ProgressiveAudioSourceMessage(
              id: 'song$attempt',
              uri: 'http://127.0.0.1:${server.port}/audio.wav?attempt=$attempt',
              headers: {'X-Musify-Test': 'required'},
            );
            final clips = [
              ClippingAudioSourceMessage(
                id: 'first$attempt',
                child: uri,
                start: Duration.zero,
                end: const Duration(milliseconds: 250),
              ),
              ClippingAudioSourceMessage(
                id: 'last$attempt',
                child: uri,
                start: const Duration(milliseconds: 1500),
                end: const Duration(milliseconds: 1750),
              ),
            ];
            final source = ConcatenatingAudioSourceMessage(
              id: '',
              useLazyPreparation: true,
              shuffleOrder: [0],
              children: [
                ConcatenatingAudioSourceMessage(
                  id: 'sponsorblock$attempt',
                  useLazyPreparation: true,
                  shuffleOrder: [0, 1],
                  children: clips,
                ),
              ],
            );
            await player
                .load(LoadRequest(audioSourceMessage: source))
                .timeout(const Duration(seconds: 15));
            final completed = player.playbackEventMessageStream.firstWhere(
              (event) =>
                  event.processingState == ProcessingStateMessage.completed,
            );
            await player.play(PlayRequest());
            await completed.timeout(const Duration(seconds: 10));
            await player.pause(PauseRequest());
          }
          expect(events.where((event) => event.errorCode != null), isEmpty);
          expect(events.map((event) => event.currentIndex), contains(1));
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) {
            logs.add(line);
          },
        ),
      );
      expect(requests, greaterThanOrEqualTo(8));
      expect(authorized, requests);
      expect(
        logs.where((line) => line.contains('Failed to create file cache')),
        isEmpty,
      );
      expect(JustAudioMediaKit.diskCache, false);
    },
    skip: library == null
        ? 'Set MUSIFY_TEST_LIBMPV to run the native backend regression'
        : false,
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
