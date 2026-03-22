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

import 'dart:math';
import 'package:musify/services/playlist_download_service.dart';

class PlaylistUtils {
  static bool isPlaylistOffline(Map playlist) => offlinePlaylistService
      .isPlaylistDownloaded(playlist['ytid']?.toString() ?? '');

  static bool folderHasOfflinePlaylists(Map folder) {
    final playlists = folder['playlists'] as List? ?? [];
    return playlists.any((p) => p is Map && isPlaylistOffline(p));
  }

  static bool isFolder(Map data) => data.containsKey('playlists');

  static bool isCustomPlaylist(Map playlist) {
    final source = playlist['source']?.toString();
    final playlistId = playlist['ytid']?.toString();
    return source == 'user-created' ||
        (playlistId != null && playlistId.startsWith('customId-'));
  }

  static String generateCustomPlaylistId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = Random().nextInt(0x7fffffff);
    return 'customId-$timestamp-$randomSuffix';
  }

  static List<dynamic> filterOfflinePlaylistsNotInFolders(
    List<dynamic> rawOfflinePlaylists,
    List<dynamic> folders,
  ) {
    final folderPlaylistIds = folders
        .expand(
          (f) => (f['playlists'] as List? ?? []).map(
            (p) => p is Map ? p['ytid']?.toString() : p?.toString(),
          ),
        )
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    return rawOfflinePlaylists
        .where(
          (p) => p is Map && !folderPlaylistIds.contains(p['ytid']?.toString()),
        )
        .toList();
  }
}
