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
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/services/ytmusic_queue_service.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:rxdart/rxdart.dart';

class MusifyAudioHandler extends BaseAudioHandler {
  MusifyAudioHandler() {
    _androidEqualizer = AndroidEqualizer();
    audioPlayer = AudioPlayer(
      audioPipeline: Platform.isAndroid
          ? AudioPipeline(androidAudioEffects: [_androidEqualizer])
          : AudioPipeline(),
      audioLoadConfiguration: const AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          maxBufferDuration: Duration(seconds: 60),
          bufferForPlaybackDuration: Duration(milliseconds: 500),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 3),
        ),
      ),
    );

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

  late final AndroidEqualizer _androidEqualizer;
  late final AudioPlayer audioPlayer;
  bool _equalizerInitialized = false;
  Future<bool>? _equalizerInitFuture;
  DateTime _equalizerRetryNotBefore = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _sleepTimer;
  Timer? _debounceTimer;
  Timer? _queueJumpDebounceTimer;
  bool sleepTimerExpired = false;

  final List<Map> _queueList = [];
  final List<Map> _originalQueueList = [];
  final List<Map> _historyList = [];
  final BehaviorSubject<List<Map>> _queueMapStream =
      BehaviorSubject<List<Map>>.seeded([]);
  int _currentQueueIndex = 0;
  int _currentLoadingIndex = -1;
  int _currentLoadingTransitionId = -1;
  int? _pendingQueuePlaybackIndex;
  int _activeTransitionId = 0;
  bool _isUpdatingState = false;
  int _songTransitionCounter = 0;
  bool _completionEventPending = false;

  String? _lastError;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;

  static const int _maxHistorySize = 50;
  static const int _queueLookahead = 3;
  static const int _queueHydrationThreshold = 2;
  static const int _preferredFreshQueueAppendCount = 15;
  static const int _maxQueueHydrationPages = 3;
  static const int _maxConcurrentPreloads = 2;
  static const Duration _errorRetryDelay = Duration(seconds: 2);
  static const Duration _songTransitionTimeout = Duration(seconds: 30);
  static const Duration _debounceInterval = Duration(milliseconds: 150);
  static const Duration _queueJumpDebounceInterval = Duration(
    milliseconds: 120,
  );

  int _activePreloadCount = 0;
  final Set<String> _preloadingYtIds = <String>{};
  final Set<String> _preloadedYtIds = <String>{};
  bool _queueHydrationInProgress = false;
  String? _lastQueueHydrationKey;
  String? _ytQueueContinuationToken;

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
            logger.log(
              'Playback event stream error',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );

    audioPlayer.processingStateStream.distinct().listen(
      _handleProcessingStateChange,
      onError: (error, stackTrace) {
        logger.log(
          'Processing state stream error',
          error: error,
          stackTrace: stackTrace,
        );
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
            logger.log(
              'Duration stream error',
              error: error,
              stackTrace: stackTrace,
            );
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
            logger.log(
              'Player state stream error',
              error: error,
              stackTrace: stackTrace,
            );
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
            logger.log(
              'Current index stream error',
              error: error,
              stackTrace: stackTrace,
            );
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
    final capturedQueueIndex = _currentQueueIndex;
    final capturedTransitionCounter = _songTransitionCounter;

    Future.microtask(() async {
      try {
        if (_currentQueueIndex >= _queueList.length) return;

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
        logger.log(
          'Error updating media item with duration',
          error: e,
          stackTrace: stackTrace,
        );
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
      logger.log(
        'Error initializing audio session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _ensureEqualizerConfigured({bool force = false}) async {
    if (!Platform.isAndroid) return false;
    if (_equalizerInitialized) return true;

    final now = DateTime.now();
    if (!force && now.isBefore(_equalizerRetryNotBefore)) {
      return false;
    }

    if (!force && audioPlayer.audioSource == null) {
      return false;
    }

    final inFlight = _equalizerInitFuture;
    if (inFlight != null) {
      return inFlight;
    }

    _equalizerInitFuture = _configureEqualizer();
    try {
      return await _equalizerInitFuture!;
    } finally {
      _equalizerInitFuture = null;
    }
  }

  Future<bool> _configureEqualizer() async {
    try {
      final params = await _androidEqualizer.parameters.timeout(
        const Duration(seconds: 3),
      );

      final savedGains = equalizerBandGains.value;
      if (savedGains.isNotEmpty) {
        for (var i = 0; i < params.bands.length && i < savedGains.length; i++) {
          final clamped = savedGains[i].clamp(
            params.minDecibels,
            params.maxDecibels,
          );
          await params.bands[i].setGain(clamped);
        }
      }

      await _androidEqualizer.setEnabled(equalizerEnabled.value);
      _equalizerInitialized = true;
      _equalizerRetryNotBefore = DateTime.fromMillisecondsSinceEpoch(0);
      return true;
    } catch (e, stackTrace) {
      _equalizerRetryNotBefore = DateTime.now().add(
        const Duration(seconds: 10),
      );
      logger.log(
        'Equalizer initialization deferred',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  bool get isEqualizerSupported => Platform.isAndroid;

  Future<AndroidEqualizerParameters?> getEqualizerParameters() async {
    if (!Platform.isAndroid) return null;
    final initialized = await _ensureEqualizerConfigured();
    if (!initialized) return null;
    try {
      return await _androidEqualizer.parameters.timeout(
        const Duration(seconds: 2),
      );
    } catch (e, stackTrace) {
      logger.log(
        'Failed to get equalizer parameters',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    final initialized = await _ensureEqualizerConfigured(force: true);
    if (!initialized) return;
    try {
      await _androidEqualizer.setEnabled(enabled);
      equalizerEnabled.value = enabled;
      unawaited(addOrUpdateData('settings', 'equalizerEnabled', enabled));
    } catch (e, stackTrace) {
      logger.log(
        'Failed to set equalizer enabled state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setEqualizerBandGain(int index, double gain) async {
    if (!Platform.isAndroid) return;
    final initialized = await _ensureEqualizerConfigured(force: true);
    if (!initialized) return;

    try {
      final params = await _androidEqualizer.parameters;
      if (index < 0 || index >= params.bands.length) {
        return;
      }

      final clamped = gain.clamp(params.minDecibels, params.maxDecibels);
      await params.bands[index].setGain(clamped);

      final gains = params.bands.map((band) => band.gain).toList();
      equalizerBandGains.value = gains;
      unawaited(addOrUpdateData('settings', 'equalizerBandGains', gains));
    } catch (e, stackTrace) {
      logger.log(
        'Failed to set equalizer band gain',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> resetEqualizerBands() async {
    if (!Platform.isAndroid) return;
    final initialized = await _ensureEqualizerConfigured(force: true);
    if (!initialized) return;

    try {
      final params = await _androidEqualizer.parameters;
      for (final band in params.bands) {
        await band.setGain(0);
      }
      final gains = List<double>.filled(params.bands.length, 0);
      equalizerBandGains.value = gains;
      unawaited(addOrUpdateData('settings', 'equalizerBandGains', gains));
    } catch (e, stackTrace) {
      logger.log(
        'Failed to reset equalizer bands',
        error: e,
        stackTrace: stackTrace,
      );
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
        logger.log(
          'Error updating playback state',
          error: e,
          stackTrace: stackTrace,
        );
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
      logger.log(
        'Error handling processing state change',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handlePlaybackError() {
    _consecutiveErrors++;
    logger.log(
      'Playback error occurred. Consecutive errors: $_consecutiveErrors',
      error: _lastError,
    );

    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      logger.log('Max consecutive errors reached. Stopping playback.');
      stop();
      return;
    }

    if (hasNext ||
        (repeatNotifier.value == AudioServiceRepeatMode.all &&
            _queueList.isNotEmpty)) {
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
      logger.log(
        'Error handling song completion',
        error: e,
        stackTrace: stackTrace,
      );
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
      logger.log('Error adding to history', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> addToQueue(Map song, {bool playNext = false}) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data for queue');
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
      logger.log('Error adding to queue', error: e, stackTrace: stackTrace);
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

        final stalePreloadingEntries = _preloadingYtIds
            .where((ytid) => !queueYtIds.contains(ytid))
            .toList();

        for (final ytid in stalePreloadingEntries) {
          _preloadingYtIds.remove(ytid);
        }

        if (oldPreloadedSongs.isNotEmpty || stalePreloadingEntries.isNotEmpty) {
          logger.log(
            'Cleaned up ${oldPreloadedSongs.length + stalePreloadingEntries.length} old preload entries',
          );
        }
      } catch (e, stackTrace) {
        logger.log(
          'Error cleaning up preloaded songs',
          error: e,
          stackTrace: stackTrace,
        );
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
        _lastQueueHydrationKey = null;
        _ytQueueContinuationToken = null;
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
      logger.log(
        'Error adding playlist to queue',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> removeFromQueue(int index) async {
    try {
      if (index < 0 || index >= _queueList.length) return;

      final removedSong = _queueList[index];
      _queueList.removeAt(index);

      if (shuffleNotifier.value && _originalQueueList.isNotEmpty) {
        _originalQueueList.removeWhere(
          (s) => s['ytid'] != null && s['ytid'] == removedSong['ytid'],
        );
      }

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
      logger.log('Error removing from queue', error: e, stackTrace: stackTrace);
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
      logger.log('Error reordering queue', error: e, stackTrace: stackTrace);
    }
  }

  void clearQueue() {
    try {
      _queueJumpDebounceTimer?.cancel();
      _pendingQueuePlaybackIndex = null;
      _queueList.clear();
      _originalQueueList.clear();
      _lastQueueHydrationKey = null;
      _ytQueueContinuationToken = null;
      _currentQueueIndex = 0;
      _activeTransitionId = -1;
      _currentLoadingIndex = -1;
      _currentLoadingTransitionId = -1;
      _resetPreloadingState();
      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      logger.log('Error clearing queue', error: e, stackTrace: stackTrace);
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

      _queueMapStream.add(List.unmodifiable(_queueList));

      if (_currentQueueIndex < mediaItems.length) {
        final currentMediaItem = mediaItems[_currentQueueIndex];
        mediaItem.add(currentMediaItem);
      }
    } catch (e, stackTrace) {
      logger.log(
        'Error updating queue media items',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _scheduleQueueHydrationWithPriority({required bool force}) {
    Future.microtask(() async {
      try {
        await _hydrateQueueFromYouTube(force: force);
      } catch (e, stackTrace) {
        logger.log(
          'Error scheduling queue hydration',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<bool> _hydrateQueueFromYouTube({bool force = false}) async {
    if (_queueHydrationInProgress || _queueList.isEmpty) {
      return false;
    }

    if (!force) {
      final remainingTracks = _queueList.length - _currentQueueIndex - 1;
      if (remainingTracks >= _queueHydrationThreshold) {
        return false;
      }
    }

    final seedSong = currentSong;
    final seedYtid = seedSong?['ytid']?.toString() ?? '';
    if (seedSong == null || seedYtid.isEmpty) {
      return false;
    }

    final playlistId = seedSong['queuePlaylistId']?.toString();
    final params = seedSong['queueParams']?.toString();
    final hydrationKey =
        '$seedYtid|${playlistId ?? ''}|${params ?? ''}|$_currentQueueIndex|${_queueList.length}';

    if (!force && _lastQueueHydrationKey == hydrationKey) {
      return false;
    }

    _queueHydrationInProgress = true;

    try {
      final existingIds = _queueList
          .map((song) => song['ytid']?.toString())
          .whereType<String>()
          .toSet();
      final appendedSongs = <Map>[];
      final isAtQueueEnd = _currentQueueIndex >= _queueList.length - 1;
      final shouldSeedFreshQueue =
          force || _queueList.length <= 1 || isAtQueueEnd;
      var nextContinuationToken = shouldSeedFreshQueue
          ? null
          : _ytQueueContinuationToken;

      var pagesFetched = 0;
      while (pagesFetched < _maxQueueHydrationPages) {
        final result = await YtMusicQueueService().fetchQueue(
          seedYtid,
          playlistId: playlistId,
          params: params,
          continuationToken: nextContinuationToken,
        );
        pagesFetched++;

        if (result == null || result.tracks.isEmpty) {
          if (nextContinuationToken != null &&
              nextContinuationToken.isNotEmpty) {
            nextContinuationToken = null;
            continue;
          }
          break;
        }

        _ytQueueContinuationToken = result.continuationToken;
        final resolvedPlaylistId = result.playlistId;
        final resolvedParams = result.params;

        for (final track in result.tracks) {
          if (track.ytid == seedYtid || existingIds.contains(track.ytid)) {
            continue;
          }

          final song = track.toSongMap()
            ..putIfAbsent('queuePlaylistId', () => resolvedPlaylistId)
            ..putIfAbsent('queueParams', () => resolvedParams);

          appendedSongs.add(song);
          existingIds.add(track.ytid);
        }

        if (!shouldSeedFreshQueue ||
            appendedSongs.length >= _preferredFreshQueueAppendCount ||
            result.continuationToken == null ||
            result.continuationToken!.isEmpty) {
          break;
        }

        nextContinuationToken = result.continuationToken;
      }

      if (appendedSongs.isEmpty) {
        final fallbackSongs = await fetchRelatedSongsQueue(
          seedYtid,
          limit: _preferredFreshQueueAppendCount,
        );
        for (final song in fallbackSongs) {
          final fallbackYtid = song['ytid']?.toString();
          if (fallbackYtid == null ||
              fallbackYtid.isEmpty ||
              fallbackYtid == seedYtid ||
              existingIds.contains(fallbackYtid)) {
            continue;
          }

          appendedSongs.add(song);
          existingIds.add(fallbackYtid);
        }
      }

      if (appendedSongs.isEmpty) {
        return false;
      }

      _queueList.addAll(appendedSongs);
      _lastQueueHydrationKey = hydrationKey;
      if (shuffleNotifier.value && _originalQueueList.isNotEmpty) {
        _originalQueueList.addAll(appendedSongs);
      }
      _updateQueueMediaItems();
      _cleanupOldPreloadedSongs();
      _preloadUpcomingSongs();
      return true;
    } catch (e, stackTrace) {
      logger.log(
        'Error hydrating queue from YouTube Music',
        error: e,
        stackTrace: stackTrace,
      );
      if (_lastQueueHydrationKey == hydrationKey) {
        _lastQueueHydrationKey = null;
      }
      return false;
    } finally {
      _queueHydrationInProgress = false;
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
    } catch (e, stackTrace) {
      logger.log(
        'Error emitting optimistic loading state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _playFromQueue(int index) async {
    var currentTransitionId = -1;
    try {
      if (index < 0 || index >= _queueList.length) {
        logger.log('Invalid queue index: $index');
        return;
      }

      // Start new transition
      _songTransitionCounter++;
      currentTransitionId = _songTransitionCounter;
      _activeTransitionId = currentTransitionId;
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

      _completionEventPending = false;
      await audioPlayer.stop();

      await Future.microtask(() {
        mediaItem.add(currentMediaItem);
      });

      _emitOptimisticLoadingState(
        queueIndex: _currentQueueIndex,
        mediaId: uniqueId,
      );

      final success = await playSong(
        _queueList[index],
        mediaId: uniqueId,
        transitionId: currentTransitionId,
      );

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
      logger.log('Error playing from queue', error: e, stackTrace: stackTrace);
      _handlePlaybackError();
    } finally {
      if (currentTransitionId == _currentLoadingTransitionId) {
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
                !isSongAlreadyOffline(ytid) &&
                !_preloadedYtIds.contains(ytid) &&
                !_preloadingYtIds.contains(ytid)) {
              songsToPreload.add(nextSong);
            }
          }
        }

        await _preloadSongsSequentially(songsToPreload);
      } catch (e, stackTrace) {
        logger.log(
          'Error in _preloadUpcomingSongs',
          error: e,
          stackTrace: stackTrace,
        );
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

      unawaited(_preloadSingleSongControlled(song));
    }
  }

  Future<void> _preloadSingleSongControlled(Map nextSong) async {
    final ytid = nextSong['ytid'];
    if (ytid == null) return;

    _preloadingYtIds.add(ytid);
    _activePreloadCount++;
    String? preloadUrl;

    try {
      // fetchSongStreamUrl handles caching, freshness checks, and validation
      preloadUrl = await fetchSongStreamUrl(ytid, nextSong['isLive'] ?? false)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              logger.log('Preload timeout for song $ytid');
              return null;
            },
          );
    } catch (e, stackTrace) {
      logger.log(
        'Error preloading song $ytid',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _preloadingYtIds.remove(ytid);
      if (_activePreloadCount > 0) {
        _activePreloadCount--;
      }
      if (preloadUrl != null && preloadUrl.isNotEmpty) {
        _preloadedYtIds.add(ytid);
      }
    }
  }

  List<Map> get currentQueue => List.unmodifiable(_queueList);
  List<Map> get playHistory => List.unmodifiable(_historyList);
  Stream<List<Map>> get queueAsMapStream => _queueMapStream.stream;
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
      logger.log('Error in onTaskRemoved', error: e, stackTrace: stackTrace);
    }
    await super.onTaskRemoved();
  }

  @override
  Future<void> play() async {
    try {
      await audioPlayer.play();
    } catch (e, stackTrace) {
      logger.log('Error in play()', error: e, stackTrace: stackTrace);
      _lastError = e.toString();
    }
  }

  @override
  Future<void> pause() async {
    try {
      await audioPlayer.pause();
    } catch (e, stackTrace) {
      logger.log('Error in pause()', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    _debounceTimer?.cancel();
    _queueJumpDebounceTimer?.cancel();
    _pendingQueuePlaybackIndex = null;
    _completionEventPending = false;
    _activeTransitionId = -1;
    _currentLoadingIndex = -1;
    _currentLoadingTransitionId = -1;
    try {
      await audioPlayer.stop();
      _lastError = null;
      _consecutiveErrors = 0;
      _resetPreloadingState();
    } catch (e, stackTrace) {
      logger.log('Error in stop()', error: e, stackTrace: stackTrace);
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
      logger.log('Error in seek()', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> fastForward() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds + 15));

  @override
  Future<void> rewind() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds - 15));

  bool _isActiveTransition(int transitionId) =>
      transitionId == _activeTransitionId &&
      transitionId == _currentLoadingTransitionId;

  void _requestQueuePlayback(int index, {bool immediate = false}) {
    _queueJumpDebounceTimer?.cancel();
    _pendingQueuePlaybackIndex = index;
    _previewQueueSelection(index);

    if (immediate) {
      _pendingQueuePlaybackIndex = null;
      unawaited(_playFromQueue(index));
      return;
    }

    _queueJumpDebounceTimer = Timer(_queueJumpDebounceInterval, () {
      _queueJumpDebounceTimer = null;
      final targetIndex = _pendingQueuePlaybackIndex;
      _pendingQueuePlaybackIndex = null;
      if (targetIndex != null) {
        unawaited(_playFromQueue(targetIndex));
      }
    });
  }

  void _previewQueueSelection(int index) {
    if (index < 0 || index >= _queueList.length) {
      return;
    }

    _currentQueueIndex = index;
    final currentMediaItem = _getMediaItemForQueue(_queueList[index], index);
    mediaItem.add(currentMediaItem);
    _emitOptimisticLoadingState(
      queueIndex: index,
      mediaId: currentMediaItem.id,
    );
    if (audioPlayer.playing || _currentLoadingIndex >= 0) {
      unawaited(audioPlayer.stop());
    }
  }

  Future<void> playSingleSong(Map song) async {
    await addPlaylistToQueue([song], replace: true);
  }

  Future<bool> playSong(
    Map song, {
    String? mediaId,
    required int transitionId,
  }) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data: missing ytid');
        return false;
      }

      _lastError = null;
      var isOffline = false;
      try {
        final ytid = song['ytid'];
        if (ytid != null && ytid.toString().isNotEmpty) {
          final offlineSong = getOfflineSongByYtid(ytid.toString());
          if (offlineSong.isNotEmpty &&
              offlineSong['audioPath'] != null &&
              offlineSong['audioPath'].toString().isNotEmpty) {
            isOffline = true;
            song['audioPath'] = offlineSong['audioPath'];
            if (offlineSong['artworkPath'] != null) {
              song['artworkPath'] = offlineSong['artworkPath'];
            }
          }
        }
      } catch (e, stackTrace) {
        logger.log(
          'Error while checking offline songs',
          error: e,
          stackTrace: stackTrace,
        );
      }

      if (audioPlayer.playing) await audioPlayer.pause();

      _emitOptimisticLoadingState(
        song: song,
        includeMediaItem: true,
        mediaId: mediaId,
      );

      if (!_isActiveTransition(transitionId)) {
        return false;
      }

      var songUrl = await _getSongUrl(song, isOffline);
      if (!_isActiveTransition(transitionId)) {
        return false;
      }

      // If offline file is missing, try falling back to online
      if ((songUrl == null || songUrl.isEmpty) && isOffline) {
        logger.log(
          'Offline file missing for ${song['ytid']}, switching to online',
        );
        isOffline = false;
        songUrl = await _getSongUrl(song, isOffline);
        if (!_isActiveTransition(transitionId)) {
          return false;
        }
      }

      if (songUrl == null || songUrl.isEmpty) {
        logger.log('Failed to get song URL for ${song['ytid']}');
        _lastError = 'Failed to get song URL';
        return false;
      }

      final audioSource = await buildAudioSource(song, songUrl, isOffline);
      if (!_isActiveTransition(transitionId)) {
        return false;
      }
      if (audioSource == null) {
        logger.log('Failed to build audio source for ${song['ytid']}');
        _lastError = 'Failed to build audio source';
        return false;
      }

      return await _setAudioSourceAndPlay(
        song,
        audioSource,
        songUrl,
        isOffline,
        mediaId: mediaId,
        transitionId: transitionId,
      );
    } catch (e, stackTrace) {
      logger.log('Error playing song', error: e, stackTrace: stackTrace);
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
      logger.log('Missing audioPath for offline song: ${song['ytid']}');
      return null;
    }

    final file = File(audioPath);
    if (await file.exists()) {
      return audioPath;
    }

    logger.log('Offline audio file not found: $audioPath');

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
    required int transitionId,
    bool allowOnlineRetry = true,
  }) async {
    try {
      if (!_isActiveTransition(transitionId)) {
        return false;
      }

      await audioPlayer
          .setAudioSource(audioSource)
          .timeout(_songTransitionTimeout);
      if (!_isActiveTransition(transitionId)) {
        await audioPlayer.stop();
        return false;
      }

      unawaited(_ensureEqualizerConfigured(force: true));
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isActiveTransition(transitionId)) {
        await audioPlayer.stop();
        return false;
      }

      if (audioPlayer.duration != null) {
        var currentMediaItem = mapToMediaItem(song);
        if (mediaId != null) {
          currentMediaItem = currentMediaItem.copyWith(id: mediaId);
        }
        mediaItem.add(
          currentMediaItem.copyWith(duration: audioPlayer.duration),
        );
      }

      if (!_isActiveTransition(transitionId)) {
        await audioPlayer.stop();
        return false;
      }

      final shouldRefreshQueueNow =
          _queueList.length <= 1 || _currentQueueIndex >= _queueList.length - 1;
      _scheduleQueueHydrationWithPriority(force: shouldRefreshQueueNow);

      await audioPlayer.play();

      if (!isOffline) {
        final cacheKey =
            'song_${song['ytid']}_${audioQualitySetting.value}_url';
        unawaited(addOrUpdateData('cache', cacheKey, songUrl));
      }

      _updatePlaybackState();
      Future.delayed(const Duration(seconds: 2), _preloadUpcomingSongs);

      return true;
    } catch (e, stackTrace) {
      logger.log(
        'Error setting audio source',
        error: e,
        stackTrace: stackTrace,
      );

      if (isOffline) {
        return _attemptOfflineFallback(
          song,
          mediaId: mediaId,
          transitionId: transitionId,
        );
      }

      if (allowOnlineRetry) {
        final songId = song['ytid']?.toString();
        if (songId != null && songId.isNotEmpty) {
          final cacheKey = 'song_${songId}_${audioQualitySetting.value}_url';
          await deleteData('cache', cacheKey);

          final refreshedUrl = await fetchSongStreamUrl(
            songId,
            song['isLive'] ?? false,
          );

          if (refreshedUrl != null && refreshedUrl.isNotEmpty) {
            final refreshedSource = await buildAudioSource(
              song,
              refreshedUrl,
              false,
            );

            if (refreshedSource != null) {
              return _setAudioSourceAndPlay(
                song,
                refreshedSource,
                refreshedUrl,
                false,
                mediaId: mediaId,
                transitionId: transitionId,
                allowOnlineRetry: false,
              );
            }
          }
        }
      }

      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> _attemptOfflineFallback(
    Map song, {
    String? mediaId,
    required int transitionId,
  }) async {
    final onlineUrl = await fetchSongStreamUrl(
      song['ytid'],
      song['isLive'] ?? false,
    );
    if (!_isActiveTransition(transitionId)) {
      return false;
    }
    if (onlineUrl != null && onlineUrl.isNotEmpty) {
      final onlineSource = await buildAudioSource(song, onlineUrl, false);
      if (!_isActiveTransition(transitionId)) {
        return false;
      }
      if (onlineSource != null) {
        return _setAudioSourceAndPlay(
          song,
          onlineSource,
          onlineUrl,
          false,
          mediaId: mediaId,
          transitionId: transitionId,
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
      logger.log('Error playing playlist', error: e, stackTrace: stackTrace);
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
      logger.log(
        'Error building audio source',
        error: e,
        stackTrace: stackTrace,
      );
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
      logger.log(
        'Error checking sponsor block',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> skipToSong(int newIndex) async {
    try {
      if (newIndex < 0 || newIndex >= _queueList.length) {
        logger.log('Invalid song index: $newIndex');
        return;
      }
      _requestQueuePlayback(newIndex);
    } catch (e, stackTrace) {
      logger.log('Error skipping to song', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      final baseIndex =
          _pendingQueuePlaybackIndex ??
          (_currentLoadingIndex >= 0
              ? _currentLoadingIndex
              : _currentQueueIndex);
      if (baseIndex < _queueList.length - 1) {
        _requestQueuePlayback(baseIndex + 1);
      } else if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        _requestQueuePlayback(0, immediate: true);
      } else if (_currentLoadingIndex == -1) {
        final extendedQueue = await _hydrateQueueFromYouTube(force: true);
        if (extendedQueue && _currentQueueIndex < _queueList.length - 1) {
          _requestQueuePlayback(_currentQueueIndex + 1, immediate: true);
        }
      }

      _cleanupOldPreloadedSongs();
    } catch (e, stackTrace) {
      logger.log(
        'Error skipping to next song',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      final baseIndex =
          _pendingQueuePlaybackIndex ??
          (_currentLoadingIndex >= 0
              ? _currentLoadingIndex
              : _currentQueueIndex);
      if (baseIndex > 0) {
        _requestQueuePlayback(baseIndex - 1);
      } else if (_historyList.isNotEmpty) {
        final lastSong = _historyList.removeLast();
        _queueList.insert(0, lastSong);
        _currentQueueIndex = 0;
        _updateQueueMediaItems();
        _requestQueuePlayback(0, immediate: true);
      }

      _cleanupOldPreloadedSongs();
    } catch (e, stackTrace) {
      logger.log(
        'Error skipping to previous song',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> playAgain() async {
    try {
      await audioPlayer.seek(Duration.zero);
    } catch (e, stackTrace) {
      logger.log('Error playing again', error: e, stackTrace: stackTrace);
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
      logger.log(
        'Error setting shuffle mode',
        error: e,
        stackTrace: stackTrace,
      );
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
      logger.log('Error setting repeat mode', error: e, stackTrace: stackTrace);
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
      logger.log('Error setting sleep timer', error: e, stackTrace: stackTrace);
    }
  }

  void cancelSleepTimer() {
    try {
      _sleepTimer?.cancel();
      _sleepTimer = null;
      sleepTimerExpired = false;
      sleepTimerNotifier.value = Duration.zero;
    } catch (e, stackTrace) {
      logger.log(
        'Error canceling sleep timer',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void changeSponsorBlockStatus() {
    sponsorBlockSupport.value = !sponsorBlockSupport.value;
    unawaited(
      addOrUpdateData(
        'settings',
        'sponsorBlockSupport',
        sponsorBlockSupport.value,
      ),
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
      logger.log(
        'Error in customAction: $name',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
