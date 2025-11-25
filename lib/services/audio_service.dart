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
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:rxdart/rxdart.dart';

class MusifyAudioHandler extends BaseAudioHandler {
  MusifyAudioHandler() {
    _setupEventSubscriptions();
    _updatePlaybackState();

    audioPlayer.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
    );

    _initialize();
  }

  final AudioPlayer audioPlayer = AudioPlayer(
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        maxBufferDuration: Duration(seconds: 60),
        bufferForPlaybackDuration: Duration(milliseconds: 500),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 3),
      ),
    ),
  );

  Timer? _sleepTimer;
  Timer? _debounceTimer;
  bool sleepTimerExpired = false;

  final List<Map> _queueList = [];
  final List<Map> _originalQueueList = [];
  final List<Map> _historyList = [];
  int _currentQueueIndex = 0;
  bool _isLoadingNextSong = false;
  bool _isUpdatingState = false;
  int _songTransitionCounter =
      0; // Track song transitions to prevent race conditions
  bool _completionEventPending = false;

  // Error handling
  String? _lastError;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;

  // Performance constants
  static const int _maxHistorySize = 50;
  static const int _queueLookahead = 3;
  static const int _maxConcurrentPreloads = 2;
  static const Duration _errorRetryDelay = Duration(seconds: 2);
  static const Duration _songTransitionTimeout = Duration(seconds: 30);
  static const Duration _debounceInterval = Duration(milliseconds: 150);

  // Preloading state management
  int _activePreloadCount = 0;
  final Set<String> _preloadingYtIds = <String>{};
  final Set<String> _preloadedYtIds = <String>{};

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        audioPlayer.positionStream,
        audioPlayer.bufferedPositionStream,
        audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      ).distinct((prev, curr) {
        const threshold = Duration(milliseconds: 500);
        return (prev.position - curr.position).abs() < threshold &&
            prev.duration == curr.duration &&
            (prev.bufferedPosition - curr.bufferedPosition).abs() < threshold;
      });

  /// Optimized PlaybackState stream for UI consumption
  ///
  /// This stream provides efficient PlaybackState updates with filtering
  /// to prevent unnecessary rebuilds when only irrelevant properties change.
  Stream<PlaybackState> get playbackStateStream => playbackState.distinct(
    (prev, curr) =>
        prev.playing == curr.playing &&
        prev.processingState == curr.processingState &&
        prev.queueIndex == curr.queueIndex,
  );

  /// Optimized Queue stream for UI consumption
  ///
  /// This stream provides efficient queue updates with basic throttling
  /// to prevent excessive rebuilds during rapid queue modifications.
  Stream<List<MediaItem>> get queueStream =>
      queue.throttleTime(const Duration(milliseconds: 100));

  final processingStateMap = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  void _setupEventSubscriptions() {
    // Playback event stream - triggers state updates and handles song completion
    audioPlayer.playbackEventStream
        .throttleTime(const Duration(milliseconds: 100))
        .listen(
          (event) {
            _handlePlaybackEvent(event);
            // Playback events need immediate state updates (not debounced)
            _updatePlaybackState();
          },
          onError: (error, stackTrace) {
            logger.log('Playback event stream error', error, stackTrace);
          },
        );

    // Duration stream - updates media items with duration info
    audioPlayer.durationStream
        .distinct()
        .throttleTime(const Duration(milliseconds: 200))
        .listen(
          (duration) {
            if (_currentQueueIndex < _queueList.length && duration != null) {
              _updateCurrentMediaItemWithDuration(duration);
            }
            // Duration changes don't need immediate playback state updates
          },
          onError: (error, stackTrace) {
            logger.log('Duration stream error', error, stackTrace);
          },
        );

    // Player state stream - handles state changes and errors
    audioPlayer.playerStateStream
        .distinct()
        .throttleTime(const Duration(milliseconds: 100))
        .listen(
          (state) {
            if (state.processingState == ProcessingState.idle &&
                !state.playing &&
                _lastError != null) {
              // Handle errors in background to prevent blocking
              Future.microtask(_handlePlaybackError);
            }
            _debouncedStateUpdate();
          },
          onError: (error, stackTrace) {
            logger.log('Player state stream error', error, stackTrace);
          },
        );

    // Combine index and sequence streams as they both indicate structural changes
    Rx.combineLatest2(
          audioPlayer.currentIndexStream.distinct(),
          audioPlayer.sequenceStateStream.distinct(),
          (index, sequence) => {'index': index, 'sequence': sequence},
        )
        .throttleTime(const Duration(milliseconds: 100))
        .listen(
          (_) => _debouncedStateUpdate(),
          onError: (error, stackTrace) {
            logger.log('Index/sequence stream error', error, stackTrace);
          },
        );
  }

  void _debouncedStateUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceInterval, () {
      if (!_isUpdatingState) {
        _updatePlaybackState();
      }
    });
  }

  void _updateCurrentMediaItemWithDuration(Duration duration) {
    Future.microtask(() async {
      try {
        if (_currentQueueIndex >= _queueList.length) return;

        // Capture current state to avoid race conditions
        final capturedQueueIndex = _currentQueueIndex;
        final capturedTransitionCounter = _songTransitionCounter;
        final currentSong = _queueList[capturedQueueIndex];
        final currentMediaItem = mapToMediaItem(currentSong);

        // Only update if we're still on the same song and haven't had new transitions
        final currentItem = mediaItem.valueOrNull;
        if (currentItem != null &&
            currentItem.id == currentMediaItem.id &&
            capturedQueueIndex == _currentQueueIndex &&
            capturedTransitionCounter == _songTransitionCounter &&
            (currentItem.duration == null ||
                !durationEquals(currentItem.duration, duration))) {
          mediaItem.add(currentMediaItem.copyWith(duration: duration));
        }

        // Update queue with duration info only if we're still on the same song
        if (capturedQueueIndex == _currentQueueIndex &&
            capturedTransitionCounter == _songTransitionCounter) {
          final mediaItems = _queueList.asMap().entries.map((entry) {
            final song = entry.value;
            final mediaItem = mapToMediaItem(song);
            return entry.key == capturedQueueIndex
                ? mediaItem.copyWith(duration: duration)
                : mediaItem;
          }).toList();

          queue.add(mediaItems);
        }
      } catch (e, stackTrace) {
        logger.log('Error updating media item with duration', e, stackTrace);
      }
    });
  }

  Future<void> _initialize() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e, stackTrace) {
      logger.log('Error initializing audio session', e, stackTrace);
    }
  }

  void _updatePlaybackState() {
    if (_isUpdatingState) return;

    _isUpdatingState = true;

    Future.microtask(() {
      try {
        final currentState = playbackState.valueOrNull;
        final newProcessingState =
            processingStateMap[audioPlayer.processingState] ??
            AudioProcessingState.idle;

        if (currentState == null ||
            currentState.playing != audioPlayer.playing ||
            currentState.processingState != newProcessingState ||
            currentState.queueIndex != _currentQueueIndex) {
          playbackState.add(
            PlaybackState(
              controls: [
                MediaControl.skipToPrevious,
                if (audioPlayer.playing)
                  MediaControl.pause
                else
                  MediaControl.play,
                MediaControl.stop,
                MediaControl.skipToNext,
              ],
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              androidCompactActionIndices: const [0, 1, 3],
              processingState: newProcessingState,
              playing: audioPlayer.playing,
              updatePosition: audioPlayer.position,
              bufferedPosition: audioPlayer.bufferedPosition,
              speed: audioPlayer.speed,
              queueIndex: _currentQueueIndex < _queueList.length
                  ? _currentQueueIndex
                  : null,
              updateTime: DateTime.now(),
            ),
          );
        }
      } catch (e, stackTrace) {
        logger.log('Error updating playback state', e, stackTrace);
      } finally {
        _isUpdatingState = false;
      }
    });
  }

  void _handlePlaybackEvent(PlaybackEvent event) {
    try {
      if (event.processingState == ProcessingState.completed) {
        if (!sleepTimerExpired && !_completionEventPending) {
          _completionEventPending = true;

          // Schedule the completion handler with slight delay
          Future.delayed(const Duration(milliseconds: 100), () async {
            try {
              // Double-check conditions before handling completion
              if (!sleepTimerExpired && _completionEventPending) {
                await _handleSongCompletion();
              }
            } finally {
              _completionEventPending = false;
            }
          });
        }
      } else {
        _completionEventPending = false;
      }
    } catch (e, stackTrace) {
      logger.log('Error handling playback event', e, stackTrace);
    }
  }

  void _handlePlaybackError() {
    _consecutiveErrors++;
    logger.log(
      'Playback error occurred. Consecutive errors: $_consecutiveErrors',
      _lastError,
      null,
    );

    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      logger.log(
        'Max consecutive errors reached. Stopping playback.',
        null,
        null,
      );
      stop();
      return;
    }

    // Try to skip to next song if available
    if (hasNext) {
      Future.delayed(_errorRetryDelay, skipToNext);
    }
  }

  Future<void> _handleSongCompletion() async {
    try {
      if (_currentQueueIndex < _queueList.length) {
        _addToHistory(_queueList[_currentQueueIndex]);
      }

      // Check if there's a next song in the queue (not considering auto-play here)
      if (_currentQueueIndex < _queueList.length - 1) {
        await skipToNext();
      } else if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        // Loop back to start
        await _playFromQueue(0);
      } else if (playNextSongAutomatically.value) {
        // Try to play auto-recommended song
        await _playNextRecommendedSong();
      }
      // Otherwise, playback ends naturally
    } catch (e, stackTrace) {
      logger.log('Error handling song completion', e, stackTrace);
    }
  }

  Future<void> _playNextRecommendedSong() async {
    if (_isLoadingNextSong) {
      logger.log('Already loading next song, skipping', null, null);
      return;
    }

    try {
      final baseSong = _getCurrentSongForRecommendations();
      if (baseSong == null) {
        logger.log('No valid song for recommendations', null, null);
        return;
      }

      if (nextRecommendedSong == null) {
        await _fetchRecommendedSong(baseSong);
      }

      if (nextRecommendedSong != null) {
        await _playRecommendation();
      } else {
        logger.log(
          'No recommendations available for "${baseSong['title']}"',
          null,
          null,
        );
      }
    } catch (e, stackTrace) {
      logger.log('Error playing recommended song', e, stackTrace);
    }
  }

  Map? _getCurrentSongForRecommendations() {
    if (_currentQueueIndex >= _queueList.length) {
      logger.log(
        'Invalid queue index: $_currentQueueIndex >= ${_queueList.length}',
        null,
        null,
      );
      return null;
    }

    final song = _queueList[_currentQueueIndex];

    if (song['ytid'] == null) {
      logger.log('Song has no ytid: ${song['title']}', null, null);
      return null;
    }

    return song;
  }

  Future<void> _fetchRecommendedSong(Map baseSong) async {
    logger.log(
      'Fetching recommendation for "${baseSong['title']}" (${baseSong['ytid']})',
      null,
      null,
    );

    try {
      await getSimilarSong(baseSong['ytid']).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          logger.log('Recommendation fetch timed out', null, null);
        },
      );
    } catch (e, stackTrace) {
      logger.log('Error fetching recommendation', e, stackTrace);
    }
  }

  Future<void> _playRecommendation() async {
    if (nextRecommendedSong == null) return;

    final recommendedSong = nextRecommendedSong;
    nextRecommendedSong = null;

    logger.log(
      'Playing recommendation: "${recommendedSong['title']}"',
      null,
      null,
    );

    await addToQueue(recommendedSong);
    await _playFromQueue(_queueList.length - 1);
  }

  void _prefetchNextRecommendation(String currentSongYtid) {
    if (nextRecommendedSong != null) {
      return;
    }

    Future.microtask(() async {
      try {
        await getSimilarSong(currentSongYtid).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            logger.log('Prefetch recommendation timed out', null, null);
          },
        );
      } catch (e, stackTrace) {
        logger.log('Error prefetching recommendation', e, stackTrace);
      }
    });
  }

  void _addToHistory(Map song) {
    try {
      _historyList
        ..removeWhere((s) => s['ytid'] == song['ytid'])
        ..insert(0, song);

      if (_historyList.length > _maxHistorySize) {
        _historyList.removeRange(_maxHistorySize, _historyList.length);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding to history', e, stackTrace);
    }
  }

  bool _removeSongInstances(String ytid) {
    var removedCurrentSong = false;

    for (var i = _queueList.length - 1; i >= 0; i--) {
      final existingYtId = _queueList[i]['ytid']?.toString();
      if (existingYtId == ytid) {
        if (i == _currentQueueIndex) {
          removedCurrentSong = true;
        }

        _queueList.removeAt(i);

        if (i < _currentQueueIndex) {
          _currentQueueIndex--;
        }
      }
    }

    if (_queueList.isEmpty) {
      _currentQueueIndex = 0;
    } else if (_currentQueueIndex >= _queueList.length) {
      _currentQueueIndex = _queueList.length - 1;
    } else if (_currentQueueIndex < 0) {
      _currentQueueIndex = 0;
    }

    return removedCurrentSong;
  }

  Future<void> addToQueue(Map song, {bool playNext = false}) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data for queue', null, null);
        return;
      }

      final ytid = song['ytid'].toString();
      final removedCurrentSong = _removeSongInstances(ytid);

      int insertIndex;

      if (playNext) {
        var desiredIndex = _currentQueueIndex + (removedCurrentSong ? 0 : 1);
        if (desiredIndex < 0) desiredIndex = 0;
        if (desiredIndex > _queueList.length) {
          desiredIndex = _queueList.length;
        }
        insertIndex = desiredIndex;
      } else {
        insertIndex = _queueList.length;
      }

      if (insertIndex >= 0 && insertIndex <= _queueList.length) {
        _queueList.insert(insertIndex, song);
      } else {
        _queueList.add(song);
        insertIndex = _queueList.length - 1;
      }

      if (removedCurrentSong) {
        _currentQueueIndex = insertIndex;
      } else if (_currentQueueIndex < 0) {
        _currentQueueIndex = 0;
      }

      _updateQueueMediaItems();
      _cleanupOldPreloadedSongs();

      if (!audioPlayer.playing && _queueList.length == 1) {
        await _playFromQueue(0);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding to queue', e, stackTrace);
    }
  }

  void _cleanupOldPreloadedSongs() {
    Future.microtask(() async {
      try {
        final queueYtIds = _queueList
            .map((song) => song['ytid']?.toString())
            .where((ytid) => ytid != null)
            .toSet();

        final oldPreloadedSongs = _preloadedYtIds
            .where((ytid) => !queueYtIds.contains(ytid))
            .toList();

        // Clean up old preloaded songs (keep cache but remove from tracking)
        for (final ytid in oldPreloadedSongs) {
          _preloadedYtIds.remove(ytid);
        }

        // Also clean up any stale preloading entries
        final stalePrelodingEntries = _preloadingYtIds
            .where((ytid) => !queueYtIds.contains(ytid))
            .toList();

        for (final ytid in stalePrelodingEntries) {
          _preloadingYtIds.remove(ytid);
          _activePreloadCount = (_activePreloadCount - 1).clamp(
            0,
            _maxConcurrentPreloads,
          );
        }

        if (oldPreloadedSongs.isNotEmpty || stalePrelodingEntries.isNotEmpty) {
          logger.log(
            'Cleaned up ${oldPreloadedSongs.length + stalePrelodingEntries.length} old preload entries',
            null,
            null,
          );
        }
      } catch (e, stackTrace) {
        logger.log('Error cleaning up preloaded songs', e, stackTrace);
      }
    });
  }

  Future<void> addPlaylistToQueue(
    List<Map> songs, {
    bool replace = false,
    int? startIndex,
  }) async {
    try {
      if (replace) {
        _queueList.clear();
        _originalQueueList.clear();
        _currentQueueIndex = 0;
        _resetPreloadingState();
        shuffleNotifier.value = false;
        await audioPlayer.setShuffleModeEnabled(false);
      }

      for (final song in songs) {
        if (song['ytid'] != null && song['ytid'].toString().isNotEmpty) {
          final ytid = song['ytid'].toString();
          final removedCurrentSong = _removeSongInstances(ytid);
          _queueList.add(song);

          if (removedCurrentSong) {
            _currentQueueIndex = _queueList.length - 1;
          }
        }
      }

      _updateQueueMediaItems();

      if (startIndex != null && startIndex < _queueList.length) {
        await _playFromQueue(startIndex);
      } else if (replace && _queueList.isNotEmpty) {
        await _playFromQueue(0);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding playlist to queue', e, stackTrace);
    }
  }

  Future<void> removeFromQueue(int index) async {
    try {
      if (index < 0 || index >= _queueList.length) return;

      _queueList.removeAt(index);

      if (index < _currentQueueIndex) {
        _currentQueueIndex--;
      } else if (index == _currentQueueIndex && _queueList.isNotEmpty) {
        if (_currentQueueIndex >= _queueList.length) {
          _currentQueueIndex = _queueList.length - 1;
        }
        await _playFromQueue(_currentQueueIndex);
      }

      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      logger.log('Error removing from queue', e, stackTrace);
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < 0 ||
          oldIndex >= _queueList.length ||
          newIndex < 0 ||
          newIndex >= _queueList.length)
        return;

      final song = _queueList.removeAt(oldIndex);
      _queueList.insert(newIndex, song);

      if (oldIndex == _currentQueueIndex) {
        _currentQueueIndex = newIndex;
      } else if (oldIndex < _currentQueueIndex &&
          newIndex >= _currentQueueIndex) {
        _currentQueueIndex--;
      } else if (oldIndex > _currentQueueIndex &&
          newIndex <= _currentQueueIndex) {
        _currentQueueIndex++;
      }

      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      logger.log('Error reordering queue', e, stackTrace);
    }
  }

  void clearQueue() {
    try {
      _queueList.clear();
      _originalQueueList.clear();
      _currentQueueIndex = 0;
      _resetPreloadingState();
      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      logger.log('Error clearing queue', e, stackTrace);
    }
  }

  void _updateQueueMediaItems() {
    try {
      final mediaItems = _queueList.map(mapToMediaItem).toList();
      queue.add(mediaItems);

      if (_currentQueueIndex < mediaItems.length) {
        final currentMediaItem = mediaItems[_currentQueueIndex];
        mediaItem.add(currentMediaItem);
      }
    } catch (e, stackTrace) {
      logger.log('Error updating queue media items', e, stackTrace);
    }
  }

  void _updateQueueOnly() {
    try {
      final mediaItems = _queueList.map(mapToMediaItem).toList();
      queue.add(mediaItems);
    } catch (e, stackTrace) {
      logger.log('Error updating queue', e, stackTrace);
    }
  }

  void _emitOptimisticLoadingState({
    Map? song,
    int? queueIndex,
    bool includeMediaItem = false,
  }) {
    try {
      if (includeMediaItem && song != null) {
        final immediateMediaItem = mapToMediaItem(song);
        scheduleMicrotask(() {
          mediaItem.add(immediateMediaItem);
        });
      }

      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: AudioProcessingState.loading,
          queueIndex:
              queueIndex ??
              (_currentQueueIndex < _queueList.length
                  ? _currentQueueIndex
                  : null),
          updateTime: DateTime.now(),
        ),
      );
    } catch (_) {
      // Non-fatal: if optimistic state cannot be added, continue normally.
    }
  }

  Future<void> _playFromQueue(int index) async {
    try {
      if (index < 0 || index >= _queueList.length) {
        logger.log('Invalid queue index: $index', null, null);
        return;
      }

      // If a song is already loading and it's the same index, skip
      if (_isLoadingNextSong && _currentQueueIndex == index) {
        logger.log(
          'Song already loading, skipping request for index: $index',
          null,
          null,
        );
        return;
      }

      _isLoadingNextSong = true;

      // Save old index for recovery in case of failure
      final previousQueueIndex = _currentQueueIndex;
      _currentQueueIndex = index;
      _songTransitionCounter++;

      final currentSong = _queueList[_currentQueueIndex];
      final currentMediaItem = mapToMediaItem(currentSong);

      scheduleMicrotask(() {
        mediaItem.add(currentMediaItem);
      });

      // Update queue
      _updateQueueOnly();

      _emitOptimisticLoadingState(queueIndex: _currentQueueIndex);

      final success = await playSong(_queueList[index]);

      if (success) {
        _consecutiveErrors = 0;
        _preloadUpcomingSongs();
      } else {
        // Restore previous index on failure
        _currentQueueIndex = previousQueueIndex;
        _handlePlaybackError();
      }
    } catch (e, stackTrace) {
      logger.log('Error playing from queue', e, stackTrace);
      _handlePlaybackError();
    } finally {
      _isLoadingNextSong = false;
    }
  }

  void _preloadUpcomingSongs() {
    Future.microtask(() async {
      try {
        // Get songs to preload (next 2-3 in queue)
        final songsToPreload = <Map>[];

        for (var i = 1; i <= _queueLookahead; i++) {
          final nextIndex = _currentQueueIndex + i;
          if (nextIndex < _queueList.length) {
            final nextSong = _queueList[nextIndex];
            final ytid = nextSong['ytid'];

            // Only preload if:
            // 1. Song has valid ytid
            // 2. Not an offline song
            // 3. Not already preloaded or preloading
            if (ytid != null &&
                !(nextSong['isOffline'] ?? false) &&
                !_preloadedYtIds.contains(ytid) &&
                !_preloadingYtIds.contains(ytid)) {
              songsToPreload.add(nextSong);
            }
          }
        }

        // Preload songs sequentially with concurrency control
        await _preloadSongsSequentially(songsToPreload);
      } catch (e, stackTrace) {
        logger.log('Error in _preloadUpcomingSongs', e, stackTrace);
      }
    });
  }

  Future<void> _preloadSongsSequentially(List<Map> songsToPreload) async {
    for (final song in songsToPreload) {
      // Wait for available slot if at capacity
      while (_activePreloadCount >= _maxConcurrentPreloads) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final ytid = song['ytid'];
      if (ytid == null || _preloadingYtIds.contains(ytid)) {
        continue;
      }

      // Start preloading this song (don't await - let it run in background)
      _preloadSingleSongControlled(song);
    }
  }

  void _preloadSingleSongControlled(Map nextSong) {
    final ytid = nextSong['ytid'];
    if (ytid == null) return;

    // Mark as preloading synchronously
    _preloadingYtIds.add(ytid);

    Future.microtask(() async {
      _activePreloadCount++;
      try {
        await _preloadSingleSong(nextSong).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            logger.log('Preload timeout for song $ytid', null, null);
          },
        );
      } catch (e) {
        logger.log('Error preloading song $ytid', e, null);
      } finally {
        // Clean up state
        _preloadingYtIds.remove(ytid);
        _activePreloadCount--;
        _preloadedYtIds.add(ytid); // Mark as attempted (success or failure)
      }
    });
  }

  Future<void> _preloadSingleSong(Map nextSong) async {
    final ytid = nextSong['ytid'];
    if (ytid == null) return;

    final cacheKey = 'song_${ytid}_${audioQualitySetting.value}_url';

    // Check if already cached
    final cachedUrl = await getData('cache', cacheKey);
    if (cachedUrl != null && cachedUrl.toString().isNotEmpty) return;

    // Fetch and cache the song URL
    final url = await getSong(ytid, nextSong['isLive'] ?? false);
    if (url != null && url.isNotEmpty) {
      await addOrUpdateData('cache', cacheKey, url);
    } else {
      logger.log('Preload: Failed to get URL for song $ytid', null, null);
    }
  }

  // Getters
  List<Map> get currentQueue => List.unmodifiable(_queueList);
  List<Map> get playHistory => List.unmodifiable(_historyList);
  int get currentQueueIndex => _currentQueueIndex;
  Map? get currentSong => _currentQueueIndex < _queueList.length
      ? _queueList[_currentQueueIndex]
      : null;

  bool get hasNext => _currentQueueIndex < _queueList.length - 1;

  bool get hasPrevious => _currentQueueIndex > 0 || _historyList.isNotEmpty;

  @override
  Future<void> onTaskRemoved() async {
    try {
      await stop();
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e, stackTrace) {
      logger.log('Error in onTaskRemoved', e, stackTrace);
    }
    await super.onTaskRemoved();
  }

  @override
  Future<void> play() async {
    try {
      await audioPlayer.play();
    } catch (e, stackTrace) {
      logger.log('Error in play()', e, stackTrace);
      _lastError = e.toString();
    }
  }

  @override
  Future<void> pause() async {
    try {
      await audioPlayer.pause();
    } catch (e, stackTrace) {
      logger.log('Error in pause()', e, stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    _debounceTimer?.cancel();
    _completionEventPending = false;
    try {
      await audioPlayer.stop();
      _lastError = null;
      _consecutiveErrors = 0;
      _resetPreloadingState();
    } catch (e, stackTrace) {
      logger.log('Error in stop()', e, stackTrace);
    }
    await super.stop();
  }

  void _resetPreloadingState() {
    _activePreloadCount = 0;
    _preloadingYtIds.clear();
    _preloadedYtIds.clear();
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await audioPlayer.seek(position);
    } catch (e, stackTrace) {
      logger.log('Error in seek()', e, stackTrace);
    }
  }

  @override
  Future<void> fastForward() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds + 15));

  @override
  Future<void> rewind() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds - 15));

  Future<bool> playSong(Map song) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data: missing ytid', null, null);
        return false;
      }

      _lastError = null;
      final isOffline = song['isOffline'] ?? false;

      if (audioPlayer.playing) await audioPlayer.pause();

      _emitOptimisticLoadingState(song: song, includeMediaItem: true);

      final songUrl = await _getSongUrl(song, isOffline);

      if (songUrl == null || songUrl.isEmpty) {
        logger.log('Failed to get song URL for ${song['ytid']}', null, null);
        _lastError = 'Failed to get song URL';
        return false;
      }

      final audioSource = await buildAudioSource(song, songUrl, isOffline);
      if (audioSource == null) {
        logger.log(
          'Failed to build audio source for ${song['ytid']}',
          null,
          null,
        );
        _lastError = 'Failed to build audio source';
        return false;
      }

      return await _setAudioSourceAndPlay(
        song,
        audioSource,
        songUrl,
        isOffline,
      );
    } catch (e, stackTrace) {
      logger.log('Error playing song', e, stackTrace);
      _lastError = e.toString();
      return false;
    }
  }

  Future<String?> _getSongUrl(Map song, bool isOffline) async {
    if (isOffline) {
      return _getOfflineSongUrl(song);
    } else {
      return getSong(song['ytid'], song['isLive'] ?? false);
    }
  }

  Future<String?> _getOfflineSongUrl(Map song) async {
    final audioPath = song['audioPath'];
    if (audioPath == null || audioPath.isEmpty) {
      logger.log(
        'Missing audioPath for offline song: ${song['ytid']}',
        null,
        null,
      );
      return null;
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      logger.log('Offline audio file not found: $audioPath', null, null);

      // Try to find in userOfflineSongs
      final offlineSong = userOfflineSongs.firstWhere(
        (s) => s['ytid'] == song['ytid'],
        orElse: () => <String, dynamic>{},
      );

      if (offlineSong.isNotEmpty && offlineSong['audioPath'] != null) {
        final fallbackFile = File(offlineSong['audioPath']);
        if (await fallbackFile.exists()) {
          song['audioPath'] = offlineSong['audioPath'];
          return offlineSong['audioPath'];
        }
      }

      // Fallback to online
      return getSong(song['ytid'], song['isLive'] ?? false);
    }

    return audioPath;
  }

  Future<bool> _setAudioSourceAndPlay(
    Map song,
    AudioSource audioSource,
    String songUrl,
    bool isOffline,
  ) async {
    try {
      await audioPlayer
          .setAudioSource(audioSource)
          .timeout(_songTransitionTimeout);
      await Future.delayed(const Duration(milliseconds: 100));

      // Update media item only with duration if available (media item base was set in _playFromQueue)
      if (audioPlayer.duration != null) {
        final currentMediaItem = mapToMediaItem(song);
        mediaItem.add(
          currentMediaItem.copyWith(duration: audioPlayer.duration),
        );
      }

      await audioPlayer.play();

      if (!isOffline) {
        final cacheKey =
            'song_${song['ytid']}_${audioQualitySetting.value}_url';
        unawaited(addOrUpdateData('cache', cacheKey, songUrl));
      }

      _updatePlaybackState();

      if (playNextSongAutomatically.value) {
        _prefetchNextRecommendation(song['ytid']);
      }

      Future.delayed(const Duration(seconds: 2), _preloadUpcomingSongs);

      return true;
    } catch (e, stackTrace) {
      logger.log('Error setting audio source', e, stackTrace);

      // Try online fallback for offline songs
      if (isOffline) {
        logger.log('Attempting to play online version as fallback', null, null);
        final onlineUrl = await getSong(song['ytid'], song['isLive'] ?? false);
        if (onlineUrl != null && onlineUrl.isNotEmpty) {
          final onlineSource = await buildAudioSource(song, onlineUrl, false);
          if (onlineSource != null) {
            try {
              await audioPlayer
                  .setAudioSource(onlineSource)
                  .timeout(_songTransitionTimeout);
              await Future.delayed(const Duration(milliseconds: 100));

              if (audioPlayer.duration != null) {
                final currentMediaItem = mapToMediaItem(song);
                mediaItem.add(
                  currentMediaItem.copyWith(duration: audioPlayer.duration),
                );
              }

              await audioPlayer.play();
              _updatePlaybackState();

              // Start preloading after successful fallback
              Future.delayed(const Duration(seconds: 2), _preloadUpcomingSongs);

              return true;
            } catch (fallbackError, fallbackStackTrace) {
              logger.log(
                'Fallback also failed',
                fallbackError,
                fallbackStackTrace,
              );
            }
          }
        }
      }

      _lastError = e.toString();
      return false;
    }
  }

  Future<void> playNext(Map song) async {
    await addToQueue(song, playNext: true);
  }

  Future<void> playPlaylistSong({
    Map<dynamic, dynamic>? playlist,
    required int songIndex,
  }) async {
    try {
      if (playlist != null && playlist['list'] != null) {
        await addPlaylistToQueue(
          List<Map>.from(playlist['list']),
          replace: true,
          startIndex: songIndex,
        );
      }
    } catch (e, stackTrace) {
      logger.log('Error playing playlist', e, stackTrace);
    }
  }

  Future<AudioSource?> buildAudioSource(
    Map song,
    String songUrl,
    bool isOffline,
  ) async {
    try {
      final tag = mapToMediaItem(song);

      if (isOffline) {
        return AudioSource.file(songUrl, tag: tag);
      }

      final uri = Uri.parse(songUrl);
      final audioSource = AudioSource.uri(uri, tag: tag);

      if (!sponsorBlockSupport.value) {
        return audioSource;
      }

      final spbAudioSource = await checkIfSponsorBlockIsAvailable(
        audioSource,
        song['ytid'],
      );
      return spbAudioSource ?? audioSource;
    } catch (e, stackTrace) {
      logger.log('Error building audio source', e, stackTrace);
      return null;
    }
  }

  Future<ClippingAudioSource?> checkIfSponsorBlockIsAvailable(
    UriAudioSource audioSource,
    String songId,
  ) async {
    try {
      final segments = await getSkipSegments(songId);
      if (segments.isNotEmpty && segments[0]['end'] != null) {
        return ClippingAudioSource(
          child: audioSource,
          start: Duration.zero,
          end: Duration(seconds: segments[0]['end']!),
        );
      }
    } catch (e, stackTrace) {
      logger.log('Error checking sponsor block', e, stackTrace);
    }
    return null;
  }

  Future<void> skipToSong(int newIndex) async {
    try {
      if (newIndex < 0 || newIndex >= _queueList.length) {
        logger.log('Invalid song index: $newIndex', null, null);
        return;
      }
      await _playFromQueue(newIndex);
    } catch (e, stackTrace) {
      logger.log('Error skipping to song', e, stackTrace);
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      if (_currentQueueIndex < _queueList.length - 1) {
        // Next song exists in queue
        await _playFromQueue(_currentQueueIndex + 1);
      } else if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        // Loop back to start
        await _playFromQueue(0);
      } else if (playNextSongAutomatically.value && !_isLoadingNextSong) {
        // Try to play auto-recommended song
        await _playNextRecommendedSong();
      } else {
        logger.log('No next song available', null, null);
      }

      _cleanupOldPreloadedSongs();
    } catch (e, stackTrace) {
      logger.log('Error skipping to next song', e, stackTrace);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      if (_currentQueueIndex > 0) {
        await _playFromQueue(_currentQueueIndex - 1);
      } else if (_historyList.isNotEmpty) {
        final lastSong = _historyList.removeLast();
        _queueList.insert(0, lastSong);
        // Ensure index is valid
        _currentQueueIndex = 0;
        _updateQueueMediaItems();
        await _playFromQueue(0);
      }

      _cleanupOldPreloadedSongs();
    } catch (e, stackTrace) {
      logger.log('Error skipping to previous song', e, stackTrace);
    }
  }

  Future<void> playAgain() async {
    try {
      await audioPlayer.seek(Duration.zero);
    } catch (e, stackTrace) {
      logger.log('Error playing again', e, stackTrace);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    try {
      final shuffleEnabled = shuffleMode != AudioServiceShuffleMode.none;
      final wasShuffled = shuffleNotifier.value;

      shuffleNotifier.value = shuffleEnabled;
      await audioPlayer.setShuffleModeEnabled(shuffleEnabled);

      if (_queueList.isEmpty) return;

      if (shuffleEnabled && !wasShuffled) {
        _originalQueueList
          ..clear()
          ..addAll(_queueList);

        final currentSong = _queueList[_currentQueueIndex];
        final currentYtId = currentSong['ytid'];

        _queueList.shuffle();

        // Only reorder if current song has a valid ytid
        if (currentYtId != null) {
          final newCurrentIndex = _queueList.indexWhere(
            (song) => song['ytid'] == currentYtId,
          );

          if (newCurrentIndex != -1 && newCurrentIndex != 0) {
            _queueList
              ..removeAt(newCurrentIndex)
              ..insert(0, currentSong);
          }
        }

        _currentQueueIndex = 0;
        _updateQueueMediaItems();
      } else if (!shuffleEnabled && wasShuffled) {
        if (_originalQueueList.isNotEmpty) {
          final currentSong = _queueList[_currentQueueIndex];
          final currentYtId = currentSong['ytid'];

          _queueList
            ..clear()
            ..addAll(_originalQueueList);

          // Find current song in original queue, default to 0 if not found or ytid is null
          _currentQueueIndex = currentYtId != null
              ? _queueList.indexWhere((song) => song['ytid'] == currentYtId)
              : 0;

          if (_currentQueueIndex == -1) {
            _currentQueueIndex = 0;
          }

          _originalQueueList.clear();
          _updateQueueMediaItems();
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error setting shuffle mode', e, stackTrace);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    try {
      repeatNotifier.value = repeatMode;
      switch (repeatMode) {
        case AudioServiceRepeatMode.none:
          await audioPlayer.setLoopMode(LoopMode.off);
          break;
        case AudioServiceRepeatMode.one:
          await audioPlayer.setLoopMode(LoopMode.one);
          break;
        case AudioServiceRepeatMode.all:
        case AudioServiceRepeatMode.group:
          await audioPlayer.setLoopMode(LoopMode.all);
          break;
      }
    } catch (e, stackTrace) {
      logger.log('Error setting repeat mode', e, stackTrace);
    }
  }

  Future<void> setSleepTimer(Duration duration) async {
    try {
      _sleepTimer?.cancel();
      sleepTimerExpired = false;
      sleepTimerNotifier.value = duration;

      _sleepTimer = Timer(duration, () async {
        sleepTimerExpired = true;
        await pause();
        sleepTimerNotifier.value = Duration.zero;
      });
    } catch (e, stackTrace) {
      logger.log('Error setting sleep timer', e, stackTrace);
    }
  }

  void cancelSleepTimer() {
    try {
      _sleepTimer?.cancel();
      _sleepTimer = null;
      sleepTimerExpired = false;
      sleepTimerNotifier.value = Duration.zero;
    } catch (e, stackTrace) {
      logger.log('Error canceling sleep timer', e, stackTrace);
    }
  }

  void changeSponsorBlockStatus() {
    sponsorBlockSupport.value = !sponsorBlockSupport.value;
    addOrUpdateData(
      'settings',
      'sponsorBlockSupport',
      sponsorBlockSupport.value,
    );
  }

  void changeAutoPlayNextStatus() {
    playNextSongAutomatically.value = !playNextSongAutomatically.value;
    addOrUpdateData(
      'settings',
      'playNextSongAutomatically',
      playNextSongAutomatically.value,
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    try {
      switch (name) {
        case 'clearQueue':
          clearQueue();
          break;
        case 'addToQueue':
          if (extras?['song'] != null) {
            await addToQueue(
              extras!['song'] as Map,
              playNext: extras['playNext'] ?? false,
            );
          }
          break;
        case 'removeFromQueue':
          if (extras?['index'] != null) {
            await removeFromQueue(extras!['index'] as int);
          }
          break;
        case 'reorderQueue':
          if (extras?['oldIndex'] != null && extras?['newIndex'] != null) {
            await reorderQueue(
              extras!['oldIndex'] as int,
              extras['newIndex'] as int,
            );
          }
          break;
        default:
          await super.customAction(name, extras);
      }
    } catch (e, stackTrace) {
      logger.log('Error in customAction: $name', e, stackTrace);
    }
  }

  // ============================================================================
  // Android Auto Support
  // ============================================================================

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    try {
      // Root level - show main browsable categories
      if (parentMediaId == '__ROOT__') {
        return _buildRootMediaItems();
      }

      // Queue - show current queue
      if (parentMediaId == '__QUEUE__') {
        return queue.value;
      }

      // Liked Songs
      if (parentMediaId == '__LIKED_SONGS__') {
        return _buildLikedSongsMediaItems();
      }

      // User Playlists (from YouTube/external)
      if (parentMediaId == '__USER_PLAYLISTS__') {
        return _buildUserPlaylistsMediaItems();
      }

      // Custom Playlists (user created)
      if (parentMediaId == '__CUSTOM_PLAYLISTS__') {
        return _buildCustomPlaylistsMediaItems();
      }

      // Individual playlist - show songs in the playlist
      if (parentMediaId.startsWith('playlist:')) {
        final playlistId = parentMediaId.substring('playlist:'.length);
        return await _buildPlaylistSongsMediaItems(playlistId);
      }

      return [];
    } catch (e, stackTrace) {
      logger.log('Error in onLoadChildren', e, stackTrace);
      return [];
    }
  }

  /// Builds the root-level browsable categories
  List<MediaItem> _buildRootMediaItems() {
    final items = <MediaItem>[];

    // Current Queue
    if (queue.value.isNotEmpty) {
      items.add(
        const MediaItem(id: '__QUEUE__', title: 'Queue', playable: false),
      );
    }

    // Liked Songs
    if (userLikedSongsList.isNotEmpty) {
      items.add(
        const MediaItem(
          id: '__LIKED_SONGS__',
          title: 'Liked Songs',
          playable: false,
        ),
      );
    }

    // User Playlists
    if (userPlaylists.value.isNotEmpty) {
      items.add(
        const MediaItem(
          id: '__USER_PLAYLISTS__',
          title: 'Your Playlists',
          playable: false,
        ),
      );
    }

    // Custom Playlists
    if (userCustomPlaylists.value.isNotEmpty) {
      items.add(
        const MediaItem(
          id: '__CUSTOM_PLAYLISTS__',
          title: 'Custom Playlists',
          playable: false,
        ),
      );
    }

    return items;
  }

  /// Builds MediaItems for liked songs
  List<MediaItem> _buildLikedSongsMediaItems() {
    return userLikedSongsList
        .map((song) => mapToMediaItem(song as Map))
        .toList();
  }

  /// Builds browsable MediaItems for user playlists
  List<MediaItem> _buildUserPlaylistsMediaItems() {
    return userPlaylists.value.map<MediaItem>((playlist) {
      final playlistMap = playlist as Map;
      return MediaItem(
        id: 'playlist:${playlistMap['ytid']}',
        title: playlistMap['title']?.toString() ?? 'Unnamed Playlist',
        artUri: playlistMap['image'] != null
            ? Uri.parse(playlistMap['image'].toString())
            : null,
        playable: false,
      );
    }).toList();
  }

  /// Builds browsable MediaItems for custom playlists
  List<MediaItem> _buildCustomPlaylistsMediaItems() {
    return userCustomPlaylists.value.map<MediaItem>((playlist) {
      final playlistMap = playlist as Map;
      return MediaItem(
        id: 'playlist:custom:${playlistMap['title']}',
        title: playlistMap['title']?.toString() ?? 'Unnamed Playlist',
        artUri: playlistMap['image'] != null
            ? Uri.parse(playlistMap['image'].toString())
            : null,
        playable: false,
      );
    }).toList();
  }

  /// Builds MediaItems for songs in a specific playlist
  Future<List<MediaItem>> _buildPlaylistSongsMediaItems(
    String playlistId,
  ) async {
    try {
      // Handle custom playlists
      if (playlistId.startsWith('custom:')) {
        final playlistTitle = playlistId.substring('custom:'.length);
        final playlist = userCustomPlaylists.value.firstWhere(
          (p) => (p as Map)['title'] == playlistTitle,
          orElse: () => <String, dynamic>{},
        );

        if (playlist is Map && playlist.isNotEmpty) {
          final songs = playlist['list'] as List? ?? [];
          return songs.map((song) => mapToMediaItem(song as Map)).toList();
        }
      } else {
        // Handle regular playlists
        final playlist = userPlaylists.value.firstWhere(
          (p) => (p as Map)['ytid'] == playlistId,
          orElse: () => <String, dynamic>{},
        );

        if (playlist is Map && playlist.isNotEmpty) {
          final songs = playlist['list'] as List? ?? [];
          return songs.map((song) => mapToMediaItem(song as Map)).toList();
        }
      }

      return [];
    } catch (e, stackTrace) {
      logger.log('Error building playlist songs', e, stackTrace);
      return [];
    }
  }
}
