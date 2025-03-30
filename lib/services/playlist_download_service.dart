// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

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

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';

class OfflinePlaylistService {
  factory OfflinePlaylistService() => _instance;
  OfflinePlaylistService._internal();
  static final OfflinePlaylistService _instance =
      OfflinePlaylistService._internal();

  // Playlist download state notifiers
  final Map<String, ValueNotifier<DownloadProgress>> downloadProgressNotifiers =
      {};
  final List<String> activeDownloads = [];

  // List of playlists that are fully available offline
  final offlinePlaylists = ValueNotifier<List<dynamic>>(
    Hive.box('userNoBackup').get('offlinePlaylists', defaultValue: []),
  );

  ValueNotifier<DownloadProgress> getProgressNotifier(String playlistId) {
    if (!downloadProgressNotifiers.containsKey(playlistId)) {
      downloadProgressNotifiers[playlistId] = ValueNotifier<DownloadProgress>(
        DownloadProgress(total: 0),
      );
    }
    return downloadProgressNotifiers[playlistId]!;
  }

  bool isPlaylistDownloaded(String playlistId) {
    return offlinePlaylists.value.any(
      (playlist) => playlist['ytid'] == playlistId,
    );
  }

  bool isPlaylistDownloading(String playlistId) {
    return activeDownloads.contains(playlistId);
  }

  Future<void> downloadPlaylist(
    BuildContext context,
    Map<String, dynamic> playlist,
  ) async {
    final playlistId = playlist['ytid'] as String? ?? playlist['title'];

    // Check if already downloading
    if (isPlaylistDownloading(playlistId)) {
      showToast(context, context.l10n!.alreadyDownloading);
      return;
    }

    // Check if already downloaded
    if (isPlaylistDownloaded(playlistId)) {
      showToast(context, context.l10n!.playlistAlreadyDownloaded);
      return;
    }

    // Initialize download state
    final songsList = playlist['list'] as List<dynamic>;
    if (songsList.isEmpty) {
      showToast(context, context.l10n!.playlistEmpty);
      return;
    }

    // Set up progress tracking
    final progressNotifier = getProgressNotifier(playlistId)
      ..value = DownloadProgress(total: songsList.length);
    activeDownloads.add(playlistId);

    // Create a queue to limit parallel downloads
    final songQueue = Queue<dynamic>.from(songsList);
    const maxConcurrent = 3; // Limit parallel downloads
    var runningTasks = 0;
    final completer = Completer<void>();

    // Helper function to process the queue
    Future<void> processQueue() async {
      while (songQueue.isNotEmpty &&
          runningTasks < maxConcurrent &&
          !progressNotifier.value.isCancelled) {
        runningTasks++;
        final song = songQueue.removeFirst();

        try {
          // Skip if already offline
          if (isSongAlreadyOffline(song['ytid'])) {
            progressNotifier.value.completed++;
            progressNotifier.notifyListeners();
          } else {
            await makeSongOffline(song, fromPlaylist: true);
            progressNotifier.value.completed++;
            progressNotifier.notifyListeners();
          }
        } catch (e) {
          logger.log('Failed to download song: ${song['title']}', e, null);
          progressNotifier.value.failed++;
          progressNotifier.notifyListeners();
        } finally {
          runningTasks--;

          // Start next song if available
          if (songQueue.isNotEmpty && !progressNotifier.value.isCancelled) {
            unawaited(processQueue());
          }

          // Check if download is complete
          if (songQueue.isEmpty && runningTasks == 0 ||
              progressNotifier.value.isComplete) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      }
    }

    // Start initial downloads
    for (var i = 0; i < maxConcurrent && i < songsList.length; i++) {
      unawaited(processQueue());
    }

    // Wait for all downloads to complete
    await completer.future;

    // Handle completion
    activeDownloads.remove(playlistId);

    // Only add to offline playlists if not cancelled and most songs succeeded
    if (!progressNotifier.value.isCancelled &&
        progressNotifier.value.completed > progressNotifier.value.failed) {
      // Create an offline version of the playlist
      final offlinePlaylist = {
        'ytid': playlistId,
        'title': playlist['title'],
        'image': playlist['image'],
        'source': playlist['source'],
        'list': songsList,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Add to offline playlists
      final updatedPlaylists = List<dynamic>.from(offlinePlaylists.value)
        ..add(offlinePlaylist);
      offlinePlaylists.value = updatedPlaylists;
      await addOrUpdateData(
        'userNoBackup',
        'offlinePlaylists',
        offlinePlaylists.value,
      );

      showToast(
        context,
        '${context.l10n!.playlistDownloaded}: ${progressNotifier.value.completed}/${songsList.length}',
      );
    } else if (progressNotifier.value.isCancelled) {
      showToast(context, context.l10n!.downloadCancelled);
    } else {
      showToast(
        context,
        '${context.l10n!.downloadFailed}: ${progressNotifier.value.failed}/${songsList.length}',
      );
    }
  }

  Future<void> cancelDownload(BuildContext context, String playlistId) async {
    if (!isPlaylistDownloading(playlistId)) return;

    final progressNotifier = getProgressNotifier(playlistId);
    progressNotifier.value.isCancelled = true;
    progressNotifier.notifyListeners();

    // Wait for the ongoing tasks to complete
    while (activeDownloads.contains(playlistId)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    showToast(context, context.l10n!.downloadCancelled);
  }

  Future<void> removeOfflinePlaylist(String playlistId) async {
    // Find the playlist
    final playlist = offlinePlaylists.value.firstWhere(
      (playlist) => playlist['ytid'] == playlistId,
      orElse: () => null,
    );

    if (playlist == null) return;

    // Get songs that are only in this playlist
    final songsInPlaylist = playlist['list'] as List<dynamic>;
    for (final song in songsInPlaylist) {
      final songId = song['ytid'] as String;

      // Check if this song is used in other offline playlists
      final isUsedInOtherPlaylists = offlinePlaylists.value
          .where((p) => p['ytid'] != playlistId) // Exclude current playlist
          .any(
            (p) => (p['list'] as List<dynamic>).any((s) => s['ytid'] == songId),
          );

      // Only remove if not used elsewhere
      if (!isUsedInOtherPlaylists) {
        await removeSongFromOffline(songId, fromPlaylist: true);
      }
    }

    // Remove playlist from offline playlists
    final updatedPlaylists = List<dynamic>.from(offlinePlaylists.value)
      ..removeWhere((p) => p['ytid'] == playlistId);
    offlinePlaylists.value = updatedPlaylists;
    await addOrUpdateData(
      'userNoBackup',
      'offlinePlaylists',
      offlinePlaylists.value,
    );
  }
}

class DownloadProgress {
  DownloadProgress({
    required this.total,
    this.completed = 0,
    this.failed = 0,
    this.isCancelled = false,
  });
  final int total;
  int completed;
  int failed;
  bool isCancelled;

  double get progress => total > 0 ? (completed + failed) / total : 0.0;
  bool get isComplete => completed + failed >= total;

  @override
  String toString() =>
      '${((completed + failed) / total * 100).toStringAsFixed(1)}%';
}

// Global instance for easy access
final offlinePlaylistService = OfflinePlaylistService();
