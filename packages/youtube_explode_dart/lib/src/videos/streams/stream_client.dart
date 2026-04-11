import 'dart:collection';

import 'package:logging/logging.dart';

import '../../exceptions/exceptions.dart';
import '../../extensions/helpers_extension.dart';
import '../../retry.dart';
import '../../reverse_engineering/challenges/js_challenge.dart';
import '../../reverse_engineering/heuristics.dart';
import '../../reverse_engineering/models/stream_info_provider.dart';
import '../../reverse_engineering/pages/watch_page.dart';
import '../../reverse_engineering/youtube_http_client.dart';
import '../video_id.dart';
import '../youtube_api_client.dart';
import 'stream_controller.dart';
import 'streams.dart';

/// Queries related to media streams of YouTube videos.
class StreamClient {
  static final _logger = Logger('YoutubeExplode.StreamsClient');
  final YoutubeHttpClient _httpClient;
  final StreamController _controller;
  final BaseJSChallengeSolver? _jsChallengeSolver;

  /// Initializes an instance of [StreamClient]
  StreamClient(this._httpClient, {BaseJSChallengeSolver? jsSolver})
      : _controller = StreamController(_httpClient),
        _jsChallengeSolver = jsSolver;

  /// Gets the manifest that contains information
  /// about available streams in the specified video.
  ///
  /// See [YoutubeApiClient] for all the possible clients that can be set using the [ytClients] parameter.
  /// If [ytClients] is null the library automatically manages the clients, otherwise only the clients provided are used.
  /// Currently by default the  [YoutubeApiClient.android] clients is used,
  /// and if a js solver is provided the [YoutubeApiClient.tv] is used additionally.
  ///
  ///
  /// Note: if using any android client youtube often prevents downloading the same stream multiple times or downloading more than one stream from the same manifest.
  /// Note: that age restricted videos are no longer support due to the changes in the YouTube API.
  ///
  /// If [requireWatchPage] (default: true) is set to false the watch page is not used to extract the streams (so the process can be faster) but
  /// it COULD be less reliable (not tested thoroughly).
  /// If the extracted streams require signature decoding for which the watch page is required, the client will automatically fetch the watch page anyways (e.g. [YoutubeApiClient.tv]).
  ///
  /// If the extraction fails an exception is thrown, to diagnose the issue enable the logging from the `logging` package, and open an issue with the output.
  /// For example add at the beginning of your code:
  /// ```dart
  /// Logger.root.level = Level.FINER;
  /// Logger.root.onRecord.listen((e)  {
  ///   print(e);
  ///    if (e.error != null) {
  ///     print(e.error);
  ///     print(e.stackTrace);
  ///   }
  /// });
  /// ```
  Future<StreamManifest> getManifest(dynamic videoId,
      {@Deprecated(
          'Use the ytClient parameter instead passing the proper [YoutubeApiClient]s')
      bool fullManifest = false,
      List<YoutubeApiClient>? ytClients,
      bool requireWatchPage = true}) async {
    assert(ytClients == null || ytClients.isNotEmpty,
        'ytClients cannot be an empty list');

    videoId = VideoId.fromString(videoId);
    final clients = ytClients ?? [YoutubeApiClient.androidSdkless];

    if (_jsChallengeSolver != null && ytClients == null) {
      clients.add(YoutubeApiClient.tv);
    }

    final uniqueStreams = LinkedHashSet<StreamInfo>(
      equals: (a, b) {
        if (a.runtimeType != b.runtimeType) return false;
        if (a is AudioStreamInfo && b is AudioStreamInfo) {
          return a.tag == b.tag && a.audioTrack == b.audioTrack;
        }
        return a.tag == b.tag;
      },
      hashCode: (e) {
        if (e is AudioStreamInfo) {
          return e.tag.hashCode ^ e.audioTrack.hashCode;
        }
        return e.tag.hashCode;
      },
    );

    Object? lastException;

    for (final client in clients) {
      _logger.fine(
          'Getting stream manifest for video $videoId with client: ${client.payload['context']['client']['clientName']}');
      try {
        await retry(_httpClient, () async {
          final streams = await _getStreams(
            videoId,
            ytClient: client,
            requireWatchPage: requireWatchPage,
          ).toList();
          if (streams.isEmpty) {
            throw VideoUnavailableException(
              'Video "$videoId" does not contain any playable streams.',
            );
          }

          final response = await _httpClient.head(streams.first.url);
          if (response.statusCode == 403) {
            throw YoutubeExplodeException(
              'Video $videoId returned 403 (stream: ${streams.first.tag})',
            );
          }
          uniqueStreams.addAll(streams);
        });
      } catch (e, s) {
        _logger.severe(
            'Failed to get stream manifest for video $videoId with client: ${client.payload['context']['client']['clientName']}. Reason: $e\n',
            e,
            s);
        lastException = e;
      }
    }

    // If the user has not provided any client retry with the tv which work also in some restricted videos.
    if (uniqueStreams.isEmpty && ytClients == null) {
      return getManifest(videoId, ytClients: [YoutubeApiClient.tv]);
    }
    if (uniqueStreams.isEmpty) {
      if (lastException is Error && lastException.stackTrace != null) {
        throw Error.throwWithStackTrace(
            lastException, lastException.stackTrace!);
      }
      throw lastException ??
          VideoUnavailableException(
              'Video "$videoId" has no available streams');
    }
    return StreamManifest(uniqueStreams.toList());
  }

  /// Gets the HTTP Live Stream (HLS) manifest URL
  /// for the specified video (if it's a live video stream).
  Future<String> getHttpLiveStreamUrl(VideoId videoId) async {
    final watchPage = await WatchPage.get(_httpClient, videoId.value);

    final playerResponse = watchPage.playerResponse;

    if (playerResponse == null) {
      throw TransientFailureException(
        "Couldn't extract the playerResponse from the Watch Page!",
      );
    }

    if (!playerResponse.isVideoPlayable) {
      throw VideoUnplayableException.unplayable(
        videoId,
        reason: playerResponse.videoPlayabilityError ?? '',
      );
    }

    final hlsManifest = playerResponse.hlsManifestUrl;
    if (hlsManifest == null) {
      throw VideoUnplayableException.notLiveStream(videoId);
    }
    return hlsManifest;
  }

  /// Gets the actual stream which is identified by the specified metadata.
  /// Usually this downloads the bytes of the stream.
  /// For HLS streams all the fragments are concatenated into a single stream.
  Stream<List<int>> get(StreamInfo streamInfo) =>
      _httpClient.getStream(streamInfo, streamClient: this);

  Stream<StreamInfo> _getStreams(VideoId videoId,
      {required YoutubeApiClient ytClient,
      bool requireWatchPage = true}) async* {
    // Use await for instead of yield* to catch exceptions
    await for (final stream
        in _getStream(videoId, ytClient, requireWatchPage: requireWatchPage)) {
      yield stream;
    }
  }

  Stream<StreamInfo> _getStream(VideoId videoId, YoutubeApiClient ytClient,
      {bool requireWatchPage = true}) async* {
    WatchPage? watchPage;
    if (requireWatchPage) {
      watchPage = await WatchPage.get(_httpClient, videoId.value);
    }
    final playerResponse = await _controller
        .getPlayerResponse(videoId, ytClient, watchPage: watchPage);

    if (!playerResponse.previewVideoId.isNullOrWhiteSpace) {
      throw VideoRequiresPurchaseException.preview(
        videoId,
        VideoId(playerResponse.previewVideoId!),
      );
    }

    if (playerResponse.videoPlayabilityError?.contains('payment') ?? false) {
      throw VideoRequiresPurchaseException(videoId);
    }

    if (!playerResponse.isVideoPlayable) {
      throw VideoUnplayableException.unplayable(
        videoId,
        reason: playerResponse.videoPlayabilityError ?? '',
      );
    }
    yield* _parseStreamInfo(playerResponse.streams,
        watchPage: watchPage, videoId: videoId);

    if (!playerResponse.dashManifestUrl.isNullOrWhiteSpace) {
      final dashManifest =
          await _controller.getDashManifest(playerResponse.dashManifestUrl!);
      yield* _parseStreamInfo(dashManifest.streams,
          watchPage: watchPage, videoId: videoId);
    }
    if (!playerResponse.hlsManifestUrl.isNullOrWhiteSpace) {
      final hlsManifest =
          await _controller.getHlsManifest(playerResponse.hlsManifestUrl!);
      yield* _parseStreamInfo(hlsManifest.streams,
          watchPage: watchPage, videoId: videoId);
    }
  }

  Stream<StreamInfo> _parseStreamInfo(Iterable<StreamInfoProvider> streams,
      {WatchPage? watchPage, VideoId? videoId}) async* {
    // First pass: collect all unique challenges
    final nChallenges = <String>{};
    final sigChallenges = <String>{};

    final solver = _jsChallengeSolver;
    if (solver != null) {
      for (final stream in streams) {
        try {
          final url = Uri.parse(stream.url);
          if (url.queryParameters.containsKey('n')) {
            nChallenges.add(url.queryParameters['n']!);
          }
          if (stream.signatureParameter != null) {
            sigChallenges.add(stream.signature!);
          }
        } catch (e) {
          // Skip invalid URLs, will be handled in second pass
        }
      }
    }

    // Bulk solve all challenges
    final solvedChallenges = <String, String?>{};
    if (watchPage != null &&
        solver != null &&
        (nChallenges.isNotEmpty || sigChallenges.isNotEmpty)) {
      final requests = <JSChallengeType, List<String>>{};
      if (nChallenges.isNotEmpty) {
        requests[JSChallengeType.n] = nChallenges.toList();
      }
      if (sigChallenges.isNotEmpty) {
        requests[JSChallengeType.sig] = sigChallenges.toList();
      }

      try {
        solvedChallenges
            .addAll(await solver.solveBulk(watchPage.sourceUrl!, requests));
      } catch (e) {
        _logger.warning('Could not bulk solve challenges: $e');
        // Fall back to individual solving if bulk fails
      }
    }

    // Second pass: process streams with solved challenges
    for (final stream in streams) {
      final itag = stream.tag;
      late Uri url;
      try {
        url = Uri.parse(stream.url);
      } catch (e) {
        continue;
      }

      if (solver != null && watchPage != null) {
        if (url.queryParameters.containsKey('n')) {
          final nParam = url.queryParameters['n']!;
          final decoded = solvedChallenges[nParam];
          if (decoded != null) {
            url = url.setQueryParam('n', decoded);
            _logger.fine(
                'Decoded n-sig for stream itag $itag. $nParam -> $decoded}');
          } else {
            // Fallback to individual solving if bulk solving didn't provide result
            try {
              final individualDecoded = await solver.solve(
                  watchPage.sourceUrl!, JSChallengeType.n, nParam);
              url = url.setQueryParam('n', individualDecoded);
              _logger.fine(
                  'Decoded n-sig for stream itag $itag (individual). $nParam -> $individualDecoded}');
            } catch (e) {
              _logger.warning('Could not decipher n-sig using JS solver: $e');
            }
          }
        }
        if (stream.signatureParameter != null) {
          final sigParam = stream.signatureParameter!;
          final sig = stream.signature!;
          final decoded = solvedChallenges[sig];
          if (decoded != null) {
            url = url.setQueryParam(sigParam, decoded);
            _logger.fine(
                'Decoded signature for stream itag $itag. $sigParam -> $decoded}');
          } else {
            // Fallback to individual solving if bulk solving didn't provide result
            try {
              final individualDecoded = await solver.solve(
                  watchPage.sourceUrl!, JSChallengeType.sig, sig);
              url = url.setQueryParam(sigParam, individualDecoded);
              _logger.fine(
                  'Decoded signature for stream itag $itag (individual). $sigParam -> $individualDecoded}');
            } catch (e) {
              _logger
                  .warning('Could not decipher signature using JS solver: $e');
            }
          }
        }
      }

      final contentLength = stream.contentLength ??
          (await _httpClient.getContentLength(url, validate: false)) ??
          0;

      if (contentLength <= 0) {
        continue;
      }

      final container = StreamContainer.parse(stream.container!);
      final fileSize = FileSize(contentLength);
      final bitrate = Bitrate(stream.bitrate!);

      final audioCodec = stream.audioCodec;
      final videoCodec = stream.videoCodec;

      // HLS
      if (stream.source == StreamSource.hls) {
        if (stream.audioOnly) {
          yield HlsAudioStreamInfo(
            videoId ?? watchPage!.videoId,
            itag,
            url,
            container,
            fileSize,
            bitrate,
            '',
            '',
            stream.codec,
          );
          continue;
        }

        final framerate = Framerate(stream.framerate ?? 24);
        // TODO: Implement quality from itag
        final videoQuality = VideoQualityUtil.fromLabel(stream.qualityLabel);
        final videoWidth = stream.videoWidth;
        final videoHeight = stream.videoHeight;
        final videoResolution = videoWidth != null && videoHeight != null
            ? VideoResolution(videoWidth, videoHeight)
            : videoQuality.toVideoResolution();

        if (stream.videoOnly) {
          yield HlsVideoStreamInfo(
            videoId ?? watchPage!.videoId,
            itag,
            url,
            container,
            fileSize,
            bitrate,
            videoCodec ?? '',
            videoQuality.qualityString,
            videoQuality,
            videoResolution,
            framerate,
            stream.codec,
            stream.audioItag,
          );
        } else {
          yield HlsMuxedStreamInfo(
            videoId ?? watchPage!.videoId,
            itag,
            url,
            container,
            fileSize,
            bitrate,
            audioCodec!,
            videoCodec!,
            videoQuality.qualityString,
            videoQuality,
            videoResolution,
            framerate,
            stream.codec,
          );
        }
        continue;
      }

      // Muxed or Video-only
      if (!videoCodec.isNullOrWhiteSpace) {
        final framerate = Framerate(stream.framerate ?? 24);
        // TODO: Implement quality from itag
        final videoQuality = VideoQualityUtil.fromLabel(stream.qualityLabel);

        final videoWidth = stream.videoWidth;
        final videoHeight = stream.videoHeight;
        final videoResolution = videoWidth != null && videoHeight != null
            ? VideoResolution(videoWidth, videoHeight)
            : videoQuality.toVideoResolution();

        // Muxed
        if (!audioCodec.isNullOrWhiteSpace &&
            stream.source != StreamSource.adaptive) {
          assert(stream.audioTrack == null);
          yield MuxedStreamInfo(
            videoId ?? watchPage!.videoId,
            itag,
            url,
            container,
            fileSize,
            bitrate,
            audioCodec!,
            videoCodec!,
            videoQuality.qualityString,
            videoQuality,
            videoResolution,
            framerate,
            stream.codec,
          );
          continue;
        }

        // Video only
        yield VideoOnlyStreamInfo(
          videoId ?? watchPage!.videoId,
          itag,
          url,
          container,
          fileSize,
          bitrate,
          videoCodec!,
          videoQuality.qualityString,
          videoQuality,
          videoResolution,
          framerate,
          stream.fragments ?? const [],
          stream.codec,
        );
        continue;
        // Audio-only
      } else if (!audioCodec.isNullOrWhiteSpace) {
        yield AudioOnlyStreamInfo(
            videoId ?? watchPage!.videoId,
            itag,
            url,
            container,
            fileSize,
            bitrate,
            audioCodec!,
            stream.qualityLabel!,
            stream.fragments ?? const [],
            stream.codec,
            stream.audioTrack);
      } else {
        throw YoutubeExplodeException('Could not extract stream codec');
      }
    }
  }
}
