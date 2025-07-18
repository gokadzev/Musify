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
  final List<Map> _historyList = [];
  int _currentQueueIndex = 0;
  bool _isLoadingNextSong = false;
  bool _isUpdatingState = false;
  int _songTransitionCounter =
      0; // Track song transitions to prevent race conditions

  // Error handling
  String? _lastError;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;

  // Performance constants
  static const int _maxHistorySize = 50;
  static const int _queueLookahead = 3;
  static const Duration _errorRetryDelay = Duration(seconds: 2);
  static const Duration _songTransitionTimeout = Duration(seconds: 30);
  static const Duration _debounceInterval = Duration(milliseconds: 150);

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
          final mediaItems =
              _queueList.asMap().entries.map((entry) {
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
              queueIndex:
                  _currentQueueIndex < _queueList.length
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
      if (event.processingState == ProcessingState.completed &&
          !sleepTimerExpired) {
        Future.delayed(
          const Duration(milliseconds: 100),
          _handleSongCompletion,
        );
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

      if (hasNext) {
        await skipToNext();
      } else if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        await _playFromQueue(0);
      } else if (playNextSongAutomatically.value) {
        await _playRecommendedSong();
      }
    } catch (e, stackTrace) {
      logger.log('Error handling song completion', e, stackTrace);
    }
  }

  Future<void> _playRecommendedSong() async {
    if (_isLoadingNextSong) return;

    _isLoadingNextSong = true;

    try {
      final currentSong =
          _currentQueueIndex < _queueList.length
              ? _queueList[_currentQueueIndex]
              : null;

      if (currentSong != null && currentSong['ytid'] != null) {
        getSimilarSong(currentSong['ytid']);

        // Wait for recommendation with timeout
        final completer = Completer<void>();
        Timer? timeoutTimer;

        void checkRecommendation() {
          if (nextRecommendedSong != null) {
            timeoutTimer?.cancel();
            if (!completer.isCompleted) completer.complete();
          }
        }

        // Check every 100ms for recommendation
        final checkTimer = Timer.periodic(const Duration(milliseconds: 100), (
          _,
        ) {
          checkRecommendation();
        });

        // Timeout after 3 seconds
        timeoutTimer = Timer(const Duration(seconds: 3), () {
          checkTimer.cancel();
          if (!completer.isCompleted) completer.complete();
        });

        await completer.future;
        checkTimer.cancel();

        if (nextRecommendedSong != null) {
          await addToQueue(nextRecommendedSong!);
          await _playFromQueue(_queueList.length - 1);
          nextRecommendedSong = null;
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error playing recommended song', e, stackTrace);
    } finally {
      _isLoadingNextSong = false;
    }
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

  Future<void> addToQueue(Map song, {bool playNext = false}) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data for queue', null, null);
        return;
      }

      _queueList.removeWhere((s) => s['ytid'] == song['ytid']);

      if (playNext) {
        final insertIndex = _currentQueueIndex + 1;
        if (insertIndex < _queueList.length) {
          _queueList.insert(insertIndex, song);
        } else {
          _queueList.add(song);
        }
      } else {
        _queueList.add(song);
      }

      _updateQueueMediaItems();

      if (!audioPlayer.playing && _queueList.length == 1) {
        await _playFromQueue(0);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding to queue', e, stackTrace);
    }
  }

  Future<void> addPlaylistToQueue(
    List<Map> songs, {
    bool replace = false,
    int? startIndex,
  }) async {
    try {
      if (replace) {
        _queueList.clear();
        _currentQueueIndex = 0;
      }

      for (final song in songs) {
        if (song['ytid'] != null && song['ytid'].toString().isNotEmpty) {
          _queueList
            ..removeWhere((s) => s['ytid'] == song['ytid'])
            ..add(song);
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
      _currentQueueIndex = 0;
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

  Future<void> _playFromQueue(int index) async {
    try {
      if (index < 0 || index >= _queueList.length) {
        logger.log('Invalid queue index: $index', null, null);
        return;
      }

      // Prevent overlapping song loads
      if (_isLoadingNextSong) {
        logger.log(
          'Song already loading, skipping request for index: $index',
          null,
          null,
        );
        return;
      }

      _isLoadingNextSong = true;
      _currentQueueIndex = index;
      _songTransitionCounter++;

      final currentSong = _queueList[_currentQueueIndex];
      final currentMediaItem = mapToMediaItem(currentSong);

      scheduleMicrotask(() {
        mediaItem.add(currentMediaItem);
      });

      // Update queue
      _updateQueueOnly();

      final success = await playSong(_queueList[index]);

      if (success) {
        _consecutiveErrors = 0;
        _preloadUpcomingSongs();
      } else {
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
        final preloadTasks = <Future<void>>[];

        for (var i = 1; i <= _queueLookahead; i++) {
          final nextIndex = _currentQueueIndex + i;
          if (nextIndex < _queueList.length) {
            final nextSong = _queueList[nextIndex];
            if (nextSong['ytid'] != null && !(nextSong['isOffline'] ?? false)) {
              final preloadTask = _preloadSingleSong(nextSong)
                  .timeout(
                    const Duration(seconds: 10),
                    onTimeout: () {
                      logger.log(
                        'Preload timeout for song ${nextSong['ytid']}',
                        null,
                        null,
                      );
                    },
                  )
                  .catchError((e) {
                    logger.log(
                      'Error preloading song ${nextSong['ytid']}',
                      e,
                      null,
                    );
                  });

              preloadTasks.add(preloadTask);
            }
          }
        }

        // Run all preload tasks concurrently with overall timeout
        if (preloadTasks.isNotEmpty) {
          await Future.wait(preloadTasks)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  logger.log('Preloading batch timeout', null, null);
                  return <void>[];
                },
              )
              .catchError((e) {
                logger.log('Error in preload batch', e, null);
                return <void>[];
              });
        }
      } catch (e, stackTrace) {
        logger.log('Error in _preloadUpcomingSongs', e, stackTrace);
      }
    });
  }

  Future<void> _preloadSingleSong(Map nextSong) async {
    try {
      final cacheKey =
          'song_${nextSong['ytid']}_${audioQualitySetting.value}_url';

      // Check if already cached
      final cachedUrl = getData('cache', cacheKey);
      if (cachedUrl.toString().isNotEmpty) {
        return; // Already cached, skip
      }

      final url = await getSong(nextSong['ytid'], nextSong['isLive'] ?? false);
      if (url != null && url.isNotEmpty) {
        await addOrUpdateData('cache', cacheKey, url);
        logger.log(
          'Successfully preloaded song ${nextSong['ytid']}',
          null,
          null,
        );
      }
    } catch (e) {
      // Don't rethrow - let parent handle
      logger.log('Failed to preload song ${nextSong['ytid']}: $e', null, null);
    }
  }

  // Getters
  List<Map> get currentQueue => List.unmodifiable(_queueList);
  List<Map> get playHistory => List.unmodifiable(_historyList);
  int get currentQueueIndex => _currentQueueIndex;
  Map? get currentSong =>
      _currentQueueIndex < _queueList.length
          ? _queueList[_currentQueueIndex]
          : null;
  bool get hasNext =>
      _currentQueueIndex < _queueList.length - 1 ||
      (playNextSongAutomatically.value && !_isLoadingNextSong);
  bool get hasPrevious => _currentQueueIndex > 0 || _historyList.isNotEmpty;

  @override
  Future<void> onTaskRemoved() async {
    try {
      if (!backgroundPlay.value) {
        await stop();
        final session = await AudioSession.instance;
        await session.setActive(false);
      }
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
    try {
      await audioPlayer.stop();
      _lastError = null;
      _consecutiveErrors = 0;
    } catch (e, stackTrace) {
      logger.log('Error in stop()', e, stackTrace);
    }
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

      if (audioPlayer.playing) await audioPlayer.stop();

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
        getSimilarSong(song['ytid']);
      }

      // Start preloading AFTER current song is playing to avoid blocking
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
        await _playFromQueue(_currentQueueIndex + 1);
      } else if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        await _playFromQueue(0);
      } else if (playNextSongAutomatically.value && !_isLoadingNextSong) {
        await _handleAutoPlayNext();
      }
    } catch (e, stackTrace) {
      logger.log('Error skipping to next song', e, stackTrace);
    }
  }

  Future<void> _handleAutoPlayNext() async {
    if (nextRecommendedSong == null && _queueList.isNotEmpty) {
      final currentSong = _queueList[_currentQueueIndex];
      if (currentSong['ytid'] != null) {
        getSimilarSong(currentSong['ytid']);

        // Wait for recommendation with timeout
        final maxWaitTime = DateTime.now().add(const Duration(seconds: 3));
        while (nextRecommendedSong == null &&
            DateTime.now().isBefore(maxWaitTime)) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    if (nextRecommendedSong != null) {
      await addToQueue(nextRecommendedSong!);
      await _playFromQueue(_queueList.length - 1);
      nextRecommendedSong = null;
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      // Get current playback position
      final currentPosition = audioPlayer.position;

      // If the song has been playing for more than 3 seconds, restart it
      if (currentPosition.inSeconds > 3) {
        await audioPlayer.seek(Duration.zero);
        return;
      }

      // Otherwise, go to previous song
      if (_currentQueueIndex > 0) {
        await _playFromQueue(_currentQueueIndex - 1);
      } else if (_historyList.isNotEmpty) {
        final previousSong = _historyList.removeAt(0);
        _queueList.insert(0, previousSong);
        await _playFromQueue(0);
      } else if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        await _playFromQueue(_queueList.length - 1);
      }
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
      shuffleNotifier.value = shuffleEnabled;
      await audioPlayer.setShuffleModeEnabled(shuffleEnabled);
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
}
