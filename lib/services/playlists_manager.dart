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

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:musify/database/albums.db.dart';
import 'package:musify/database/playlists.db.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/playlist_download_service.dart';
import 'package:musify/services/proxy_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/playlist_utils.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

List<Map> playlists = [...playlistsDB, ...albumsDB];
final userPlaylists = ValueNotifier<List<String>>(
  List<String>.from(Hive.box('user').get('playlists', defaultValue: [])),
);
final userCustomPlaylists = ValueNotifier<List<Map>>(
  List<Map>.from(Hive.box('user').get('customPlaylists', defaultValue: [])),
);
final userLikedPlaylists = ValueNotifier<List<Map>>(
  List<Map>.from(Hive.box('user').get('likedPlaylists', defaultValue: [])),
);
final userPlaylistFolders = ValueNotifier<List<Map>>(
  List<Map>.from(Hive.box('user').get('playlistFolders', defaultValue: [])),
);
final pinnedPlaylistIds = ValueNotifier<List<String>>(
  List<String>.from(
    Hive.box('user').get('pinnedPlaylistIds', defaultValue: <String>[]),
  ),
);
final onlinePlaylists = ValueNotifier<List<Map>>([]);
const _artistSongsLimit = 100;

void _updateOnlineCache(Map? p) {
  if (p != null && !onlinePlaylists.value.any((x) => x['ytid'] == p['ytid'])) {
    onlinePlaylists.value = [...onlinePlaylists.value, p];
  }
}

Map? _searchAppPlaylistsById(String id) {
  for (final p in userCustomPlaylists.value) {
    if (p['ytid']?.toString() == id) return p;
  }
  for (final f in userPlaylistFolders.value) {
    for (final p in (f['playlists'] as List? ?? [])) {
      if (p['ytid']?.toString() == id) return p as Map;
    }
  }
  for (final p in userLikedPlaylists.value) {
    if (p['ytid']?.toString() == id) return p;
  }
  for (final p in onlinePlaylists.value) {
    if (p['ytid']?.toString() == id) return p;
  }
  for (final p in offlinePlaylistService.offlinePlaylists.value) {
    if (p['ytid']?.toString() == id) return p as Map;
  }
  for (final p in playlists) {
    if (p['ytid']?.toString() == id) return p;
  }
  return null;
}

List<Map> resolvePinnedPlaylists(List<String> ids) {
  if (ids.isEmpty) return [];
  final result = <Map>[];
  for (final id in ids) {
    final match = _searchAppPlaylistsById(id);
    if (match != null) result.add(match);
  }
  return result;
}

const pinnedPlaylistsLimit = 5;

var _playlistLikeUpdateToken = 0;
final _latestPlaylistLikeUpdateTokens = <String, int>{};

Future<List<dynamic>> getUserPlaylists() async {
  final futures = userPlaylists.value.map((playlistID) async {
    try {
      final plist = await ytClient.playlists.get(playlistID);
      return {
        'ytid': plist.id.toString(),
        'title': plist.title,
        'image': null,
        'source': 'user-youtube',
        'list': [],
      };
    } catch (e, stackTrace) {
      logger.log(
        'Error occurred while fetching the playlist:',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'ytid': playlistID,
        'title': 'Failed playlist',
        'image': null,
        'source': 'user-youtube',
        'list': [],
      };
    }
  });

  final results = await Future.wait(futures);
  for (final result in results) {
    _updateOnlineCache(result);
  }
  return results.toList();
}

Future<String> addUserPlaylist(String input, BuildContext context) async {
  String? playlistId = input;

  if (input.startsWith('http://') || input.startsWith('https://')) {
    playlistId = extractYoutubePlaylistId(input);

    if (playlistId == null) {
      return '${context.l10n!.notYTlist}!';
    }
  }

  try {
    if (playlistExistsAnywhere(playlistId)) {
      return '${context.l10n!.playlistAlreadyExists}!';
    }

    final playlist = await ytClient.playlists.get(playlistId);
    if (playlist.title.isEmpty) {
      return '${context.l10n!.invalidYouTubePlaylist}!';
    }

    userPlaylists.value = [...userPlaylists.value, playlistId];
    unawaited(addOrUpdateData<List>('user', 'playlists', userPlaylists.value));
    return '${context.l10n!.addedSuccess}!';
  } catch (e, stackTrace) {
    logger.log('Error adding user playlist', error: e, stackTrace: stackTrace);
    return '${context.l10n!.error}: $e';
  }
}

(String message, String playlistId) createCustomPlaylist(
  String playlistName,
  String? image,
  BuildContext context,
) {
  final newPlaylistId = PlaylistUtils.generateCustomPlaylistId();
  final creationTime = DateTime.now().millisecondsSinceEpoch;
  final customPlaylist = {
    'ytid': newPlaylistId,
    'title': playlistName,
    'source': 'user-created',
    if (image != null) 'image': image,
    'list': [],
    'createdAt': creationTime,
  };
  userCustomPlaylists.value = [...userCustomPlaylists.value, customPlaylist];
  unawaited(
    addOrUpdateData<List>('user', 'customPlaylists', userCustomPlaylists.value),
  );
  return ('${context.l10n!.addedSuccess}!', newPlaylistId);
}

String addSongInCustomPlaylist(
  BuildContext context,
  String playlistId,
  Map song, {
  int? indexToInsert,
}) {
  final found = _findCustomPlaylist(playlistId);
  final customPlaylist = found?.playlist;
  final isFromFolder = found?.isFromFolder ?? false;

  if (customPlaylist != null) {
    final List<dynamic> playlistSongs = customPlaylist['list'];
    if (playlistSongs.any(
      (playlistElement) => playlistElement['ytid'] == song['ytid'],
    )) {
      return context.l10n!.songAlreadyInPlaylist;
    }
    if (indexToInsert != null) {
      final safeIndex = indexToInsert.clamp(0, playlistSongs.length);
      playlistSongs.insert(safeIndex, song);
    } else {
      playlistSongs.add(song);
    }
    if (isFromFolder) {
      unawaited(
        addOrUpdateData<List>(
          'user',
          'playlistFolders',
          userPlaylistFolders.value,
        ),
      );
    } else {
      unawaited(
        addOrUpdateData<List>(
          'user',
          'customPlaylists',
          userCustomPlaylists.value,
        ),
      );
    }

    return context.l10n!.songAdded;
  } else {
    logger.log('Custom playlist not found for ytid: $playlistId');
    return context.l10n!.error;
  }
}

List<Map> getUserCustomPlaylists() {
  return [
    ...userCustomPlaylists.value
        .where((p) => p['source'] == 'user-created')
        .cast<Map>(),
    for (final folder in userPlaylistFolders.value)
      ...(folder['playlists'] as List<dynamic>? ?? [])
          .where((p) => p['source'] == 'user-created')
          .cast<Map>(),
  ];
}

String addSongsInCustomPlaylist(
  BuildContext context,
  String playlistId,
  List<dynamic> songs,
) {
  final found = _findCustomPlaylist(playlistId);
  final customPlaylist = found?.playlist;
  final isFromFolder = found?.isFromFolder ?? false;

  if (customPlaylist != null) {
    final List<dynamic> playlistSongs = customPlaylist['list'];

    final newSongs = <dynamic>[];
    for (final song in songs) {
      final alreadyExists = playlistSongs.any(
        (playlistElement) => playlistElement['ytid'] == song['ytid'],
      );
      if (!alreadyExists) {
        playlistSongs.add(song);
        newSongs.add(song);
      }
    }

    if (newSongs.isNotEmpty) {
      if (isFromFolder) {
        unawaited(
          addOrUpdateData<List>(
            'user',
            'playlistFolders',
            userPlaylistFolders.value,
          ),
        );
      } else {
        unawaited(
          addOrUpdateData<List>(
            'user',
            'customPlaylists',
            userCustomPlaylists.value,
          ),
        );
      }
      return context.l10n!.addedSuccess;
    } else {
      return context.l10n!.songAlreadyInPlaylist;
    }
  } else {
    logger.log('Custom playlist not found for ytid: $playlistId');
    return context.l10n!.error;
  }
}

bool removeSongFromPlaylist(
  Map playlist,
  Map songToRemove, {
  int? removeOneAtIndex,
}) {
  try {
    if (playlist['list'] == null) return false;

    final playlistSongs = List<dynamic>.from(playlist['list']);
    if (removeOneAtIndex != null) {
      if (removeOneAtIndex < 0 || removeOneAtIndex >= playlistSongs.length) {
        return false;
      }
      playlistSongs.removeAt(removeOneAtIndex);
    } else {
      final initialLength = playlistSongs.length;
      playlistSongs.removeWhere((song) => song['ytid'] == songToRemove['ytid']);
      if (playlistSongs.length == initialLength) return false;
    }

    playlist['list'] = playlistSongs;

    try {
      if (playlist['source'] == 'user-created') {
        final playlistId = playlist['ytid']?.toString();
        final isInFolder =
            playlistId != null &&
            userPlaylistFolders.value.any((folder) {
              final folderPlaylists =
                  folder['playlists'] as List<dynamic>? ?? [];
              return folderPlaylists.any(
                (p) => p['ytid']?.toString() == playlistId,
              );
            });

        if (isInFolder) {
          unawaited(
            addOrUpdateData<List>(
              'user',
              'playlistFolders',
              userPlaylistFolders.value,
            ),
          );
        } else {
          unawaited(
            addOrUpdateData<List>(
              'user',
              'customPlaylists',
              userCustomPlaylists.value,
            ),
          );
        }
      } else {
        unawaited(
          addOrUpdateData<List>('user', 'playlists', userPlaylists.value),
        );
      }
    } catch (e, stackTrace) {
      logger.log(
        'Error saving playlist changes',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }

    return true;
  } catch (e, stackTrace) {
    logger.log(
      'Error while removing song from playlist: ',
      error: e,
      stackTrace: stackTrace,
    );
    return false;
  }
}

void removeUserPlaylist(String playlistId) {
  final normalizedId = playlistId.trim();
  if (normalizedId.isEmpty) return;

  final updatedPlaylists = List<String>.from(userPlaylists.value)
    ..removeWhere((id) => id == normalizedId);
  userPlaylists.value = updatedPlaylists;

  final foldersChanged = _removePlaylistFromFolders(normalizedId);
  final likedChanged = _removePlaylistFromLikedPlaylists(normalizedId);
  _unpinPlaylist(normalizedId);

  unawaited(addOrUpdateData<List>('user', 'playlists', userPlaylists.value));
  if (foldersChanged) {
    unawaited(
      addOrUpdateData<List>(
        'user',
        'playlistFolders',
        userPlaylistFolders.value,
      ),
    );
  }
  if (likedChanged) {
    unawaited(
      addOrUpdateData<List>('user', 'likedPlaylists', userLikedPlaylists.value),
    );
  }
}

void removeUserPlaylistEntry(Map playlist) {
  final playlistId = playlist['ytid']?.toString().trim() ?? '';
  if (playlistId.isEmpty) return;

  final source = playlist['source']?.toString();
  if (PlaylistUtils.isCustomPlaylist(playlist)) {
    removeUserCustomPlaylist(playlistId);
    return;
  }

  if (source == 'user-youtube') {
    removeUserPlaylist(playlistId);
    return;
  }

  final existsInCustom = userCustomPlaylists.value.any(
    (p) => p['ytid']?.toString() == playlistId,
  );

  if (existsInCustom) {
    removeUserCustomPlaylist(playlistId);
  } else {
    removeUserPlaylist(playlistId);
  }
}

void removeUserCustomPlaylist(dynamic playlist) {
  try {
    final playlistId = (playlist is Map ? playlist['ytid'] : playlist)
        ?.toString()
        .trim();
    if (playlistId == null || playlistId.isEmpty) return;

    final updatedPlaylists = List<Map>.from(userCustomPlaylists.value)
      ..removeWhere((p) => p['ytid']?.toString() == playlistId);
    userCustomPlaylists.value = updatedPlaylists;

    final foldersChanged = _removePlaylistFromFolders(playlistId);
    final likedChanged = _removePlaylistFromLikedPlaylists(playlistId);
    _unpinPlaylist(playlistId);

    unawaited(
      addOrUpdateData<List>(
        'user',
        'customPlaylists',
        userCustomPlaylists.value,
      ),
    );
    if (foldersChanged) {
      unawaited(
        addOrUpdateData<List>(
          'user',
          'playlistFolders',
          userPlaylistFolders.value,
        ),
      );
    }
    if (likedChanged) {
      unawaited(
        addOrUpdateData<List>(
          'user',
          'likedPlaylists',
          userLikedPlaylists.value,
        ),
      );
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error removing custom playlist',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

bool _removePlaylistFromFolders(String playlistId) {
  var changed = false;
  final updatedFolders = List<Map>.from(userPlaylistFolders.value);

  for (final folder in updatedFolders) {
    final folderPlaylists = List<Map>.from(folder['playlists'] ?? []);
    final previousLength = folderPlaylists.length;
    folderPlaylists.removeWhere(
      (playlist) => playlist['ytid']?.toString() == playlistId,
    );

    if (folderPlaylists.length != previousLength) {
      folder['playlists'] = folderPlaylists;
      changed = true;
    }
  }

  if (changed) {
    userPlaylistFolders.value = updatedFolders;
  }

  return changed;
}

bool _removePlaylistFromLikedPlaylists(String playlistId) {
  final updatedLikedPlaylists = _deduplicateLikedPlaylists(
    userLikedPlaylists.value,
  )..removeWhere((playlist) => playlist['ytid']?.toString() == playlistId);

  if (_likedPlaylistIdsAreEqual(
    userLikedPlaylists.value,
    updatedLikedPlaylists,
  )) {
    return false;
  }
  userLikedPlaylists.value = List<Map>.from(updatedLikedPlaylists);
  return true;
}

String createPlaylistFolder(String folderName, [BuildContext? context]) {
  if (folderName.trim().isEmpty) {
    return context?.l10n?.enterFolderName ?? 'Please enter a folder name';
  }

  final exists = userPlaylistFolders.value.any(
    (folder) =>
        folder['name'].toString().toLowerCase() ==
        folderName.trim().toLowerCase(),
  );

  if (exists) {
    return context?.l10n?.folderAlreadyExists ?? 'Folder already exists';
  }

  final newFolder = {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'name': folderName.trim(),
    'playlists': <Map>[],
    'createdAt': DateTime.now().millisecondsSinceEpoch,
  };

  userPlaylistFolders.value = [...userPlaylistFolders.value, newFolder];
  unawaited(
    addOrUpdateData<List>('user', 'playlistFolders', userPlaylistFolders.value),
  );
  return context?.l10n?.addedSuccess ?? 'Added successfully';
}

String renamePlaylistFolder(
  String folderId,
  String newName, [
  BuildContext? context,
]) {
  if (newName.trim().isEmpty) {
    return context?.l10n?.enterFolderName ?? 'Please enter a folder name';
  }

  final updatedFolders = List<Map>.from(userPlaylistFolders.value);
  final folderIndex = updatedFolders.indexWhere((f) => f['id'] == folderId);

  if (folderIndex == -1) {
    return context?.l10n?.error ?? 'Error';
  }

  final exists = updatedFolders.any(
    (folder) =>
        folder['id'] != folderId &&
        folder['name'].toString().toLowerCase() == newName.trim().toLowerCase(),
  );

  if (exists) {
    return context?.l10n?.folderAlreadyExists ?? 'Folder already exists';
  }

  updatedFolders[folderIndex]['name'] = newName.trim();
  userPlaylistFolders.value = updatedFolders;

  unawaited(
    addOrUpdateData<List>('user', 'playlistFolders', userPlaylistFolders.value),
  );
  return context?.l10n?.folderUpdated ?? 'Folder updated successfully';
}

String movePlaylistToFolder(
  Map playlist,
  String? folderId,
  BuildContext context,
) {
  try {
    final updatedFolders = List<Map>.from(userPlaylistFolders.value);
    final updatedCustomPlaylists = List<Map>.from(userCustomPlaylists.value);
    final updatedYoutubePlaylists = List<String>.from(userPlaylists.value);

    for (final folder in updatedFolders) {
      final folderPlaylists = List<Map>.from(
        folder['playlists'] ?? [],
      )..removeWhere((p) => p['ytid'] != null && p['ytid'] == playlist['ytid']);
      folder['playlists'] = folderPlaylists;
    }

    if (folderId != null) {
      final targetFolder = updatedFolders.firstWhere(
        (folder) => folder['id'] == folderId,
        orElse: () => {},
      );

      if (targetFolder.isNotEmpty) {
        final folderPlaylists = List<Map>.from(targetFolder['playlists'] ?? [])
          ..add(playlist);
        targetFolder['playlists'] = folderPlaylists;

        if (playlist['source'] == 'user-created') {
          updatedCustomPlaylists.removeWhere(
            (p) => p['ytid'] == playlist['ytid'],
          );
        } else if (playlist['source'] == 'user-youtube') {
          updatedYoutubePlaylists.removeWhere((p) => p == playlist['ytid']);
        }
      } else {
        logger.log(
          'Target folder with id $folderId not found for moving playlist',
        );
        return context.l10n!.error;
      }
    } else {
      if (playlist['source'] == 'user-created') {
        if (!updatedCustomPlaylists.any((p) => p['ytid'] == playlist['ytid'])) {
          updatedCustomPlaylists.add(playlist);
        }
      } else if (playlist['source'] == 'user-youtube') {
        if (!updatedYoutubePlaylists.contains(playlist['ytid'])) {
          updatedYoutubePlaylists.add(playlist['ytid']);
        }
      }
    }

    userPlaylistFolders.value = updatedFolders;
    userCustomPlaylists.value = updatedCustomPlaylists;
    userPlaylists.value = updatedYoutubePlaylists;

    unawaited(
      addOrUpdateData<List>(
        'user',
        'playlistFolders',
        userPlaylistFolders.value,
      ),
    );
    unawaited(
      addOrUpdateData<List>(
        'user',
        'customPlaylists',
        userCustomPlaylists.value,
      ),
    );
    unawaited(addOrUpdateData<List>('user', 'playlists', userPlaylists.value));

    return '${context.l10n!.addedSuccess}!';
  } catch (e, stackTrace) {
    logger.log(
      'Error moving playlist to folder',
      error: e,
      stackTrace: stackTrace,
    );
    return context.l10n!.error;
  }
}

String deletePlaylistFolder(String folderId, [BuildContext? context]) {
  try {
    final updatedFolders = List<Map>.from(userPlaylistFolders.value);
    final folderToDelete = updatedFolders.firstWhere(
      (folder) => folder['id'] == folderId,
      orElse: () => {},
    );

    if (folderToDelete.isNotEmpty) {
      final folderPlaylists = List<Map>.from(folderToDelete['playlists'] ?? []);
      final updatedCustomPlaylists = List<Map>.from(userCustomPlaylists.value);
      final updatedYoutubePlaylists = List<String>.from(userPlaylists.value);

      for (final playlist in folderPlaylists) {
        if (playlist['source'] == 'user-created') {
          if (playlist['ytid'] != null &&
              !updatedCustomPlaylists.any(
                (p) => p['ytid'] == playlist['ytid'],
              )) {
            updatedCustomPlaylists.add(playlist);
          }
        } else if (playlist['source'] == 'user-youtube') {
          if (playlist['ytid'] != null &&
              !updatedYoutubePlaylists.contains(playlist['ytid'])) {
            updatedYoutubePlaylists.add(playlist['ytid']);
          }
        }
      }

      updatedFolders.removeWhere((folder) => folder['id'] == folderId);

      userPlaylistFolders.value = updatedFolders;
      userCustomPlaylists.value = updatedCustomPlaylists;
      userPlaylists.value = updatedYoutubePlaylists;

      unawaited(
        addOrUpdateData<List>(
          'user',
          'playlistFolders',
          userPlaylistFolders.value,
        ),
      );
      unawaited(
        addOrUpdateData<List>(
          'user',
          'customPlaylists',
          userCustomPlaylists.value,
        ),
      );
      unawaited(
        addOrUpdateData<List>('user', 'playlists', userPlaylists.value),
      );

      return context?.l10n?.folderDeleted ?? 'Folder deleted successfully';
    }
    return context?.l10n?.error ?? 'Error';
  } catch (e, stackTrace) {
    logger.log(
      'Error deleting playlist folder',
      error: e,
      stackTrace: stackTrace,
    );
    return context?.l10n?.error ?? 'Error';
  }
}

List<Map> getPlaylistsInFolder(String folderId) {
  try {
    final folder = userPlaylistFolders.value.firstWhere(
      (folder) => folder['id'] == folderId,
      orElse: () => {},
    );
    return List<Map>.from(folder['playlists'] ?? []);
  } catch (e, stackTrace) {
    logger.log(
      'Error getting playlists in folder',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

List<Map> getPlaylistsNotInFolders() {
  final playlistsInFolders = <String>{};
  for (final folder in userPlaylistFolders.value) {
    final folderPlaylists = folder['playlists'] as List<dynamic>? ?? [];
    for (final playlist in folderPlaylists) {
      if (playlist['ytid'] != null) {
        playlistsInFolders.add(playlist['ytid']);
      }
    }
  }

  return userCustomPlaylists.value
      .where((playlist) {
        final playlistId = playlist['ytid'];
        return playlistId == null || !playlistsInFolders.contains(playlistId);
      })
      .toList()
      .cast<Map>();
}

Future<List> getPlaylists({
  String? query,
  int? playlistsNum,
  String type = 'all',
}) async {
  if (playlists.isEmpty || (playlistsNum == null && query == null)) {
    logger.log('No playlists available');
    return [];
  }

  if (query != null && playlistsNum == null) {
    final lowercaseQuery = query.toLowerCase();
    final filteredPlaylists = playlists.where((playlist) {
      final title = playlist['title'].toLowerCase();
      final matchesQuery = title.contains(lowercaseQuery);
      final matchesType =
          type == 'all' ||
          (type == 'album' && playlist['isAlbum'] == true) ||
          (type == 'playlist' && playlist['isAlbum'] != true);
      return matchesQuery && matchesType;
    }).toList();

    final searchTerm = type == 'album' ? '$query album' : query;

    late final Iterable searchResultsIterable;
    try {
      searchResultsIterable = await ytClient.search.searchContent(
        searchTerm,
        filter: TypeFilters.playlist,
      );
    } catch (e, st) {
      logger.log(
        'Error while searching online songs:',
        error: e,
        stackTrace: st,
      );
      if (useProxy.value) {
        final proxyYt = await ProxyManager().getYoutubeExplodeClient();
        if (proxyYt != null) {
          try {
            searchResultsIterable = await proxyYt.search.searchContent(
              searchTerm,
              filter: TypeFilters.playlist,
            );
          } catch (e2, st2) {
            logger.log('Proxy search failed:', error: e2, stackTrace: st2);
            searchResultsIterable = <dynamic>[];
          } finally {
            try {
              proxyYt.close();
            } catch (_) {}
          }
        } else {
          searchResultsIterable = <dynamic>[];
        }
      } else {
        searchResultsIterable = <dynamic>[];
      }
    }

    final existingYtIds = onlinePlaylists.value
        .map((p) => p['ytid'] as String)
        .toSet();

    final newPlaylists = searchResultsIterable
        .whereType<SearchPlaylist>()
        .map((playlist) {
          final playlistMap = {
            'ytid': playlist.id.toString(),
            'title': playlist.title,
            'image': playlist.thumbnails.first.url.toString(),
            'source': 'youtube',
            'list': [],
          };
          if (!existingYtIds.contains(playlistMap['ytid'])) {
            existingYtIds.add(playlistMap['ytid'].toString());
            return playlistMap;
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
    onlinePlaylists.value = [...onlinePlaylists.value, ...newPlaylists];
    return filteredPlaylists.isNotEmpty
        ? filteredPlaylists
        : onlinePlaylists.value
              .where((p) => p['title'].toLowerCase().contains(lowercaseQuery))
              .toList();
  }

  if (playlistsNum != null && query == null) {
    final suggestedPlaylists = List<Map>.from(playlists)..shuffle();
    return suggestedPlaylists.take(playlistsNum).toList();
  }

  if (type != 'all') {
    return playlists.where((playlist) {
      return type == 'album'
          ? playlist['isAlbum'] == true
          : playlist['isAlbum'] != true;
    }).toList();
  }

  return playlists;
}

Future<List<Map<String, dynamic>>> searchArtists(
  String query, {
  int limit = 5,
}) async {
  final normalizedQuery = query.trim();
  if (normalizedQuery.isEmpty) return [];

  final cacheKey = 'search_artists_${normalizedQuery.toLowerCase()}';
  final cachedArtists = await getData('cache', cacheKey);
  if (cachedArtists is List && cachedArtists.isNotEmpty) {
    return cachedArtists
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .take(limit)
        .toList();
  }

  try {
    final results = await ytClient.search.searchContent(
      normalizedQuery,
      filter: TypeFilters.channel,
    );

    final seen = <String>{};
    final artists = <Map<String, dynamic>>[];
    for (final result in results.whereType<SearchChannel>()) {
      final artist = _artistMapFromSearchChannel(result);
      final artistId = artist['ytid']?.toString();
      if (artistId == null || artistId.isEmpty || !seen.add(artistId)) {
        continue;
      }
      artists.add(artist);
      if (artists.length >= limit) break;
    }

    unawaited(addOrUpdateData<List>('cache', cacheKey, artists));
    return artists;
  } catch (e, stackTrace) {
    logger.log(
      'Error while searching artists',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

Future<List<dynamic>> getUserPlaylistsNotInFolders() async {
  final playlistsInFolders = <String>{};
  for (final folder in userPlaylistFolders.value) {
    final folderPlaylists = folder['playlists'] as List<dynamic>? ?? [];
    for (final playlist in folderPlaylists) {
      if (playlist['ytid'] != null && playlist['source'] == 'user-youtube') {
        playlistsInFolders.add(playlist['ytid']);
      }
    }
  }

  final allUserPlaylists = await getUserPlaylists();
  return allUserPlaylists.where((playlist) {
    return !playlistsInFolders.contains(playlist['ytid']);
  }).toList();
}

bool playlistExistsAnywhere(String playlistId) {
  final normalizedId = playlistId.trim();
  if (normalizedId.isEmpty) return false;

  if (userPlaylists.value.any((id) => id == normalizedId)) {
    return true;
  }

  if (userCustomPlaylists.value.any(
    (p) => p['ytid']?.toString() == normalizedId,
  )) {
    return true;
  }

  for (final folder in userPlaylistFolders.value) {
    final folderPlaylists = folder['playlists'] as List<dynamic>? ?? [];
    if (folderPlaylists.any((p) => p['ytid']?.toString() == normalizedId)) {
      return true;
    }
  }

  return false;
}

int findPlaylistIndexByYtId(String ytid) {
  for (var i = 0; i < playlists.length; i++) {
    if (playlists[i]['ytid'] == ytid) {
      return i;
    }
  }
  return -1;
}

Future<Map?> getPlaylistInfoForWidget(
  dynamic id, {
  bool isArtist = false,
  String? artistName,
  String? artistImage,
  String? sourceSongId,
}) async {
  if (id == null) return null;
  final normalizedId = id.toString().trim();
  if (normalizedId.isEmpty || normalizedId == 'null') return null;
  if (isArtist) {
    return _fetchArtistPlaylist(
      normalizedId,
      artistName: artistName,
      artistImage: artistImage,
      sourceSongId: sourceSongId,
    );
  }
  if (normalizedId.startsWith('customId-')) {
    return _findCustomPlaylist(normalizedId)?.playlist;
  }

  final offlinePlaylist = _findOfflinePlaylist(normalizedId);
  if (offlinePlaylist != null) return offlinePlaylist;

  return _fetchYouTubePlaylist(normalizedId);
}

Future<Map> _fetchArtistPlaylist(
  String artistLookup, {
  String? artistName,
  String? artistImage,
  String? sourceSongId,
}) async {
  try {
    final artist = await _resolveArtist(
      artistLookup,
      preferredName: artistName,
      preferredImage: artistImage,
      sourceSongId: sourceSongId,
    );

    if (artist == null) {
      return {
        'ytid': artistLookup,
        'title': artistName ?? artistLookup,
        'image': artistImage,
        'source': 'youtube-artist',
        'isArtist': true,
        'list': [],
      };
    }

    final artistId = artist['ytid']?.toString() ?? artistLookup;
    final cacheKey = 'artist_v4_$artistId';
    final cachedArtist = await getData('cache', cacheKey);
    if (cachedArtist is Map &&
        cachedArtist['list'] is List &&
        (cachedArtist['list'] as List).isNotEmpty) {
      return Map<String, dynamic>.from(cachedArtist);
    }

    final songs = await _loadArtistSongs(artist);
    final artistPlaylist = {
      ...artist,
      'source': 'youtube-artist',
      'isArtist': true,
      'list': songs,
    };

    unawaited(addOrUpdateData<Map>('cache', cacheKey, artistPlaylist));
    return artistPlaylist;
  } catch (e, stackTrace) {
    logger.log(
      'Error fetching artist songs for $artistLookup',
      error: e,
      stackTrace: stackTrace,
    );
    return {
      'ytid': artistLookup,
      'title': artistName ?? artistLookup,
      'image': artistImage,
      'source': 'youtube-artist',
      'isArtist': true,
      'list': [],
    };
  }
}

Future<Map<String, dynamic>?> _resolveArtist(
  String artistLookup, {
  String? preferredName,
  String? preferredImage,
  String? sourceSongId,
}) async {
  final lookup = artistLookup.trim();
  final displayName = preferredName?.trim();
  final seedId = _isChannelId(lookup) ? lookup : null;
  final normalizedSourceSongId = sourceSongId?.trim();
  final candidates = <Map<String, dynamic>>[];
  String? sourceVideoAuthor;
  String? sourceChannelId;

  if (seedId != null) {
    try {
      final channel = await ytClient.channels.get(seedId);
      candidates.add(_artistMapFromChannel(channel));
    } catch (e, stackTrace) {
      logger.log(
        'Could not load seeded artist channel $seedId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  if (seedId == null &&
      normalizedSourceSongId != null &&
      normalizedSourceSongId.isNotEmpty) {
    try {
      final sourceVideo = await ytClient.videos.get(normalizedSourceSongId);
      sourceVideoAuthor = sourceVideo.author.trim();
      sourceChannelId = sourceVideo.channelId.toString();
      if (_isChannelId(sourceChannelId)) {
        final channel = await ytClient.channels.get(sourceChannelId);
        candidates.add(_artistMapFromChannel(channel));
      }
    } catch (e, stackTrace) {
      logger.log(
        'Could not load source video $normalizedSourceSongId for artist lookup',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  final searchTerms = <String>{
    if (displayName != null && displayName.isNotEmpty) displayName,
    if (sourceVideoAuthor != null && sourceVideoAuthor.isNotEmpty)
      sourceVideoAuthor,
    if (seedId == null && lookup.isNotEmpty && lookup != normalizedSourceSongId)
      lookup,
  };

  for (final searchTerm in searchTerms) {
    candidates.addAll(await searchArtists(searchTerm, limit: 8));
  }

  final uniqueCandidates = _dedupeArtists(candidates);
  if (uniqueCandidates.isEmpty) {
    return null;
  }

  uniqueCandidates.sort((a, b) {
    final scoringName = displayName ?? sourceVideoAuthor ?? lookup;
    final scoreA = _scoreArtistCandidate(
      a,
      preferredName: scoringName,
      seedId: seedId,
      sourceChannelId: sourceChannelId,
    );
    final scoreB = _scoreArtistCandidate(
      b,
      preferredName: scoringName,
      seedId: seedId,
      sourceChannelId: sourceChannelId,
    );
    return scoreB.compareTo(scoreA);
  });

  final best = Map<String, dynamic>.from(uniqueCandidates.first);
  if ((best['image'] == null || best['image'].toString().isEmpty) &&
      preferredImage != null &&
      preferredImage.isNotEmpty) {
    best['image'] = preferredImage;
  }

  final bestId = best['ytid']?.toString();
  if (bestId != null && _isChannelId(bestId)) {
    try {
      final channel = await ytClient.channels.get(bestId);
      return {...best, ..._artistMapFromChannel(channel)};
    } catch (e, stackTrace) {
      logger.log(
        'Could not refresh artist channel $bestId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  return best;
}

Future<List<Map<String, dynamic>>> _loadArtistSongs(
  Map<String, dynamic> artist,
) async {
  final artistId = artist['ytid']?.toString() ?? '';
  final artistTitle = artist['title']?.toString() ?? artistId;
  final songs = <Map<String, dynamic>>[
    ...await _searchSongsForArtist(
      artistTitle,
      artistId: artistId,
      maxResults: 80,
    ),
  ];

  if (_isChannelId(artistId)) {
    try {
      var page = await ytClient.channels.getUploadsFromPage(artistId);

      while (songs.length < _artistSongsLimit) {
        for (final video in page) {
          songs.add(returnSongLayout(songs.length, video));
          if (songs.length >= _artistSongsLimit) break;
        }

        if (songs.length >= _artistSongsLimit) break;
        final nextPage = await page.nextPage();
        if (nextPage == null || nextPage.isEmpty) break;
        page = nextPage;
      }
    } catch (e, stackTrace) {
      logger.log(
        'Could not load uploads for artist $artistId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  return _dedupeSongs(songs).take(_artistSongsLimit).toList();
}

Future<List<Map<String, dynamic>>> _searchSongsForArtist(
  String artistName, {
  String? artistId,
  int maxResults = 20,
}) async {
  try {
    final songs = <Map<String, dynamic>>[];
    final searchQueries = <String>{
      '$artistName songs',
      '$artistName official audio',
      '$artistName topic',
      artistName,
    };

    for (final query in searchQueries) {
      final querySongs = await _collectArtistSearchSongs(
        query,
        maxResults: (maxResults / searchQueries.length).ceil() + 12,
      );
      songs.addAll(querySongs);
    }

    final canonicalArtist = _canonicalArtistName(artistName);
    final dedupedSongs = _dedupeSongs(songs)
      ..sort((a, b) {
        final scoreA = _scoreArtistSong(
          a,
          canonicalArtist: canonicalArtist,
          artistId: artistId,
        );
        final scoreB = _scoreArtistSong(
          b,
          canonicalArtist: canonicalArtist,
          artistId: artistId,
        );
        return scoreB.compareTo(scoreA);
      });

    return dedupedSongs.take(maxResults).toList();
  } catch (e, stackTrace) {
    logger.log(
      'Error searching artist songs for $artistName',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

Future<List<Map<String, dynamic>>> _collectArtistSearchSongs(
  String query, {
  required int maxResults,
}) async {
  var results = await ytClient.search.search(query);
  final songs = <Map<String, dynamic>>[];

  while (songs.length < maxResults) {
    for (final video in results) {
      songs.add(returnSongLayout(songs.length, video));
      if (songs.length >= maxResults) break;
    }

    if (songs.length >= maxResults) break;
    final nextPage = await results.nextPage();
    if (nextPage == null || nextPage.isEmpty) break;
    results = nextPage;
  }

  return songs;
}

int _scoreArtistSong(
  Map<String, dynamic> song, {
  required String canonicalArtist,
  String? artistId,
}) {
  final songArtistId = song['artistId']?.toString();
  final videoAuthor = _canonicalArtistName(
    song['videoAuthor']?.toString() ?? '',
  );
  final songArtist = _canonicalArtistName(song['artist']?.toString() ?? '');
  final title = _canonicalArtistName(song['title']?.toString() ?? '');
  var score = 0;

  if (artistId != null && artistId.isNotEmpty && songArtistId == artistId) {
    score += 120;
  }

  if (songArtist == canonicalArtist) {
    score += 100;
  } else if (_sameArtistCandidate(songArtist, canonicalArtist)) {
    score += 55;
  }

  if (videoAuthor == canonicalArtist) {
    score += 90;
  } else if (_sameArtistCandidate(videoAuthor, canonicalArtist)) {
    score += 45;
  }

  if (title.contains(canonicalArtist)) {
    score += 10;
  }

  final searchableText =
      '${song['title'] ?? ''} ${song['artist'] ?? ''} ${song['videoAuthor'] ?? ''}'
          .toLowerCase();
  if (searchableText.contains('cover') ||
      searchableText.contains('reaction') ||
      searchableText.contains('interview')) {
    score -= 35;
  }

  return score;
}

bool _sameArtistCandidate(String candidate, String artist) {
  if (candidate.isEmpty || artist.isEmpty) return false;
  return candidate.contains(artist) || artist.contains(candidate);
}

List<Map<String, dynamic>> _dedupeArtists(List<Map<String, dynamic>> artists) {
  final seen = <String>{};
  final unique = <Map<String, dynamic>>[];
  for (final artist in artists) {
    final id = artist['ytid']?.toString();
    final title = artist['title']?.toString();
    final key = (id != null && id.isNotEmpty) ? id : title;
    if (key == null || key.isEmpty || !seen.add(key)) continue;
    unique.add(artist);
  }
  return unique;
}

List<Map<String, dynamic>> _dedupeSongs(List<Map<String, dynamic>> songs) {
  final seenIds = <String>{};
  final seenTitles = <String>{};
  final unique = <Map<String, dynamic>>[];
  for (final song in songs) {
    final id = song['ytid']?.toString();
    if (id == null || id.isEmpty || !seenIds.add(id)) continue;

    final title = formatSongTitle(song['title']?.toString() ?? '');
    final artist = song['artist']?.toString() ?? '';
    if (title.trim().isEmpty || _sameArtistPageSongTitle(title, artist)) {
      continue;
    }

    final titleKey =
        '${_canonicalArtistName(artist)}:${_canonicalArtistName(title)}';
    if (!seenTitles.add(titleKey)) {
      continue;
    }

    unique.add(song);
  }
  return unique;
}

bool _sameArtistPageSongTitle(String title, String artist) {
  final canonicalTitle = _canonicalArtistName(title);
  final canonicalArtist = _canonicalArtistName(artist);
  return canonicalTitle.isNotEmpty && canonicalTitle == canonicalArtist;
}

Map<String, dynamic> _artistMapFromChannel(Channel channel) {
  return {
    'ytid': channel.id.toString(),
    'title': channel.title,
    'image': channel.logoUrl,
    'bannerImage': channel.bannerUrl,
    'source': 'youtube-artist',
    'isArtist': true,
    'list': [],
  };
}

Map<String, dynamic> _artistMapFromSearchChannel(SearchChannel artist) {
  final thumbnail = artist.thumbnails.isNotEmpty
      ? artist.thumbnails.last.url.toString()
      : null;

  return {
    'ytid': artist.id.toString(),
    'title': artist.name,
    'image': thumbnail,
    'source': 'youtube-artist',
    'isArtist': true,
    'list': [],
  };
}

int _scoreArtistCandidate(
  Map<String, dynamic> artist, {
  required String preferredName,
  String? seedId,
  String? sourceChannelId,
}) {
  final candidateId = artist['ytid']?.toString();
  final candidateName = artist['title']?.toString() ?? '';
  final canonicalCandidate = _canonicalArtistName(candidateName);
  final canonicalPreferred = _canonicalArtistName(preferredName);
  var score = 0;

  if (seedId != null && candidateId == seedId) {
    score += 240;
  }

  if (sourceChannelId != null && candidateId == sourceChannelId) {
    score += 180;
  }

  if (canonicalPreferred.isEmpty || canonicalCandidate.isEmpty) {
    return score;
  }

  if (canonicalCandidate == canonicalPreferred) {
    score += 120;
  } else if (canonicalCandidate.contains(canonicalPreferred) ||
      canonicalPreferred.contains(canonicalCandidate)) {
    score += 60;
  }

  final lowerName = candidateName.toLowerCase();
  if (lowerName.contains('official') ||
      lowerName.contains('vevo') ||
      lowerName.contains('topic')) {
    score += 10;
  }

  return score;
}

String _canonicalArtistName(String value) {
  final cleaned = value
      .toLowerCase()
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\b(official|vevo|topic|music|channel)\b'), '')
      .replaceAll(RegExp('[^a-z0-9]+'), '');

  if (cleaned.isNotEmpty) return cleaned;

  return value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

bool _isChannelId(String value) => ChannelId.validateChannelId(value);

({Map playlist, bool isFromFolder})? _findCustomPlaylist(String playlistId) {
  for (final playlist in userCustomPlaylists.value) {
    if (playlist['ytid'] == playlistId) {
      return (playlist: playlist, isFromFolder: false);
    }
  }
  for (final folder in userPlaylistFolders.value) {
    final folderPlaylists = folder['playlists'] as List<dynamic>? ?? [];
    for (final playlist in folderPlaylists) {
      if (playlist['ytid'] == playlistId) {
        return (playlist: playlist as Map, isFromFolder: true);
      }
    }
  }
  return null;
}

Map? _findOfflinePlaylist(String id) {
  return _findPlaylistById(offlinePlaylistService.offlinePlaylists.value, id);
}

Map? _findPlaylistById(Iterable<dynamic> playlists, String id) {
  for (final playlist in playlists) {
    if (playlist is Map && playlist['ytid']?.toString() == id) {
      return playlist;
    }
  }

  return null;
}

Future<Map?> _fetchYouTubePlaylist(String id) async {
  // 1. Local DB / in-memory caches (no network).
  var playlist = _findPlaylistById(playlists, id);

  // 2. User-added YouTube playlists.
  if (playlist == null) {
    final userPlaylists = await getUserPlaylists();
    playlist = _findPlaylistById(userPlaylists, id);
  }

  // 3. Previously fetched online playlists.
  playlist ??= _findPlaylistById(onlinePlaylists.value, id);

  // 4. Fetch from YouTube as a last resort.
  if (playlist == null) {
    try {
      final ytPlaylist = await ytClient.playlists.get(id);
      playlist = {
        'ytid': ytPlaylist.id.toString(),
        'title': ytPlaylist.title,
        'image': ytPlaylist.thumbnails.mediumResUrl,
        'source': 'user-youtube',
        'list': [],
      };
      _updateOnlineCache(playlist);
    } catch (e, stackTrace) {
      logger.log(
        'Failed to fetch playlist info for id $id',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // 5. Populate the song list if it is absent or empty.
  final list = playlist['list'];
  if (list == null || (list is List && list.isEmpty)) {
    playlist['list'] = await _loadSongsForPlaylist(playlist);
  }

  return playlist;
}

Future<List> _loadSongsForPlaylist(Map playlist) async {
  try {
    final playlistImage = playlist['isAlbum'] == true
        ? playlist['image'] as String?
        : null;
    final songs = await getSongsFromPlaylist(
      playlist['ytid'],
      playlistImage: playlistImage,
    );
    if (!playlists.contains(playlist)) {
      playlists.add(playlist);
    }
    return songs;
  } catch (e, stackTrace) {
    logger.log(
      'Error fetching songs for playlist ${playlist['ytid']}',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

Future<List> getSongsFromPlaylist(
  dynamic playlistId, {
  String? playlistImage,
}) async {
  final songList = await getData('cache', 'playlistSongs$playlistId') ?? [];

  if (songList.isEmpty) {
    await for (final song in ytClient.playlists.getVideos(playlistId)) {
      songList.add(
        returnSongLayout(songList.length, song, playlistImage: playlistImage),
      );
    }

    unawaited(
      addOrUpdateData<List>('cache', 'playlistSongs$playlistId', songList),
    );
  }

  return songList;
}

Future updatePlaylistList(BuildContext context, String playlistId) async {
  final index = findPlaylistIndexByYtId(playlistId);
  if (index != -1) {
    final songList = [];
    await for (final song in ytClient.playlists.getVideos(playlistId)) {
      songList.add(returnSongLayout(songList.length, song));
    }

    playlists[index]['list'] = songList;
    unawaited(
      addOrUpdateData<List>('cache', 'playlistSongs$playlistId', songList),
    );
    showToast(context, context.l10n!.playlistUpdated);
    return playlists[index];
  }
  logger.log('Playlist with id $playlistId not found for update');
  return null;
}

Future<void> renameSongInPlaylist(
  dynamic playlistId,
  dynamic songId,
  String newTitle,
  String newArtist,
) async {
  try {
    final playlist = userCustomPlaylists.value.firstWhere(
      (p) => p['ytid'] == playlistId,
      orElse: () => <String, dynamic>{},
    );

    if (playlist.isNotEmpty && playlist['list'] != null) {
      final songIndex = (playlist['list'] as List).indexWhere(
        (song) => song['ytid'] == songId,
      );

      if (songIndex != -1) {
        final updatedSongs = List<dynamic>.from(playlist['list'] as List);
        updatedSongs[songIndex] =
            Map<String, dynamic>.from(updatedSongs[songIndex] as Map)
              ..['title'] = newTitle
              ..['artist'] = newArtist;

        final updatedPlaylist = Map<String, dynamic>.from(playlist)
          ..['list'] = updatedSongs;

        // Update the playlist in storage
        final updatedPlaylists = userCustomPlaylists.value
            .map((p) => p['ytid'] == playlistId ? updatedPlaylist : p)
            .toList();
        userCustomPlaylists.value = updatedPlaylists;

        // Save to database
        unawaited(
          addOrUpdateData<List>('user', 'customPlaylists', updatedPlaylists),
        );
      }
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error renaming song in playlist',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

Future<void> updatePlaylistLikeStatus(
  String playlistId,
  bool add, {
  Map? playlistData,
}) async {
  try {
    final normalizedPlaylistId = playlistId.trim();
    if (normalizedPlaylistId.isEmpty) return;

    final updateToken = ++_playlistLikeUpdateToken;
    _latestPlaylistLikeUpdateTokens[normalizedPlaylistId] = updateToken;

    final playlistToAdd = add
        ? await _resolvePlaylistForLikedStatus(
            normalizedPlaylistId,
            playlistData,
          )
        : null;

    if (_latestPlaylistLikeUpdateTokens[normalizedPlaylistId] != updateToken) {
      return;
    }

    final updatedLikedPlaylists = _deduplicateLikedPlaylists(
      userLikedPlaylists.value,
    );

    if (add) {
      if (playlistToAdd != null &&
          !updatedLikedPlaylists.any(
            (playlist) => playlist['ytid']?.toString() == normalizedPlaylistId,
          )) {
        updatedLikedPlaylists.add(playlistToAdd);
      }
    } else {
      updatedLikedPlaylists.removeWhere(
        (playlist) => playlist['ytid']?.toString() == normalizedPlaylistId,
      );
    }

    if (_likedPlaylistIdsAreEqual(
      userLikedPlaylists.value,
      updatedLikedPlaylists,
    )) {
      return;
    }

    userLikedPlaylists.value = List<Map>.from(updatedLikedPlaylists);
    unawaited(
      addOrUpdateData<List>('user', 'likedPlaylists', userLikedPlaylists.value),
    );
  } catch (e, stackTrace) {
    logger.log(
      'Error updating playlist like status: ',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

List<Map> _deduplicateLikedPlaylists(Iterable<Map> likedPlaylists) {
  final seenPlaylistIds = <String>{};
  final deduplicatedPlaylists = <Map>[];

  for (final playlist in likedPlaylists) {
    final playlistId = playlist['ytid']?.toString();
    if (playlistId == null || playlistId.isEmpty) {
      deduplicatedPlaylists.add(playlist);
      continue;
    }

    if (seenPlaylistIds.add(playlistId)) {
      deduplicatedPlaylists.add(playlist);
    }
  }

  return deduplicatedPlaylists;
}

bool _likedPlaylistIdsAreEqual(List<Map> previous, List<Map> updated) {
  if (previous.length != updated.length) return false;

  for (var i = 0; i < previous.length; i++) {
    if (previous[i]['ytid']?.toString() != updated[i]['ytid']?.toString()) {
      return false;
    }
  }

  return true;
}

Future<Map?> _resolvePlaylistForLikedStatus(
  String playlistId,
  Map? playlistData,
) async {
  if (playlistData?['ytid']?.toString() == playlistId) {
    return Map<String, dynamic>.from(playlistData!);
  }

  final cachedPlaylist = _searchAppPlaylistsById(playlistId);
  if (cachedPlaylist != null) {
    return Map<String, dynamic>.from(cachedPlaylist);
  }

  final playlistInfo = await getPlaylistInfoForWidget(playlistId);
  return playlistInfo == null ? null : Map<String, dynamic>.from(playlistInfo);
}

bool isPlaylistPinned(String playlistId) =>
    pinnedPlaylistIds.value.contains(playlistId);

bool togglePinnedPlaylist(String playlistId, BuildContext context) {
  final current = List<String>.from(pinnedPlaylistIds.value);
  if (current.contains(playlistId)) {
    current.remove(playlistId);
    pinnedPlaylistIds.value = current;
    unawaited(addOrUpdateData<List>('user', 'pinnedPlaylistIds', current));
    return false;
  }
  if (current.length >= pinnedPlaylistsLimit) {
    return false;
  }
  current.add(playlistId);
  pinnedPlaylistIds.value = current;
  unawaited(addOrUpdateData<List>('user', 'pinnedPlaylistIds', current));
  return true;
}

void _unpinPlaylist(String playlistId) {
  if (!pinnedPlaylistIds.value.contains(playlistId)) return;
  final updated = List<String>.from(pinnedPlaylistIds.value)
    ..remove(playlistId);
  pinnedPlaylistIds.value = updated;
  unawaited(addOrUpdateData<List>('user', 'pinnedPlaylistIds', updated));
}

/// Updates the offline playlist metadata (title, image, source) when a custom
/// playlist is renamed or modified. This ensures the offline playlist section
/// in the library displays the updated information.
Future<void> syncOfflinePlaylistMetadata(Map updatedPlaylist) async {
  final playlistId = updatedPlaylist['ytid']?.toString();
  if (playlistId == null ||
      !offlinePlaylistService.isPlaylistDownloaded(playlistId)) {
    return;
  }

  final offlinePlaylists = List<dynamic>.from(
    offlinePlaylistService.offlinePlaylists.value,
  );
  final offlineIndex = offlinePlaylists.indexWhere(
    (p) => p['ytid']?.toString() == playlistId,
  );

  if (offlineIndex == -1) return;

  // Update the offline playlist with the new metadata
  offlinePlaylists[offlineIndex] = {
    ...offlinePlaylists[offlineIndex],
    'title': updatedPlaylist['title'],
    'image': updatedPlaylist['image'],
    'source': updatedPlaylist['source'],
  };

  // Create a new list to trigger ValueNotifier listeners
  offlinePlaylistService.offlinePlaylists.value = List<dynamic>.from(
    offlinePlaylists,
  );
  unawaited(
    addOrUpdateData<List>('userNoBackup', 'offlinePlaylists', offlinePlaylists),
  );
}
