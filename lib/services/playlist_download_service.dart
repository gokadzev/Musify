// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

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

  Future<void> downloadPlaylist(BuildContext context, Map playlist) async {
    final playlistId = playlist['ytid'] as String? ?? playlist['title'];

    if (playlistId == null || playlistId.isEmpty) {
      showToast(context, context.l10n!.error);
      return;
    }

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
    final songsList = playlist['list'] as List<dynamic>? ?? [];
    if (songsList.isEmpty) {
      showToast(context, context.l10n!.playlistEmpty);
      return;
    }

    // Set up progress tracking
    final progressNotifier = getProgressNotifier(playlistId)
      ..value = DownloadProgress(total: songsList.length);
    activeDownloads.add(playlistId);

    try {
      // Create a queue to limit parallel downloads
      final songQueue = Queue<dynamic>.from(songsList);
      const maxConcurrent = 3; // Limit parallel downloads
      var runningTasks = 0;
      final completer = Completer<void>();
      var hasCompletedEarly = false;

      // Helper function to process the queue
      Future<void> processQueue() async {
        while (songQueue.isNotEmpty &&
            runningTasks < maxConcurrent &&
            !progressNotifier.value.isCancelled &&
            !hasCompletedEarly) {
          runningTasks++;
          final song = songQueue.removeFirst();

          try {
            if (song == null ||
                song['ytid'] == null ||
                song['ytid'].toString().isEmpty) {
              logger.log('Invalid song data in playlist download', null, null);
              progressNotifier.value.failed++;
              progressNotifier.notifyListeners();
              continue;
            }

            // Skip if already offline
            if (isSongAlreadyOffline(song['ytid'])) {
              // Find the existing offline song to get the correct audioPath
              final offlineSong = userOfflineSongs.firstWhere(
                (s) => s['ytid'] == song['ytid'],
                orElse: () => null,
              );

              if (offlineSong != null) {
                // Update the song in the playlist with the correct offline properties
                song['audioPath'] = offlineSong['audioPath'];
                song['artworkPath'] = offlineSong['artworkPath'];
                song['isOffline'] = true;
              }
              // Update progress
              progressNotifier.value.completed++;
              progressNotifier.notifyListeners();
            } else {
              final success = await makeSongOffline(song, fromPlaylist: true);
              if (success) {
                progressNotifier.value.completed++;
              } else {
                progressNotifier.value.failed++;
              }
              progressNotifier.notifyListeners();
            }
          } catch (e, stackTrace) {
            logger.log(
              'Failed to download song: ${song['title']}',
              e,
              stackTrace,
            );
            progressNotifier.value.failed++;
            progressNotifier.notifyListeners();
          } finally {
            runningTasks--;

            // Check if download is complete or cancelled
            if (progressNotifier.value.isComplete ||
                progressNotifier.value.isCancelled) {
              hasCompletedEarly = true;
              if (!completer.isCompleted) {
                completer.complete();
              }
            } else if (songQueue.isNotEmpty &&
                !progressNotifier.value.isCancelled) {
              // Start next song if available
              unawaited(processQueue());
            } else if (songQueue.isEmpty && runningTasks == 0) {
              // All tasks completed
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          }
        }
      }

      // Start initial downloads
      final initialTasks = songsList.length < maxConcurrent
          ? songsList.length
          : maxConcurrent;
      for (var i = 0; i < initialTasks; i++) {
        unawaited(processQueue());
      }

      // Wait for all downloads to complete with timeout
      await completer.future.timeout(
        Duration(minutes: songsList.length * 2), // 2 minutes per song
        onTimeout: () {
          logger.log('Download timeout for playlist $playlistId', null, null);
          progressNotifier.value.isCancelled = true;
          progressNotifier.notifyListeners();
        },
      );

      // Handle completion
      await _handleDownloadCompletion(
        context,
        playlistId,
        playlist,
        progressNotifier,
      );
    } catch (e, stackTrace) {
      logger.log('Error during playlist download', e, stackTrace);
      activeDownloads.remove(playlistId);
      showToast(context, '${context.l10n!.error}: $e');
    }
  }

  Future<void> _handleDownloadCompletion(
    BuildContext context,
    String playlistId,
    Map playlist,
    ValueNotifier<DownloadProgress> progressNotifier,
  ) async {
    try {
      // Remove from active downloads
      activeDownloads.remove(playlistId);

      final songsList = playlist['list'] as List<dynamic>;

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
        final updatedPlaylists = List<dynamic>.from(offlinePlaylists.value);

        final existingIndex = updatedPlaylists.indexWhere(
          (p) => p['ytid'] == playlistId,
        );

        if (existingIndex != -1) {
          updatedPlaylists[existingIndex] = offlinePlaylist;
        } else {
          updatedPlaylists.add(offlinePlaylist);
        }

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
    } catch (e, stackTrace) {
      logger.log('Error handling download completion', e, stackTrace);
    }
  }

  Future<void> cancelDownload(BuildContext context, String playlistId) async {
    if (!isPlaylistDownloading(playlistId)) return;

    try {
      final progressNotifier = getProgressNotifier(playlistId);
      progressNotifier.value.isCancelled = true;
      progressNotifier.notifyListeners();

      const maxWaitTime = Duration(seconds: 30);
      final startTime = DateTime.now();

      // Wait for the ongoing tasks to complete with timeout
      while (activeDownloads.contains(playlistId)) {
        await Future.delayed(const Duration(milliseconds: 100));

        if (DateTime.now().difference(startTime) > maxWaitTime) {
          logger.log('Timeout waiting for download cancellation', null, null);
          activeDownloads.remove(playlistId);
          break;
        }
      }

      showToast(context, context.l10n!.downloadCancelled);
    } catch (e, stackTrace) {
      logger.log('Error cancelling download', e, stackTrace);
      // Force remove from active downloads on error
      activeDownloads.remove(playlistId);
    }
  }

  Future<void> removeOfflinePlaylist(String playlistId) async {
    try {
      if (playlistId.isEmpty) {
        logger.log('Invalid playlistId for removal', null, null);
        return;
      }

      // Find the playlist
      final playlist = offlinePlaylists.value.firstWhere(
        (playlist) => playlist['ytid'] == playlistId,
        orElse: () => null,
      );

      if (playlist == null) {
        logger.log('Playlist not found for removal: $playlistId', null, null);
        return;
      }

      // Get songs that are only in this playlist
      final songsInPlaylist = playlist['list'] as List<dynamic>? ?? [];
      for (final song in songsInPlaylist) {
        try {
          final songId = song['ytid'] as String?;

          if (songId == null || songId.isEmpty) {
            continue;
          }

          // Check if this song is used in other offline playlists
          final isUsedInOtherPlaylists = offlinePlaylists.value
              .where((p) => p['ytid'] != playlistId) // Exclude current playlist
              .any((p) {
                final playlistSongs = p['list'] as List<dynamic>? ?? [];
                return playlistSongs.any((s) => s['ytid'] == songId);
              });

          // Also check if song is in user's liked songs or custom playlists
          final isInLikedSongs = userLikedSongsList.any(
            (s) => s['ytid'] == songId,
          );
          final isInCustomPlaylists = userCustomPlaylists.value.any((p) {
            final customPlaylistSongs = p['list'] as List<dynamic>? ?? [];
            return customPlaylistSongs.any((s) => s['ytid'] == songId);
          });

          // Only remove if not used elsewhere
          if (!isUsedInOtherPlaylists &&
              !isInLikedSongs &&
              !isInCustomPlaylists) {
            await removeSongFromOffline(songId, fromPlaylist: true);
          }
        } catch (e, stackTrace) {
          logger.log('Error removing song from offline', e, stackTrace);
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
    } catch (e, stackTrace) {
      logger.log('Error removing offline playlist', e, stackTrace);
    }
  }

  void cleanupProgressNotifier(String playlistId) {
    try {
      if (downloadProgressNotifiers.containsKey(playlistId)) {
        downloadProgressNotifiers[playlistId]?.dispose();
        downloadProgressNotifiers.remove(playlistId);
      }
    } catch (e, stackTrace) {
      logger.log('Error cleaning up progress notifier', e, stackTrace);
    }
  }

  Map<String, dynamic> getDownloadStatus(String playlistId) {
    final isDownloaded = isPlaylistDownloaded(playlistId);
    final isDownloading = isPlaylistDownloading(playlistId);
    final progress = downloadProgressNotifiers.containsKey(playlistId)
        ? downloadProgressNotifiers[playlistId]!.value
        : null;

    return {
      'isDownloaded': isDownloaded,
      'isDownloading': isDownloading,
      'progress': progress,
    };
  }

  void pauseAllDownloads() {
    for (final notifier in downloadProgressNotifiers.values) {
      notifier.value.isCancelled = true;
      notifier.notifyListeners();
    }
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

  double get progress {
    if (total <= 0) return 0;
    final totalProcessed = completed + failed;
    return totalProcessed > total ? 1.0 : totalProcessed / total;
  }

  bool get isComplete => completed + failed >= total;

  double get successRate {
    final totalProcessed = completed + failed;
    return totalProcessed > 0 ? completed / totalProcessed : 0.0;
  }

  @override
  String toString() {
    final percentage = (progress * 100).toStringAsFixed(1);
    return '$percentage% ($completed/$total)';
  }
}

// Global instance for easy access
final offlinePlaylistService = OfflinePlaylistService();
