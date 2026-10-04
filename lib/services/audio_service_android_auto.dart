import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/map_utils.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:rxdart/rxdart.dart';

abstract interface class AndroidAutoHost {
  List<Map> get browserQueue;
  Stream<List<MediaItem>> get browserQueueStream;

  Map? latestResumableSong();
  Map<String, dynamic>? normaliseResumableSong(Map song);
  Future<void> playResumableSong(Map song);
  String ensureBrowserQueueEntryId(Map song);
  void logBrowserError(String message, {Object? error, StackTrace? stackTrace});
  Future<void> resumeAudio();
  Future<void> skipToQueueItem(int index);
  Future<void> playBrowserPlaylist(List<Map> songs, {required int songIndex});
  void publishPreparedBrowserItem(MediaItem item);
}

class AndroidAutoBrowser {
  AndroidAutoBrowser(this._host);

  final AndroidAutoHost _host;
  List<Map> _lastSearchResults = const [];
  final Map<String, BehaviorSubject<Map<String, dynamic>>> _childrenSubjects =
      {};

  static const _rootLiked = 'liked_songs';
  static const _rootOffline = 'offline_songs';
  static const _rootRecent = 'recently_played';
  static const _rootQueue = 'current_queue';
  static const _rootPlaylists = 'playlists';
  static const _rootSearch = 'search_results';

  static const String _songMediaIdPrefix = 'song:';
  static const String _playlistMediaIdPrefix = 'playlist:';
  static const String _recentMediaIdPrefix = 'recent:';
  static const int _maxSearchResults = 30;
  static const Duration _browserFetchTimeout = Duration(seconds: 15);

  String _recentMediaId(String ytid) => '$_recentMediaIdPrefix$ytid';

  String? _ytidFromMediaId(String mediaId) {
    if (mediaId.startsWith(_recentMediaIdPrefix)) {
      return mediaId.substring(_recentMediaIdPrefix.length);
    }
    final song = _parseSongMediaId(mediaId);
    if (song != null) return song.container == _rootQueue ? null : song.token;
    return mediaId.isEmpty ? null : mediaId;
  }

  String _songMediaId(String containerId, String token) =>
      '$_songMediaIdPrefix$containerId:$token';

  ({String container, String token})? _parseSongMediaId(String mediaId) {
    if (!mediaId.startsWith(_songMediaIdPrefix)) return null;
    final body = mediaId.substring(_songMediaIdPrefix.length);
    final separator = body.lastIndexOf(':');
    if (separator <= 0 || separator >= body.length - 1) return null;
    return (
      container: body.substring(0, separator),
      token: body.substring(separator + 1),
    );
  }

  String _playlistMediaId(String source, String id) =>
      '$_playlistMediaIdPrefix$source:$id';

  ({String source, String id})? _parsePlaylistMediaId(String mediaId) {
    if (!mediaId.startsWith(_playlistMediaIdPrefix)) return null;
    final body = mediaId.substring(_playlistMediaIdPrefix.length);
    final separator = body.indexOf(':');
    if (separator <= 0 || separator >= body.length - 1) return null;
    return (
      source: body.substring(0, separator),
      id: body.substring(separator + 1),
    );
  }

  String? _songToken(Map song, String containerId) => containerId == _rootQueue
      ? _host.ensureBrowserQueueEntryId(song)
      : songYtid(song);

  int _indexOfSongToken(List<Map> songs, String containerId, String token) =>
      songs.indexWhere((song) => _songToken(song, containerId) == token);

  String _playlistSource(Map playlist) =>
      playlist['source']?.toString() ?? 'user-created';

  String? _playlistIdOf(Map playlist) {
    final id = (playlist['ytid'] ?? playlist['id'])?.toString();
    return id == null || id.isEmpty ? null : id;
  }

  List<Map> _browsablePlaylists() => [
    ...getUserCustomPlaylists(),
    ...getLikedPlaylistItems(),
  ];

  MediaItem _systemMediaItem(
    Map<String, dynamic> song,
    String mediaId, {
    bool? playable,
  }) {
    final artist = song['artist']?.toString().trim() ?? '';
    return mapToMediaItem(song).copyWith(
      id: mediaId,
      playable: playable,
      displayTitle: song['title']?.toString(),
      displaySubtitle: artist.isEmpty ? 'Musify' : artist,
    );
  }

  MediaItem? _mediaItemForResumption(Map song) {
    final normalisedSong = _host.normaliseResumableSong(song);
    if (normalisedSong == null) return null;

    return _systemMediaItem(
      normalisedSong,
      _recentMediaId(normalisedSong['ytid'].toString()),
    );
  }

  Map? _findSongByYtid(String? ytid) {
    if (ytid == null || ytid.isEmpty) return null;

    for (final source in [
      _host.browserQueue,
      userRecentlyPlayed.value,
      userOfflineSongs.value,
      userLikedSongsList.value,
    ]) {
      final song = findSongByYtid(source, ytid);
      if (song != null) return song;
    }

    return null;
  }

  MediaItem _browsableCategory(
    String id,
    String title, {
    int playableHint = AndroidContentStyle.listItemHintValue,
  }) => MediaItem(
    id: id,
    title: title,
    playable: false,
    extras: {
      'isBrowsable': true,
      AndroidContentStyle.playableHintKey: playableHint,
    },
  );

  MediaItem? _browsableSong(Map song, String containerId) {
    final token = _songToken(song, containerId);
    if (token == null || token.isEmpty) return null;

    final normalised = _host.normaliseResumableSong(song);
    if (normalised == null) return null;

    return _systemMediaItem(
      normalised,
      _songMediaId(containerId, token),
      playable: true,
    );
  }

  List<MediaItem> _browsableSongs(Iterable songs, String containerId) {
    final items = <MediaItem>[];
    for (final song in songs.whereType<Map>()) {
      final item = _browsableSong(song, containerId);
      if (item != null) items.add(item);
    }
    return items;
  }

  List<MediaItem> _emptyCategory(String parentMediaId, String message) => [
    MediaItem(
      id: '$parentMediaId:__empty__',
      title: message,
      playable: false,
      extras: const {'isBrowsable': false},
    ),
  ];

  String? _emptyCategoryMessage(String parentMediaId) {
    switch (parentMediaId) {
      case _rootQueue:
        return 'Nothing in the queue yet';
      case _rootLiked:
        return 'No liked songs yet';
      case _rootOffline:
        return 'Nothing downloaded yet';
      case _rootRecent:
        return 'Nothing played yet';
      case _rootPlaylists:
        return 'No playlists yet';
    }
    return _parsePlaylistMediaId(parentMediaId) == null
        ? null
        : 'This playlist is empty';
  }

  MediaItem _playlistMediaItem(Map playlist, String id) {
    final image = playlist['image']?.toString();
    return MediaItem(
      id: _playlistMediaId(_playlistSource(playlist), id),
      title: playlist['title']?.toString() ?? 'Playlist',
      playable: false,
      artUri: image == null || image.isEmpty ? null : Uri.tryParse(image),
      extras: const {'isBrowsable': true},
    );
  }

  List<MediaItem> _playlistChildren() {
    final items = <MediaItem>[];
    for (final playlist in _browsablePlaylists()) {
      final id = _playlistIdOf(playlist);
      if (id != null) items.add(_playlistMediaItem(playlist, id));
    }
    return items;
  }

  Future<List<Map>> _songsForPlaylist(String source, String id) async {
    final playlist = _browsablePlaylists().firstWhere(
      (playlist) =>
          _playlistIdOf(playlist) == id && _playlistSource(playlist) == source,
      orElse: () => const {},
    );
    if (playlist.isEmpty) return const [];

    final inline = playlist['list'];
    if (inline is List && inline.isNotEmpty) {
      return inline.whereType<Map>().toList();
    }

    if (source == 'user-created' || offlineMode.value) return const [];

    try {
      final songs = await getSongsFromPlaylist(
        id,
        playlistImage: playlist['image']?.toString(),
      ).timeout(_browserFetchTimeout);
      return songs.whereType<Map>().toList();
    } catch (error, stackTrace) {
      _host.logBrowserError(
        'Error loading playlist $id for the media browser',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  Future<List<Map>> _songsForContainer(String containerId) async {
    switch (containerId) {
      case _rootQueue:
        return List<Map>.from(_host.browserQueue);
      case _rootLiked:
        return userLikedSongsList.value.whereType<Map>().toList();
      case _rootOffline:
        return userOfflineSongs.value.whereType<Map>().toList();
      case _rootRecent:
        return userRecentlyPlayed.value.whereType<Map>().toList();
      case _rootSearch:
        return List<Map>.from(_lastSearchResults);
    }

    final playlist = _parsePlaylistMediaId(containerId);
    return playlist == null
        ? const []
        : _songsForPlaylist(playlist.source, playlist.id);
  }

  Future<List<MediaItem>> children(String parentMediaId) async {
    try {
      return await _buildChildren(parentMediaId);
    } catch (error, stackTrace) {
      _host.logBrowserError(
        'Error building browse children for $parentMediaId',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  Future<List<MediaItem>> _buildChildren(String parentMediaId) async {
    if (parentMediaId == AudioService.recentRootId) {
      final recentSong = _host.latestResumableSong();
      final recentItem = recentSong == null
          ? null
          : _mediaItemForResumption(recentSong);
      return recentItem == null ? [] : [recentItem];
    }

    if (parentMediaId == AudioService.browsableRootId) {
      return [
        _browsableCategory(_rootQueue, 'Now Playing Queue'),
        _browsableCategory(_rootLiked, 'Liked Songs'),
        _browsableCategory(
          _rootPlaylists,
          'Playlists',
          playableHint: AndroidContentStyle.gridItemHintValue,
        ),
        _browsableCategory(_rootOffline, 'Downloaded'),
        _browsableCategory(_rootRecent, 'Recently Played'),
      ];
    }

    if (parentMediaId == _rootPlaylists) {
      final playlists = _playlistChildren();
      return playlists.isEmpty
          ? _emptyCategory(parentMediaId, _emptyCategoryMessage(parentMediaId)!)
          : playlists;
    }

    final songs = await _songsForContainer(parentMediaId);
    if (songs.isNotEmpty) return _browsableSongs(songs, parentMediaId);

    final message = _emptyCategoryMessage(parentMediaId);
    return message == null ? const [] : _emptyCategory(parentMediaId, message);
  }

  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    return _childrenSubjects.putIfAbsent(
      parentMediaId,
      () => BehaviorSubject<Map<String, dynamic>>.seeded(<String, dynamic>{}),
    );
  }

  void _notifyChildrenChanged(List<String> parentMediaIds) {
    for (final parentMediaId in parentMediaIds) {
      final subject = _childrenSubjects[parentMediaId];
      if (subject != null && !subject.isClosed) {
        subject.add(<String, dynamic>{});
      }
    }
  }

  void setupMediaBrowserSubscriptions() {
    void watch(Listenable source, List<String> parents) {
      source.addListener(() => _notifyChildrenChanged(parents));
    }

    watch(userLikedSongsList, const [_rootLiked]);
    watch(userOfflineSongs, const [_rootOffline]);
    watch(userRecentlyPlayed, const [_rootRecent, AudioService.recentRootId]);
    watch(userCustomPlaylists, const [_rootPlaylists]);
    watch(userLikedPlaylists, const [_rootPlaylists]);
    watch(userPlaylistFolders, const [_rootPlaylists]);

    _host.browserQueueStream
        .throttleTime(const Duration(seconds: 2), trailing: true)
        .listen(
          (_) => _notifyChildrenChanged(const [_rootQueue]),
          onError: (error, stackTrace) {
            _host.logBrowserError(
              'Queue browse stream error',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  bool _songMatches(Map song, String needle) {
    final title = song['title']?.toString().toLowerCase() ?? '';
    if (title.contains(needle)) return true;
    final artist = song['artist']?.toString().toLowerCase() ?? '';
    return artist.contains(needle);
  }

  Future<List<Map>> _searchSongs(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final needle = trimmed.toLowerCase();
    final results = <Map>[];
    final seen = <String>{};

    void collect(Iterable songs) {
      for (final song in songs.whereType<Map>()) {
        if (results.length >= _maxSearchResults) return;
        final ytid = songYtid(song);
        if (ytid == null || seen.contains(ytid)) continue;
        if (!_songMatches(song, needle)) continue;
        seen.add(ytid);
        results.add(song);
      }
    }

    collect(userLikedSongsList.value);
    collect(userOfflineSongs.value);
    collect(userRecentlyPlayed.value);
    collect(_host.browserQueue);

    if (results.length >= _maxSearchResults || offlineMode.value) {
      return results;
    }

    try {
      final online = await fetchSongsList(trimmed)
          .timeout(_browserFetchTimeout);
      for (final song in online.whereType<Map>()) {
        if (results.length >= _maxSearchResults) break;
        final ytid = songYtid(song);
        if (ytid == null || !seen.add(ytid)) continue;
        results.add(song);
      }
    } catch (error, stackTrace) {
      _host.logBrowserError(
        'Media browser search failed for "$trimmed"',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return results;
  }

  Future<List<MediaItem>> search(String query) async {
    try {
      final results = await _searchSongs(query);
      _lastSearchResults = results;
      return _browsableSongs(results, _rootSearch);
    } catch (error, stackTrace) {
      _host.logBrowserError(
        'Error in media browser search',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  Future<void> playFromSearch(String query) async {
    try {
      if (query.trim().isEmpty) {
        if (_host.browserQueue.isNotEmpty) {
          await _host.resumeAudio();
          return;
        }
        final recentSong = _host.latestResumableSong();
        if (recentSong != null) await _host.playResumableSong(recentSong);
        return;
      }

      final results = await _searchSongs(query);
      if (results.isEmpty) {
        _host.logBrowserError('playFromSearch: no match for "$query"');
        return;
      }

      _lastSearchResults = results;
      await _host.playBrowserPlaylist(results, songIndex: 0);
    } catch (error, stackTrace) {
      _host.logBrowserError(
        'Error in media browser playFromSearch',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<MediaItem?> mediaItemForId(String mediaId) async {
    try {
      final parsed = _parseSongMediaId(mediaId);
      if (parsed != null) {
        final songs = await _songsForContainer(parsed.container);
        final index = _indexOfSongToken(songs, parsed.container, parsed.token);
        if (index >= 0) return _browsableSong(songs[index], parsed.container);
      }

      final song = _findSongByYtid(_ytidFromMediaId(mediaId));
      return song == null ? null : _mediaItemForResumption(song);
    } catch (error, stackTrace) {
      _host.logBrowserError(
        'Error in media browser getMediaItem',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> prepareFromId(String mediaId) async {
    final item = await mediaItemForId(mediaId);
    if (item != null) _host.publishPreparedBrowserItem(item);
  }

  Future<bool> playFromMediaId(String mediaId) async {
    try {
      final parsed = _parseSongMediaId(mediaId);
      if (parsed != null &&
          await _playFromContainer(parsed.container, parsed.token)) {
        return true;
      }

      final song = _findSongByYtid(_ytidFromMediaId(mediaId));
      if (song != null) {
        await _host.playResumableSong(song);
        return true;
      }

      _host.logBrowserError('No playable song found for media id: $mediaId');
    } catch (error, stackTrace) {
      _host.logBrowserError(
        'Error in media browser playFromMediaId',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return false;
  }

  Future<bool> _playFromContainer(String containerId, String token) async {
    final songs = await _songsForContainer(containerId);
    if (songs.isEmpty) return false;

    final index = _indexOfSongToken(songs, containerId, token);
    if (index < 0) return false;

    if (containerId == _rootQueue) {
      await _host.skipToQueueItem(index);
      return true;
    }

    await _host.playBrowserPlaylist(songs, songIndex: index);
    return true;
  }
}
