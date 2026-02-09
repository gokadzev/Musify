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
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hive/hive.dart';
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
  int _currentLoadingIndex = -1;
  int _currentLoadingTransitionId = -1;
  bool _isUpdatingState = false;
  int _songTransitionCounter = 0;
  bool _completionEventPending = false;
  bool _completionHandlerLoadStarted = false;

  String? _lastError;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;

  static const int _maxHistorySize = 50;
  static const int _queueLookahead = 3;
  static const int _maxConcurrentPreloads = 2;
  static const Duration _errorRetryDelay = Duration(seconds: 2);
  static const Duration _songTransitionTimeout = Duration(seconds: 30);
  static const Duration _debounceInterval = Duration(milliseconds: 150);

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

  Stream<PlaybackState> get playbackStateStream => playbackState.distinct(
    (prev, curr) =>
        prev.playing == curr.playing &&
        prev.processingState == curr.processingState &&
        prev.queueIndex == curr.queueIndex,
  );

  static const _playingControls = [
    MediaControl.skipToPrevious,
    MediaControl.pause,
    MediaControl.stop,
    MediaControl.skipToNext,
  ];

  static const _pausedControls = [
    MediaControl.skipToPrevious,
    MediaControl.play,
    MediaControl.stop,
    MediaControl.skipToNext,
  ];

  final processingStateMap = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  void _setupEventSubscriptions() {
    audioPlayer.playbackEventStream
        .throttleTime(const Duration(milliseconds: 100))
        .listen(
          (event) {
            _updatePlaybackState();
          },
          onError: (error, stackTrace) {
            logger.log('Playback event stream error', error, stackTrace);
          },
        );

    audioPlayer.processingStateStream.distinct().listen(
      _handleProcessingStateChange,
      onError: (error, stackTrace) {
        logger.log('Processing state stream error', error, stackTrace);
      },
    );

    audioPlayer.durationStream
        .distinct()
        .throttleTime(const Duration(milliseconds: 200))
        .listen(
          (duration) {
            if (_currentQueueIndex < _queueList.length && duration != null) {
              _updateCurrentMediaItemWithDuration(duration);
            }
          },
          onError: (error, stackTrace) {
            logger.log('Duration stream error', error, stackTrace);
          },
        );

    audioPlayer.playerStateStream
        .distinct()
        .throttleTime(const Duration(milliseconds: 100))
        .listen(
          (state) {
            if (state.processingState == ProcessingState.idle &&
                !state.playing &&
                _lastError != null) {
              Future.microtask(_handlePlaybackError);
            }
            _debouncedStateUpdate();
          },
          onError: (error, stackTrace) {
            logger.log('Player state stream error', error, stackTrace);
          },
        );

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

  MediaItem _getMediaItemForQueue(Map song, int index) {
    return mapToMediaItem(song).copyWith(id: '${song['ytid']}_$index');
  }

  void _updateCurrentMediaItemWithDuration(Duration duration) {
    Future.microtask(() async {
      try {
        if (_currentQueueIndex >= _queueList.length) return;

        final capturedQueueIndex = _currentQueueIndex;
        final capturedTransitionCounter = _songTransitionCounter;

        // If state changed while waiting for microtask, abort
        if (capturedQueueIndex != _currentQueueIndex ||
            capturedTransitionCounter != _songTransitionCounter) {
          return;
        }

        final currentSong = _queueList[capturedQueueIndex];
        final currentMediaItem = _getMediaItemForQueue(
          currentSong,
          capturedQueueIndex,
        );
        final uniqueId = currentMediaItem.id;
        final currentItem = mediaItem.valueOrNull;

        if (currentItem != null &&
            currentItem.id == uniqueId &&
            (currentItem.duration == null ||
                !durationEquals(currentItem.duration, duration))) {
          mediaItem.add(currentMediaItem.copyWith(duration: duration));
        }

        List<MediaItem> newQueue;
        if (queue.hasValue && queue.value.length == _queueList.length) {
          newQueue = List<MediaItem>.from(queue.value);
        } else {
          newQueue = _queueList
              .asMap()
              .entries
              .map((entry) => _getMediaItemForQueue(entry.value, entry.key))
              .toList();
        }

        if (capturedQueueIndex < newQueue.length) {
          newQueue[capturedQueueIndex] = newQueue[capturedQueueIndex].copyWith(
            duration: duration,
          );
          queue.add(newQueue);
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

      // Always set loop mode to off - we handle all repeating through _handleSongCompletion
      // This ensures ProcessingState.completed is always fired for song transitions
      await audioPlayer.setLoopMode(LoopMode.off);

      // Apply stored shuffle mode to audio player
      await audioPlayer.setShuffleModeEnabled(shuffleNotifier.value);
    } catch (e, stackTrace) {
      logger.log('Error initializing audio session', e, stackTrace);
    }
  }

  void _updatePlaybackState() {
    if (_isUpdatingState) return;

    _isUpdatingState = true;

    Future.microtask(() {
      try {
        final now = DateTime.now();
        final currentPosition = audioPlayer.position;
        final isPlaying = audioPlayer.playing;
        final currentState = playbackState.valueOrNull;
        final newProcessingState =
            processingStateMap[audioPlayer.processingState] ??
            AudioProcessingState.idle;

        var shouldUpdate =
            currentState == null ||
            currentState.playing != isPlaying ||
            currentState.processingState != newProcessingState ||
            currentState.queueIndex != _currentQueueIndex;

        if (!shouldUpdate) {
          final lastUpdateTime = currentState.updateTime;
          final lastUpdatePosition = currentState.updatePosition;
          final speed = currentState.speed;

          final expectedPosition =
              lastUpdatePosition + (now.difference(lastUpdateTime)) * speed;

          if ((currentPosition - expectedPosition).abs() >
              const Duration(milliseconds: 500)) {
            shouldUpdate = true;
          }
        }

        if (shouldUpdate) {
          playbackState.add(
            PlaybackState(
              controls: isPlaying ? _playingControls : _pausedControls,
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              androidCompactActionIndices: const [0, 1, 3],
              processingState: newProcessingState,
              playing: isPlaying,
              updatePosition: currentPosition,
              bufferedPosition: audioPlayer.bufferedPosition,
              speed: audioPlayer.speed,
              queueIndex: _currentQueueIndex < _queueList.length
                  ? _currentQueueIndex
                  : null,
              updateTime: now,
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

  void _handleProcessingStateChange(ProcessingState state) {
    try {
      if (state == ProcessingState.completed) {
        if (!sleepTimerExpired && !_completionEventPending) {
          _completionEventPending = true;

          Future.microtask(() async {
            try {
              if (!sleepTimerExpired && _completionEventPending) {
                await _handleSongCompletion();
              }
            } finally {
              // Only reset if still marked as pending (another event didn't override)
              if (_completionEventPending) {
                _completionEventPending = false;
                _completionHandlerLoadStarted = false;
              }
              // else {
              //   logger.log(
              //     '[COMPLETION] Flag already false in finally block (was overridden)',
              //     null,
              //     null,
              //   );
              // }
            }
          });
        }
      } else if (state == ProcessingState.ready) {
        _completionEventPending = false;
      }
    } catch (e, stackTrace) {
      logger.log('Error handling processing state change', e, stackTrace);
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

    if (hasNext ||
        (repeatNotifier.value == AudioServiceRepeatMode.all &&
            _queueList.isNotEmpty) ||
        playNextSongAutomatically.value) {
      Future.delayed(_errorRetryDelay, skipToNext);
    }
  }

  Future<void> _handleSongCompletion() async {
    try {
      if (_currentQueueIndex >= 0 && _currentQueueIndex < _queueList.length) {
        _addToHistory(_queueList[_currentQueueIndex]);
      }

      // Determine what to play next based on queue position and repeat mode
      if (repeatNotifier.value == AudioServiceRepeatMode.one) {
        // Repeat single song - play current song again
        await _playFromQueue(_currentQueueIndex);
      } else {
        // For all other cases (next song, repeat all, auto-play), skipToNext handles it
        await skipToNext();
      }
    } catch (e, stackTrace) {
      logger.log('Error handling song completion', e, stackTrace);
    }
  }

  Future<void> _playNextRecommendedSong() async {
    if (_currentLoadingIndex >= 0) {
      logger.log(
        'Already loading next song (index: $_currentLoadingIndex), skipping',
        null,
        null,
      );
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
    final currentMediaItem = mediaItem.valueOrNull;

    if (currentMediaItem == null || currentMediaItem.id.isEmpty) {
      logger.log('No current media item available', null, null);
      return null;
    }

    return mediaItemToMap(currentMediaItem);
  }

  Future<void> _fetchRecommendedSong(Map baseSong) async {
    try {
      await getSimilarSong(baseSong['ytid']).timeout(
        const Duration(seconds: 7),
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

  Future<void> addToQueue(Map song, {bool playNext = false}) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data for queue', null, null);
        return;
      }

      int insertIndex;

      if (playNext) {
        insertIndex = _currentQueueIndex + 1;
        if (insertIndex < 0) insertIndex = 0;
        if (insertIndex > _queueList.length) {
          insertIndex = _queueList.length;
        }
      } else {
        insertIndex = _queueList.length;
      }

      _queueList.insert(insertIndex, song);

      if (_currentQueueIndex < 0) {
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

        for (final ytid in oldPreloadedSongs) {
          _preloadedYtIds.remove(ytid);
        }

        final stalePrelodingEntries = _preloadingYtIds
            .where((ytid) => !queueYtIds.contains(ytid))
            .toList();

        for (final ytid in stalePrelodingEntries) {
          _preloadingYtIds.remove(ytid);
          if (_activePreloadCount > 0) {
            _activePreloadCount--;
          }
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
        _currentLoadingIndex = -1;
        _currentLoadingTransitionId = -1;
        _resetPreloadingState();
        shuffleNotifier.value = false;
        unawaited(Hive.box('settings').put('shuffleEnabled', false));
        await audioPlayer.setShuffleModeEnabled(false);
      }

      int? targetQueueIndex;

      for (var i = 0; i < songs.length; i++) {
        final song = songs[i];
        if (song['ytid'] != null && song['ytid'].toString().isNotEmpty) {
          _queueList.add(song);

          if (replace && startIndex == i) {
            targetQueueIndex = _queueList.length - 1;
          }
        }
      }

      _updateQueueMediaItems();

      if (targetQueueIndex != null) {
        await _playFromQueue(targetQueueIndex);
      } else if (startIndex != null &&
          startIndex < _queueList.length &&
          !replace) {
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
        // If removing the currently-loading song, reset loading state
        if (_currentLoadingIndex == index) {
          _currentLoadingIndex = -1;
          _currentLoadingTransitionId = -1;
        }

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
          newIndex > _queueList.length - 1) {
        return;
      }

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
      _currentLoadingIndex = -1;
      _currentLoadingTransitionId = -1;
      _resetPreloadingState();
      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      logger.log('Error clearing queue', e, stackTrace);
    }
  }

  void _updateQueueMediaItems() {
    try {
      final mediaItems = _queueList
          .asMap()
          .entries
          .map((entry) => _getMediaItemForQueue(entry.value, entry.key))
          .toList();
      queue.add(mediaItems);

      if (_currentQueueIndex < mediaItems.length) {
        final currentMediaItem = mediaItems[_currentQueueIndex];
        mediaItem.add(currentMediaItem);
      }
    } catch (e, stackTrace) {
      logger.log('Error updating queue media items', e, stackTrace);
    }
  }

  void _emitOptimisticLoadingState({
    Map? song,
    int? queueIndex,
    bool includeMediaItem = false,
    String? mediaId,
  }) {
    try {
      if (includeMediaItem && song != null) {
        var immediateMediaItem = mapToMediaItem(song);
        if (mediaId != null) {
          immediateMediaItem = immediateMediaItem.copyWith(id: mediaId);
        }
        Future.microtask(() {
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
    } catch (_) {}
  }

  Future<void> _playFromQueue(int index) async {
    try {
      // logger.log(
      //   '[PLAY_FROM_QUEUE] Called with index=$index, _currentLoadingIndex=$_currentLoadingIndex',
      //   null,
      //   null,
      // );
      if (index < 0 || index >= _queueList.length) {
        logger.log('Invalid queue index: $index', null, null);
        return;
      }

      // If already loading any song, skip the request
      // UNLESS we're in the middle of handling a completion event (allow one load attempt)
      if (_currentLoadingIndex >= 0 && !_completionEventPending) {
        return;
      }

      if (_currentLoadingIndex >= 0 &&
          _completionEventPending &&
          !_completionHandlerLoadStarted) {
        _completionHandlerLoadStarted = true;
      } else if (_currentLoadingIndex >= 0 &&
          _completionEventPending &&
          _completionHandlerLoadStarted) {
        return;
      }

      // Start new transition
      _songTransitionCounter++;
      final currentTransitionId = _songTransitionCounter;
      _currentLoadingIndex = index;
      _currentLoadingTransitionId = currentTransitionId;

      final previousQueueIndex = _currentQueueIndex;
      _currentQueueIndex = index;

      final currentSong = _queueList[_currentQueueIndex];
      final currentMediaItem = _getMediaItemForQueue(
        currentSong,
        _currentQueueIndex,
      );
      final uniqueId = currentMediaItem.id;

      await Future.microtask(() {
        mediaItem.add(currentMediaItem);
      });

      _emitOptimisticLoadingState(
        queueIndex: _currentQueueIndex,
        mediaId: uniqueId,
      );

      final success = await playSong(_queueList[index], mediaId: uniqueId);

      // Only process result if this is still the current transition
      if (currentTransitionId == _currentLoadingTransitionId) {
        if (success) {
          _consecutiveErrors = 0;
          _preloadUpcomingSongs();
        } else {
          _currentQueueIndex = previousQueueIndex;
          _handlePlaybackError();
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error playing from queue', e, stackTrace);
      _handlePlaybackError();
    } finally {
      // Only reset if we haven't already cleared it in the success path
      if (_currentLoadingIndex >= 0) {
        _currentLoadingIndex = -1;
        _currentLoadingTransitionId = -1;
      }
    }
  }

  void _preloadUpcomingSongs() {
    Future.microtask(() async {
      try {
        final songsToPreload = <Map>[];

        for (var i = 1; i <= _queueLookahead; i++) {
          final nextIndex = _currentQueueIndex + i;
          if (nextIndex < _queueList.length) {
            final nextSong = _queueList[nextIndex];
            final ytid = nextSong['ytid'];

            if (ytid != null &&
                !(nextSong['isOffline'] ?? false) &&
                !_preloadedYtIds.contains(ytid) &&
                !_preloadingYtIds.contains(ytid)) {
              songsToPreload.add(nextSong);
            }
          }
        }

        await _preloadSongsSequentially(songsToPreload);
      } catch (e, stackTrace) {
        logger.log('Error in _preloadUpcomingSongs', e, stackTrace);
      }
    });
  }

  Future<void> _preloadSongsSequentially(List<Map> songsToPreload) async {
    for (final song in songsToPreload) {
      while (_activePreloadCount >= _maxConcurrentPreloads) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final ytid = song['ytid'];
      if (ytid == null || _preloadingYtIds.contains(ytid)) {
        continue;
      }

      _preloadSingleSongControlled(song);
    }
  }

  void _preloadSingleSongControlled(Map nextSong) {
    final ytid = nextSong['ytid'];
    if (ytid == null) return;

    _preloadingYtIds.add(ytid);

    Future.microtask(() async {
      _activePreloadCount++;
      try {
        // fetchSongStreamUrl handles caching, freshness checks, and validation
        await fetchSongStreamUrl(ytid, nextSong['isLive'] ?? false).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            logger.log('Preload timeout for song $ytid', null, null);
            return null;
          },
        );
      } catch (e) {
        logger.log('Error preloading song $ytid', e, null);
      } finally {
        _preloadingYtIds.remove(ytid);
        _activePreloadCount--;
        _preloadedYtIds.add(ytid);
      }
    });
  }

  List<Map> get currentQueue => List.unmodifiable(_queueList);
  List<Map> get playHistory => List.unmodifiable(_historyList);
  int get currentQueueIndex => _currentQueueIndex;
  Map? get currentSong =>
      _currentQueueIndex >= 0 && _currentQueueIndex < _queueList.length
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
    _currentLoadingIndex = -1;
    _currentLoadingTransitionId = -1;
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

  Future<bool> playSong(Map song, {String? mediaId}) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data: missing ytid', null, null);
        return false;
      }

      _lastError = null;
      var isOffline = song['isOffline'] ?? false;

      if (audioPlayer.playing) await audioPlayer.pause();

      _emitOptimisticLoadingState(
        song: song,
        includeMediaItem: true,
        mediaId: mediaId,
      );

      var songUrl = await _getSongUrl(song, isOffline);

      // If offline file is missing, try falling back to online
      if ((songUrl == null || songUrl.isEmpty) && isOffline) {
        logger.log(
          'Offline file missing for ${song['ytid']}, switching to online',
          null,
          null,
        );
        isOffline = false;
        songUrl = await _getSongUrl(song, isOffline);
      }

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
        mediaId: mediaId,
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
      return fetchSongStreamUrl(song['ytid'], song['isLive'] ?? false);
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
    if (await file.exists()) {
      return audioPath;
    }

    logger.log('Offline audio file not found: $audioPath', null, null);

    final offlineSong = userOfflineSongs.firstWhere(
      (s) => s['ytid'] == song['ytid'],
      orElse: () => <String, dynamic>{},
    );

    if (offlineSong.isNotEmpty && offlineSong['audioPath'] != null) {
      final fallbackPath = offlineSong['audioPath'];
      final fallbackFile = File(fallbackPath);
      if (await fallbackFile.exists()) {
        song['audioPath'] = fallbackPath;
        return fallbackPath;
      }
    }

    return null;
  }

  Future<bool> _setAudioSourceAndPlay(
    Map song,
    AudioSource audioSource,
    String songUrl,
    bool isOffline, {
    String? mediaId,
  }) async {
    try {
      await audioPlayer
          .setAudioSource(audioSource)
          .timeout(_songTransitionTimeout);
      await Future.delayed(const Duration(milliseconds: 100));

      if (audioPlayer.duration != null) {
        var currentMediaItem = mapToMediaItem(song);
        if (mediaId != null) {
          currentMediaItem = currentMediaItem.copyWith(id: mediaId);
        }
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

      if (isOffline) {
        return _attemptOfflineFallback(song, mediaId: mediaId);
      }

      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> _attemptOfflineFallback(Map song, {String? mediaId}) async {
    logger.log('Attempting to play online version as fallback', null, null);
    final onlineUrl = await fetchSongStreamUrl(
      song['ytid'],
      song['isLive'] ?? false,
    );
    if (onlineUrl != null && onlineUrl.isNotEmpty) {
      final onlineSource = await buildAudioSource(song, onlineUrl, false);
      if (onlineSource != null) {
        return _setAudioSourceAndPlay(
          song,
          onlineSource,
          onlineUrl,
          false,
          mediaId: mediaId,
        );
      }
    }
    return false;
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

  Future<AudioSource?> checkIfSponsorBlockIsAvailable(
    UriAudioSource audioSource,
    String songId,
  ) async {
    try {
      final segments = await getSkipSegments(songId);
      if (segments.isEmpty) return null;

      // Sort segments by start time
      segments.sort((a, b) => (a['start'] ?? 0).compareTo(b['start'] ?? 0));

      final children = <AudioSource>[];
      var lastEnd = 0;

      for (final segment in segments) {
        final start = segment['start'] ?? 0;
        final end = segment['end'] ?? 0;

        // Add the "good" part before this sponsor segment
        if (start > lastEnd) {
          children.add(
            ClippingAudioSource(
              child: audioSource,
              start: Duration(seconds: lastEnd),
              end: Duration(seconds: start),
            ),
          );
        }

        // Advance lastEnd, handling overlapping segments
        if (end > lastEnd) {
          lastEnd = end;
        }
      }

      // Add the final part from the last sponsor segment to the end of the song
      children.add(
        ClippingAudioSource(
          child: audioSource,
          start: Duration(seconds: lastEnd),
          // end: null means play until the end of the file
        ),
      );

      if (children.length == 1) {
        return children.first;
      }

      // ignore: deprecated_member_use
      return ConcatenatingAudioSource(children: children);
    } catch (e, stackTrace) {
      logger.log('Error checking sponsor block', e, stackTrace);
      return null;
    }
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
      } else if (playNextSongAutomatically.value &&
          _currentLoadingIndex == -1) {
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
      unawaited(Hive.box('settings').put('shuffleEnabled', shuffleEnabled));
      await audioPlayer.setShuffleModeEnabled(shuffleEnabled);

      if (_queueList.isEmpty) return;

      if (shuffleEnabled && !wasShuffled) {
        _originalQueueList
          ..clear()
          ..addAll(_queueList);

        final currentSong = _queueList[_currentQueueIndex];
        final currentYtId = currentSong['ytid'];

        _queueList.shuffle();

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
      unawaited(Hive.box('settings').put('repeatMode', repeatMode.index));

      // Always set loop mode to off - we handle all repeating through _handleSongCompletion
      // This ensures ProcessingState.completed is always fired for proper song transitions
      await audioPlayer.setLoopMode(LoopMode.off);
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
