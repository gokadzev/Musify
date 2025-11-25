/*
 *     Copyright (C) 2025 Valeri Gokadze
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

import 'package:audio_service/audio_service.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/mediaitem.dart';

/// Helper class for Android Auto media browsing support.
class AndroidAutoService {
  // Android Auto media IDs
  static const String queueId = '__QUEUE__';
  static const String likedSongsId = '__LIKED_SONGS__';
  static const String recentSongsId = '__RECENT_SONGS__';
  static const String offlineSongsId = '__OFFLINE_SONGS__';
  static const String userPlaylistsId = '__USER_PLAYLISTS__';
  static const String customPlaylistsId = '__CUSTOM_PLAYLISTS__';
  static const String playlistPrefix = 'playlist:';
  static const String customPlaylistPrefix = 'playlist:custom:';

  // Extras keys for Android Auto media items
  static const String sourceKey = 'aaSource';
  static const String indexKey = 'aaIndex';
  static const String songKey = 'aaSong';

  /// Gets children for a given parent media ID.
  /// Returns a list of [MediaItem] that can be browsed in Android Auto.
  static Future<List<MediaItem>> getChildren(
    String parentMediaId,
    List<MediaItem>? currentQueue,
  ) async {
    // Root level - show main browsable categories
    // AudioService.browsableRootId is 'root' (hardcoded in the Android plugin)
    if (parentMediaId == AudioService.browsableRootId) {
      return _buildRootMediaItems(currentQueue);
    }

    // Recent root for Android Auto resume feature
    if (parentMediaId == AudioService.recentRootId) {
      return _buildRecentSongsMediaItems();
    }

    if (parentMediaId == queueId) {
      return currentQueue ?? const [];
    }

    if (parentMediaId == likedSongsId) {
      return _buildLikedSongsMediaItems();
    }

    if (parentMediaId == recentSongsId) {
      return _buildRecentSongsMediaItems();
    }

    if (parentMediaId == offlineSongsId) {
      return _buildOfflineSongsMediaItems();
    }

    if (parentMediaId == userPlaylistsId) {
      return _buildUserPlaylistsMediaItems();
    }

    if (parentMediaId == customPlaylistsId) {
      return _buildCustomPlaylistsMediaItems();
    }

    if (parentMediaId.startsWith(customPlaylistPrefix)) {
      final playlistId = parentMediaId.substring(customPlaylistPrefix.length);
      return _buildCustomPlaylistSongsMediaItems(playlistId);
    }

    if (parentMediaId.startsWith(playlistPrefix)) {
      final playlistId = parentMediaId.substring(playlistPrefix.length);
      return _buildUserPlaylistSongsMediaItems(playlistId);
    }

    return [];
  }

  /// Handles play requests from Android Auto.
  /// Returns the list of songs and the start index to play.
  static Future<({List<Map<String, dynamic>> songs, int startIndex})?>
  handlePlayRequest(String mediaId, Map<String, dynamic>? extras) async {
    final sourceId = extras?[sourceKey] as String?;
    if (sourceId == null) {
      return null;
    }

    final songs = await _getSongsForSource(sourceId);
    if (songs.isEmpty) {
      return null;
    }

    final indexFromExtras = extras?[indexKey] as int?;
    final rawSongExtras = extras?[songKey];
    Map<String, dynamic>? songExtras;
    if (rawSongExtras is Map<String, dynamic>) {
      songExtras = rawSongExtras;
    } else if (rawSongExtras is Map) {
      songExtras = Map<String, dynamic>.from(rawSongExtras);
    }

    final startIndex = _resolveStartIndex(
      songs,
      mediaId,
      indexFromExtras,
      songExtras,
    );

    return (songs: songs, startIndex: startIndex);
  }

  /// Builds the root-level browsable categories
  static List<MediaItem> _buildRootMediaItems(List<MediaItem>? currentQueue) {
    final items = <MediaItem>[];

    if (currentQueue != null && currentQueue.isNotEmpty) {
      items.add(const MediaItem(id: queueId, title: 'Queue', playable: false));
    }

    // Always surface liked songs so users have a starting point
    items.add(
      const MediaItem(id: likedSongsId, title: 'Liked Songs', playable: false),
    );

    if (userRecentlyPlayed.isNotEmpty) {
      items.add(
        const MediaItem(
          id: recentSongsId,
          title: 'Recently Played',
          playable: false,
        ),
      );
    }

    if (userOfflineSongs.isNotEmpty) {
      items.add(
        const MediaItem(
          id: offlineSongsId,
          title: 'Offline Songs',
          playable: false,
        ),
      );
    }

    if (userPlaylists.value.isNotEmpty) {
      items.add(
        const MediaItem(
          id: userPlaylistsId,
          title: 'Your Playlists',
          playable: false,
        ),
      );
    }

    if (userCustomPlaylists.value.isNotEmpty) {
      items.add(
        const MediaItem(
          id: customPlaylistsId,
          title: 'Custom Playlists',
          playable: false,
        ),
      );
    }

    return items;
  }

  static List<MediaItem> _buildLikedSongsMediaItems() {
    final songs = _cloneSongList(userLikedSongsList);
    return _buildSongMediaItemsFromList(songs, likedSongsId);
  }

  static List<MediaItem> _buildRecentSongsMediaItems() {
    final songs = _cloneSongList(userRecentlyPlayed);
    return _buildSongMediaItemsFromList(songs, recentSongsId);
  }

  static List<MediaItem> _buildOfflineSongsMediaItems() {
    final songs = _cloneSongList(userOfflineSongs);
    return _buildSongMediaItemsFromList(songs, offlineSongsId);
  }

  static Future<List<MediaItem>> _buildUserPlaylistsMediaItems() async {
    try {
      final playlists = await getUserPlaylists();
      return playlists
          .map<MediaItem?>((playlist) {
            if (playlist is! Map) return null;
            final playlistId = playlist['ytid']?.toString();
            if (playlistId == null || playlistId.isEmpty) return null;

            return MediaItem(
              id: '$playlistPrefix$playlistId',
              title: playlist['title']?.toString() ?? 'Unnamed Playlist',
              displaySubtitle: playlist['list'] is List
                  ? '${(playlist['list'] as List).length} songs'
                  : null,
              artUri: playlist['image'] != null
                  ? Uri.parse(playlist['image'].toString())
                  : null,
              playable: false,
            );
          })
          .whereType<MediaItem>()
          .toList();
    } catch (e, stackTrace) {
      logger.log(
        'Error building user playlists for Android Auto',
        e,
        stackTrace,
      );
      return [];
    }
  }

  static List<MediaItem> _buildCustomPlaylistsMediaItems() {
    return userCustomPlaylists.value
        .map<MediaItem?>((playlist) {
          if (playlist is! Map) return null;
          final playlistId =
              playlist['ytid']?.toString() ?? playlist['title']?.toString();
          if (playlistId == null || playlistId.isEmpty) return null;

          return MediaItem(
            id: '$customPlaylistPrefix$playlistId',
            title: playlist['title']?.toString() ?? 'Unnamed Playlist',
            artUri: playlist['image'] != null
                ? Uri.parse(playlist['image'].toString())
                : null,
            playable: false,
          );
        })
        .whereType<MediaItem>()
        .toList();
  }

  static Future<List<MediaItem>> _buildUserPlaylistSongsMediaItems(
    String playlistId,
  ) async {
    try {
      final playlist = await getPlaylistInfoForWidget(playlistId);
      final songs = _cloneSongList((playlist?['list'] as List?) ?? const []);
      return _buildSongMediaItemsFromList(songs, '$playlistPrefix$playlistId');
    } catch (e, stackTrace) {
      logger.log('Error building user playlist songs', e, stackTrace);
      return [];
    }
  }

  static List<MediaItem> _buildCustomPlaylistSongsMediaItems(
    String playlistId,
  ) {
    try {
      final playlist = userCustomPlaylists.value.firstWhere((p) {
        if (p is! Map) return false;
        final ytid = p['ytid']?.toString();
        final title = p['title']?.toString();
        return ytid == playlistId || title == playlistId;
      }, orElse: () => <String, dynamic>{});

      if (playlist is Map && playlist.isNotEmpty) {
        final songs = _cloneSongList(playlist['list'] as List? ?? const []);
        return _buildSongMediaItemsFromList(
          songs,
          '$customPlaylistPrefix$playlistId',
        );
      }
      return [];
    } catch (e, stackTrace) {
      logger.log('Error building custom playlist songs', e, stackTrace);
      return [];
    }
  }

  static List<MediaItem> _buildSongMediaItemsFromList(
    List<Map<String, dynamic>> songs,
    String sourceId,
  ) {
    return List<MediaItem>.generate(songs.length, (index) {
      final baseItem = mapToMediaItem(songs[index]);
      return _decorateMediaItem(
        baseItem,
        sourceId: sourceId,
        index: index,
        song: songs[index],
      );
    });
  }

  static MediaItem _decorateMediaItem(
    MediaItem item, {
    required String sourceId,
    required int index,
    Map<String, dynamic>? song,
  }) {
    final extras = <String, dynamic>{
      if (item.extras != null) ...item.extras!,
      sourceKey: sourceId,
      indexKey: index,
      if (song != null) songKey: song,
    };

    return item.copyWith(extras: extras);
  }

  static List<Map<String, dynamic>> _cloneSongList(List<dynamic> songs) {
    final sanitized = <Map<String, dynamic>>[];
    for (final entry in songs) {
      if (entry is! Map) continue;
      final song = Map<String, dynamic>.from(entry);
      final existingId = song['id'];
      if (existingId == null || existingId.toString().isEmpty) {
        final fallbackId = (song['ytid'] ?? song.hashCode).toString();
        song['id'] = fallbackId;
      } else if (existingId is! String) {
        song['id'] = existingId.toString();
      }
      sanitized.add(song);
    }
    return sanitized;
  }

  static Future<List<Map<String, dynamic>>> _getSongsForSource(
    String sourceId,
  ) async {
    if (sourceId == likedSongsId) {
      return _cloneSongList(userLikedSongsList);
    }

    if (sourceId == recentSongsId) {
      return _cloneSongList(userRecentlyPlayed);
    }

    if (sourceId == offlineSongsId) {
      return _cloneSongList(userOfflineSongs);
    }

    if (sourceId.startsWith(customPlaylistPrefix)) {
      final playlistId = sourceId.substring(customPlaylistPrefix.length);
      final playlist = userCustomPlaylists.value.firstWhere((p) {
        if (p is! Map) return false;
        final ytid = p['ytid']?.toString();
        final title = p['title']?.toString();
        return ytid == playlistId || title == playlistId;
      }, orElse: () => <String, dynamic>{});
      if (playlist is Map && playlist.isNotEmpty) {
        return _cloneSongList(playlist['list'] as List? ?? const []);
      }
      return [];
    }

    if (sourceId.startsWith(playlistPrefix)) {
      final playlistId = sourceId.substring(playlistPrefix.length);
      final playlist = await getPlaylistInfoForWidget(playlistId);
      return _cloneSongList((playlist?['list'] as List?) ?? const []);
    }

    return [];
  }

  static int _resolveStartIndex(
    List<Map<String, dynamic>> songs,
    String mediaId,
    int? indexFromExtras,
    Map<String, dynamic>? songExtras,
  ) {
    if (songs.isEmpty) {
      return 0;
    }

    if (indexFromExtras != null &&
        indexFromExtras >= 0 &&
        indexFromExtras < songs.length) {
      return indexFromExtras;
    }

    final requestedId =
        songExtras?['id']?.toString() ??
        songExtras?['ytid']?.toString() ??
        mediaId;
    final matchIndex = songs.indexWhere((song) {
      final songId = song['id']?.toString();
      final songYtid = song['ytid']?.toString();
      return songId == requestedId || songYtid == requestedId;
    });

    return matchIndex != -1 ? matchIndex : 0;
  }
}
