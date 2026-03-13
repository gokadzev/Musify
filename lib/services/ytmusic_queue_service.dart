/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:musify/main.dart';

class YtMusicQueueTrack {
  const YtMusicQueueTrack({
    required this.ytid,
    required this.title,
    required this.artist,
    required this.image,
    this.duration,
    this.queuePlaylistId,
    this.queueParams,
  });

  final String ytid;
  final String title;
  final String artist;
  final String image;
  final int? duration;
  final String? queuePlaylistId;
  final String? queueParams;

  Map<String, dynamic> toSongMap() {
    return {
      'ytid': ytid,
      'title': title,
      'artist': artist,
      'image': image,
      'lowResImage': image,
      'highResImage': image,
      'duration': duration,
      'isLive': false,
      if (queuePlaylistId != null) 'queuePlaylistId': queuePlaylistId,
      if (queueParams != null) 'queueParams': queueParams,
    };
  }
}

class YtMusicQueueResult {
  const YtMusicQueueResult({
    required this.tracks,
    this.playlistId,
    this.params,
    this.continuationToken,
  });

  final List<YtMusicQueueTrack> tracks;
  final String? playlistId;
  final String? params;
  final String? continuationToken;
}

class YtMusicQueueService {
  factory YtMusicQueueService() => _instance;

  YtMusicQueueService._internal();

  static final YtMusicQueueService _instance = YtMusicQueueService._internal();
  static final Uri _homeUri = Uri.parse('https://music.youtube.com/');
  static final Uri _nextUri = Uri.parse(
    'https://music.youtube.com/youtubei/v1/next?prettyPrint=false',
  );

  static const String _defaultClientVersion = '1.20260128.03.00';
  static const String _userAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const Duration _contextCacheTtl = Duration(hours: 6);

  String _clientVersion = _defaultClientVersion;
  String? _visitorData;
  DateTime _contextFetchedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<YtMusicQueueResult?> fetchQueue(
    String videoId, {
    String? playlistId,
    String? params,
    String? continuationToken,
  }) async {
    if (videoId.isEmpty) {
      return null;
    }

    try {
      await _ensureClientContext();

      final response = await _sendQueueRequest(
        videoId,
        playlistId: playlistId,
        params: params,
        continuationToken: continuationToken,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        logger.log(
          'YouTube Music queue request failed with status ${response.statusCode}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        logger.log('Unexpected YouTube Music queue payload shape');
        return null;
      }

      final tracks = _parseQueueTracks(decoded);
      if (tracks.isEmpty) {
        return null;
      }

      final resolvedPlaylistId = tracks
          .map((track) => track.queuePlaylistId)
          .whereType<String>()
          .firstWhere(
            (value) => value.isNotEmpty,
            orElse: () => playlistId ?? 'RDAMVM$videoId',
          );
      final resolvedParams = tracks
          .map((track) => track.queueParams)
          .whereType<String>()
          .firstWhere((value) => value.isNotEmpty, orElse: () => params ?? '');

      return YtMusicQueueResult(
        tracks: tracks,
        playlistId: resolvedPlaylistId,
        params: resolvedParams.isEmpty ? null : resolvedParams,
        continuationToken: _extractContinuationToken(decoded),
      );
    } catch (e, stackTrace) {
      logger.log(
        'Failed to fetch YouTube Music queue',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<http.Response> _sendQueueRequest(
    String videoId, {
    String? playlistId,
    String? params,
    String? continuationToken,
  }) {
    final endpoint = continuationToken == null
        ? _nextUri
        : _nextUri.replace(
            queryParameters: {
              'prettyPrint': 'false',
              'ctoken': continuationToken,
              'continuation': continuationToken,
            },
          );

    return http
        .post(
          endpoint,
          headers: {
            'Accept': '*/*',
            'Content-Type': 'application/json',
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/watch?v=$videoId',
            'User-Agent': _userAgent,
            'X-Youtube-Client-Name': '67',
            'X-Youtube-Client-Version': _clientVersion,
            if (_visitorData != null && _visitorData!.isNotEmpty)
              'X-Goog-Visitor-Id': _visitorData!,
          },
          body: jsonEncode({
            'context': {
              'client': {
                'hl': 'en',
                'gl': 'US',
                'clientName': 'WEB_REMIX',
                'clientVersion': _clientVersion,
                'platform': 'DESKTOP',
                'userAgent': _userAgent,
              },
              'user': {'lockedSafetyMode': false},
              'request': {
                'useSsl': true,
                'internalExperimentFlags': <dynamic>[],
                'consistencyTokenJars': <dynamic>[],
              },
            },
            if (continuationToken == null) ...{
              'videoId': videoId,
              'playlistId': playlistId ?? 'RDAMVM$videoId',
              if (params != null && params.isNotEmpty) 'params': params,
              'isAudioOnly': true,
              'enablePersistentPlaylistPanel': true,
            } else
              'continuation': continuationToken,
          }),
        )
        .timeout(_requestTimeout);
  }

  Future<void> _ensureClientContext() async {
    final now = DateTime.now();
    if (now.difference(_contextFetchedAt) < _contextCacheTtl) {
      return;
    }

    try {
      final response = await http
          .get(_homeUri, headers: {'User-Agent': _userAgent})
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final body = response.body;
      final clientVersionMatch = RegExp(
        '"INNERTUBE_CLIENT_VERSION":"([^"]+)"',
      ).firstMatch(body);
      final visitorMatch = RegExp('"VISITOR_DATA":"([^"]+)"').firstMatch(body);

      _clientVersion = clientVersionMatch?.group(1) ?? _defaultClientVersion;
      _visitorData = visitorMatch?.group(1);
      _contextFetchedAt = now;
    } catch (e, stackTrace) {
      logger.log(
        'Failed to refresh YouTube Music client context',
        error: e,
        stackTrace: stackTrace,
      );
      _clientVersion = _defaultClientVersion;
      _visitorData = null;
      _contextFetchedAt = now;
    }
  }

  List<YtMusicQueueTrack> _parseQueueTracks(Map<String, dynamic> response) {
    final directPanelItems = _extractDirectPanelItems(response);
    final candidateRenderers = directPanelItems.isNotEmpty
        ? directPanelItems
              .map((entry) => entry['playlistPanelVideoRenderer'])
              .whereType<Map<String, dynamic>>()
              .toList()
        : _collectPlaylistPanelRenderers(response);

    final seen = <String>{};
    final tracks = <YtMusicQueueTrack>[];

    for (final renderer in candidateRenderers) {
      final track = _mapRendererToTrack(renderer);
      if (track == null || !seen.add(track.ytid)) {
        continue;
      }
      tracks.add(track);
    }

    return tracks;
  }

  List<Map<String, dynamic>> _extractDirectPanelItems(
    Map<String, dynamic> response,
  ) {
    final tabs = _readNested(response, [
      'contents',
      'singleColumnMusicWatchNextResultsRenderer',
      'tabbedRenderer',
      'watchNextTabbedResultsRenderer',
      'tabs',
    ]);

    if (tabs is! List) {
      return const [];
    }

    final items = <Map<String, dynamic>>[];

    for (final tab in tabs) {
      if (tab is! Map) continue;
      final tabContent = _readNested(tab, ['tabRenderer', 'content']);
      final contents =
          _readNested(tabContent, [
            'musicQueueRenderer',
            'content',
            'playlistPanelRenderer',
            'contents',
          ]) ??
          _readNested(tabContent, ['playlistPanelRenderer', 'contents']);

      if (contents is List) {
        for (final item in contents) {
          if (item is Map<String, dynamic>) {
            items.add(item);
          }
        }
      }
    }

    final fallback =
        _readNested(response, [
          'contents',
          'singleColumnMusicWatchNextResultsRenderer',
          'playlist',
          'playlistPanelRenderer',
          'contents',
        ]) ??
        _readNested(response, [
          'contents',
          'twoColumnWatchNextResults',
          'playlist',
          'playlist',
          'contents',
        ]);

    if (items.isEmpty && fallback is List) {
      for (final item in fallback) {
        if (item is Map<String, dynamic>) {
          items.add(item);
        }
      }
    }

    return items;
  }

  List<Map<String, dynamic>> _collectPlaylistPanelRenderers(
    dynamic node, {
    int depth = 0,
    List<Map<String, dynamic>>? acc,
  }) {
    final result = acc ?? <Map<String, dynamic>>[];
    if (node == null || depth > 12) {
      return result;
    }

    if (node is List) {
      for (final item in node) {
        _collectPlaylistPanelRenderers(item, depth: depth + 1, acc: result);
      }
      return result;
    }

    if (node is! Map) {
      return result;
    }

    final renderer = node['playlistPanelVideoRenderer'];
    if (renderer is Map<String, dynamic>) {
      result.add(renderer);
    }

    for (final value in node.values) {
      _collectPlaylistPanelRenderers(value, depth: depth + 1, acc: result);
    }

    return result;
  }

  YtMusicQueueTrack? _mapRendererToTrack(Map<String, dynamic> renderer) {
    final videoId = renderer['videoId']?.toString() ?? '';
    if (videoId.isEmpty) {
      return null;
    }

    final title =
        _readNested(renderer, ['title', 'simpleText'])?.toString() ??
        _joinRuns(_readNested(renderer, ['title', 'runs'])) ??
        'Unknown Title';

    final artistRuns =
        _readNested(renderer, ['longBylineText', 'runs']) ??
        _readNested(renderer, ['shortBylineText', 'runs']) ??
        const <dynamic>[];
    final artists = _extractArtists(artistRuns);
    final artist = artists.isEmpty ? 'Unknown Artist' : artists.join(', ');

    final thumbnail =
        _pickLastThumbnail(
          _readNested(renderer, ['thumbnail', 'thumbnails']),
        ) ??
        _pickLastThumbnail(
          _readNested(renderer, [
            'thumbnail',
            'musicThumbnailRenderer',
            'thumbnail',
            'thumbnails',
          ]),
        ) ??
        '';

    final navigationEndpoint =
        renderer['navigationEndpoint'] ??
        renderer['playNavigationEndpoint'] ??
        _readNested(renderer, [
          'thumbnailOverlay',
          'musicItemThumbnailOverlayRenderer',
          'content',
          'musicPlayButtonRenderer',
          'playNavigationEndpoint',
        ]);
    final watchEndpoint = _readNested(navigationEndpoint, ['watchEndpoint']);

    return YtMusicQueueTrack(
      ytid: videoId,
      title: title,
      artist: artist,
      image: thumbnail,
      duration: _parseDurationInSeconds(
        _readNested(renderer, ['lengthText', 'simpleText'])?.toString() ??
            _joinRuns(_readNested(renderer, ['lengthText', 'runs'])),
      ),
      queuePlaylistId: _readNested(watchEndpoint, ['playlistId'])?.toString(),
      queueParams: _readNested(watchEndpoint, ['params'])?.toString(),
    );
  }

  List<String> _extractArtists(dynamic runs) {
    if (runs is! List) {
      return const [];
    }

    final artists = <String>[];
    final seen = <String>{};

    for (final run in runs) {
      if (run is! Map) continue;
      final text = run['text']?.toString().trim() ?? '';
      if (text.isEmpty || text == '•') {
        continue;
      }

      final browseId = _readNested(run, [
        'navigationEndpoint',
        'browseEndpoint',
        'browseId',
      ])?.toString();
      if (browseId != null &&
          browseId.isNotEmpty &&
          !browseId.startsWith('UC')) {
        continue;
      }

      if (seen.add(text.toLowerCase())) {
        artists.add(text);
      }
    }

    return artists;
  }

  String? _joinRuns(dynamic runs) {
    if (runs is! List) {
      return null;
    }

    final text = runs
        .whereType<Map>()
        .map((run) => run['text']?.toString() ?? '')
        .join()
        .trim();
    return text.isEmpty ? null : text;
  }

  String? _pickLastThumbnail(dynamic thumbnails) {
    if (thumbnails is! List || thumbnails.isEmpty) {
      return null;
    }

    for (var i = thumbnails.length - 1; i >= 0; i--) {
      final item = thumbnails[i];
      if (item is Map && item['url'] != null) {
        return item['url'].toString();
      }
    }

    return null;
  }

  int? _parseDurationInSeconds(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parts = value
        .split(':')
        .map((part) => int.tryParse(part.trim()))
        .toList();
    if (parts.any((part) => part == null)) {
      return null;
    }

    if (parts.length == 2) {
      return parts[0]! * 60 + parts[1]!;
    }
    if (parts.length == 3) {
      return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    }
    return null;
  }

  String? _extractContinuationToken(Map<String, dynamic> response) {
    final directItems = _extractDirectPanelItems(response);
    for (final item in directItems) {
      final token = _readNested(item, [
        'continuationItemRenderer',
        'continuationEndpoint',
        'continuationCommand',
        'token',
      ])?.toString();
      if (token != null && token.isNotEmpty) {
        return token;
      }
    }

    return _findContinuationToken(response);
  }

  String? _findContinuationToken(dynamic node, {int depth = 0}) {
    if (node == null || depth > 12) {
      return null;
    }

    if (node is List) {
      for (final item in node) {
        final token = _findContinuationToken(item, depth: depth + 1);
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
      return null;
    }

    if (node is! Map) {
      return null;
    }

    final directToken =
        _readNested(node, [
          'continuationItemRenderer',
          'continuationEndpoint',
          'continuationCommand',
          'token',
        ]) ??
        _readNested(node, [
          'continuations',
          '0',
          'nextContinuationData',
          'continuation',
        ]);
    if (directToken is String && directToken.isNotEmpty) {
      return directToken;
    }

    for (final value in node.values) {
      final token = _findContinuationToken(value, depth: depth + 1);
      if (token != null && token.isNotEmpty) {
        return token;
      }
    }

    return null;
  }

  dynamic _readNested(dynamic node, List<String> path) {
    var current = node;
    for (final key in path) {
      if (current is List) {
        final index = int.tryParse(key);
        if (index == null || index < 0 || index >= current.length) {
          return null;
        }
        current = current[index];
        continue;
      }
      if (current is! Map) {
        return null;
      }
      current = current[key];
    }
    return current;
  }
}
