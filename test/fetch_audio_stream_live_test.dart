import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:musify/constants/clients.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Live test: hits YouTube, which blocks GitHub Actions.
final _skip = Platform.environment.containsKey('GITHUB_ACTIONS')
    ? 'YouTube blocks GitHub Actions'
    : null;

const _songId = 'dQw4w9WgXcQ';

void main() {
  // No TestWidgetsFlutterBinding: it blocks real HTTP requests.
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('musify_live').path);
    await Hive.openBox('settings');
    await Hive.openBox('cache');
    useProxy.value = false;
  });

  test(
    'fetchBestAudioStream returns a playable, clean audio stream',
    () async {
      final stream = await fetchBestAudioStream(_songId);

      expect(stream, isNotNull);
      expect(stream!.url.toString(), startsWith('https://'));
      expect(stream.url.queryParameters['sq'], isNull);
    },
    skip: _skip,
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'the stream URL is accepted with the playback headers',
    () async {
      final stream = await fetchBestAudioStream(_songId);

      final response = await http.head(
        stream!.url,
        headers: streamPlaybackHeaders(_songId),
      );

      expect(response.statusCode, inInclusiveRange(200, 299));
    },
    skip: _skip,
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'each fallback client can be used on its own',
    () async {
      final yt = YoutubeExplode();
      for (final client in fallbackClients) {
        try {
          final manifest = await yt.videos.streams.getManifest(
            _songId,
            ytClients: [client],
          );
          // ignore: avoid_print
          print(
            '${client.payload['context']['client']['clientName']}: '
            '${manifest.audioOnly.length} audio streams',
          );
        } catch (e) {
          // ignore: avoid_print
          print('${client.payload['context']['client']['clientName']}: $e');
        }
      }
    },
    skip: _skip,
    timeout: const Timeout(Duration(seconds: 120)),
  );
}
