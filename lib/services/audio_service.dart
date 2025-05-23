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
  bool sleepTimerExpired = false;

  final List<Map> _queueList = [];
  final List<Map> _historyList = [];
  int _currentQueueIndex = 0;
  bool _isLoadingNextSong = false;
  static const int _maxHistorySize = 50;
  static const int _queueLookahead =
      3; // Number of songs to keep in queue ahead

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        audioPlayer.positionStream,
        audioPlayer.bufferedPositionStream,
        audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  final processingStateMap = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  void _setupEventSubscriptions() {
    audioPlayer.playbackEventStream.listen(_handlePlaybackEvent);
    audioPlayer.durationStream.listen((duration) {
      // Force update when duration changes
      _updatePlaybackState();
      // Also update the media item with duration
      if (_currentQueueIndex < _queueList.length && duration != null) {
        final currentSong = _queueList[_currentQueueIndex];
        final currentMediaItem = mapToMediaItem(currentSong);
        mediaItem.add(currentMediaItem.copyWith(duration: duration));

        // Also update the queue with the duration
        final mediaItems =
            _queueList.map((song) {
              if (song['ytid'] == currentSong['ytid']) {
                return mapToMediaItem(song).copyWith(duration: duration);
              }
              return mapToMediaItem(song);
            }).toList();
        queue.add(mediaItems);
      }
    });
    audioPlayer.currentIndexStream.listen((index) {
      _updatePlaybackState();
    });
    audioPlayer.sequenceStateStream.listen((state) {
      _updatePlaybackState();
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
    try {
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (audioPlayer.playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState:
              processingStateMap[audioPlayer.processingState] ??
              AudioProcessingState.idle,
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
    } catch (e, stackTrace) {
      logger.log('Error updating playback state', e, stackTrace);
    }
  }

  void _handlePlaybackEvent(PlaybackEvent event) {
    try {
      if (event.processingState == ProcessingState.completed &&
          !sleepTimerExpired) {
        // Use a slight delay to ensure the completion is processed
        Future.delayed(
          const Duration(milliseconds: 100),
          _handleSongCompletion,
        );
      }
      _updatePlaybackState();
    } catch (e, stackTrace) {
      logger.log('Error handling playback event', e, stackTrace);
    }
  }

  Future<void> _handleSongCompletion() async {
    try {
      // Add current song to history
      if (_currentQueueIndex < _queueList.length) {
        _addToHistory(_queueList[_currentQueueIndex]);
      }

      // Check if we have next song in queue
      if (hasNext) {
        await skipToNext();
      } else if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        // Restart from beginning if repeat all is enabled
        await _playFromQueue(0);
      } else if (playNextSongAutomatically.value) {
        // Try to get and play recommended song
        await _playRecommendedSong();
      }
    } catch (e, stackTrace) {
      logger.log('Error handling song completion', e, stackTrace);
    }
  }

  Future<void> _playRecommendedSong() async {
    try {
      if (_isLoadingNextSong) return;

      _isLoadingNextSong = true;

      // Get current song for recommendations
      final currentSong =
          _currentQueueIndex < _queueList.length
              ? _queueList[_currentQueueIndex]
              : null;

      if (currentSong != null && currentSong['ytid'] != null) {
        // Get similar song and wait for it
        getSimilarSong(currentSong['ytid']);

        // Wait a bit for the recommendation to be set
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if nextRecommendedSong was set
        if (nextRecommendedSong != null) {
          await addToQueue(nextRecommendedSong!);
          await _playFromQueue(_queueList.length - 1);
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
      // Remove song if it already exists in history
      _historyList
        ..removeWhere((s) => s['ytid'] == song['ytid'])
        // Add to beginning of history
        ..insert(0, song);

      // Limit history size
      if (_historyList.length > _maxHistorySize) {
        _historyList.removeRange(_maxHistorySize, _historyList.length);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding to history', e, stackTrace);
    }
  }

  // Enhanced queue management methods
  Future<void> addToQueue(Map song, {bool playNext = false}) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data for queue', null, null);
        return;
      }

      // Remove duplicates
      _queueList.removeWhere((s) => s['ytid'] == song['ytid']);

      if (playNext) {
        // Add after current song
        final insertIndex = _currentQueueIndex + 1;
        if (insertIndex < _queueList.length) {
          _queueList.insert(insertIndex, song);
        } else {
          _queueList.add(song);
        }
      } else {
        // Add to end of queue
        _queueList.add(song);
      }

      _updateQueueMediaItems();

      // If queue was empty and we're not playing anything, start playing
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

      // Remove duplicates and add songs
      for (final song in songs) {
        if (song['ytid'] != null && song['ytid'].toString().isNotEmpty) {
          _queueList
            ..removeWhere((s) => s['ytid'] == song['ytid'])
            ..add(song);
        }
      }

      _updateQueueMediaItems();

      // Start playing if specified
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

      // Adjust current index if needed
      if (index < _currentQueueIndex) {
        _currentQueueIndex--;
      } else if (index == _currentQueueIndex && _queueList.isNotEmpty) {
        // If we removed the currently playing song, play the next one
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

      // Update current index if needed
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

      // Update current media item
      if (_currentQueueIndex < mediaItems.length) {
        mediaItem.add(mediaItems[_currentQueueIndex]);
      }
    } catch (e, stackTrace) {
      logger.log('Error updating queue media items', e, stackTrace);
    }
  }

  Future<void> _playFromQueue(int index) async {
    try {
      if (index < 0 || index >= _queueList.length) {
        logger.log('Invalid queue index: $index', null, null);
        return;
      }

      _currentQueueIndex = index;

      // Update media items first
      _updateQueueMediaItems();

      await playSong(_queueList[index]);

      // Preload upcoming songs for smoother playback
      _preloadUpcomingSongs();
    } catch (e, stackTrace) {
      logger.log('Error playing from queue', e, stackTrace);
    }
  }

  void _preloadUpcomingSongs() {
    try {
      // Preload next few songs in background for smoother transitions
      for (var i = 1; i <= _queueLookahead; i++) {
        final nextIndex = _currentQueueIndex + i;
        if (nextIndex < _queueList.length) {
          final nextSong = _queueList[nextIndex];
          if (nextSong['ytid'] != null && !(nextSong['isOffline'] ?? false)) {
            // Preload in background (don't await)
            getSong(nextSong['ytid'], nextSong['isLive'] ?? false)
                .then((url) {
                  if (url != null) {
                    final cacheKey =
                        'song_${nextSong['ytid']}_${audioQualitySetting.value}_url';
                    addOrUpdateData('cache', cacheKey, url);
                  }
                })
                .catchError((e) {
                  logger.log(
                    'Error preloading song ${nextSong['ytid']}',
                    e,
                    null,
                  );
                });
          }
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error preloading upcoming songs', e, stackTrace);
    }
  }

  // Getters for queue information
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
  Future<void> play() => audioPlayer.play();
  @override
  Future<void> pause() => audioPlayer.pause();
  @override
  Future<void> stop() => audioPlayer.stop();
  @override
  Future<void> seek(Duration position) => audioPlayer.seek(position);

  @override
  Future<void> fastForward() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds + 15));

  @override
  Future<void> rewind() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds - 15));

  Future<void> playSong(Map song) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data: missing ytid', null, null);
        return;
      }

      final isOffline = song['isOffline'] ?? false;

      if (audioPlayer.playing) await audioPlayer.stop();

      String? songUrl;
      if (isOffline) {
        final audioPath = song['audioPath'];
        if (audioPath == null || audioPath.isEmpty) {
          logger.log(
            'Missing audioPath for offline song: ${song['ytid']}',
            null,
            null,
          );
          return;
        }

        final file = File(audioPath);
        if (!await file.exists()) {
          logger.log('Offline audio file not found: $audioPath', null, null);
          final offlineSong = userOfflineSongs.firstWhere(
            (s) => s['ytid'] == song['ytid'],
            orElse: () => <String, dynamic>{},
          );

          if (offlineSong.isNotEmpty && offlineSong['audioPath'] != null) {
            song['audioPath'] = offlineSong['audioPath'];
            songUrl = offlineSong['audioPath'];
          } else {
            songUrl = await getSong(song['ytid'], song['isLive'] ?? false);
          }
        } else {
          songUrl = audioPath;
        }
      } else {
        songUrl = await getSong(song['ytid'], song['isLive'] ?? false);
      }

      if (songUrl == null || songUrl.isEmpty) {
        logger.log('Failed to get song URL for ${song['ytid']}', null, null);
        return;
      }

      // Find if song is already in queue
      final existingIndex = _queueList.indexWhere(
        (s) => s['ytid'] == song['ytid'],
      );

      if (existingIndex != -1) {
        // Song exists, just update the index
        _currentQueueIndex = existingIndex;
      } else {
        // Add to queue and set as current
        _queueList.add(song);
        _currentQueueIndex = _queueList.length - 1;
      }

      // Update media items after queue changes
      _updateQueueMediaItems();

      final audioSource = await buildAudioSource(song, songUrl, isOffline);

      try {
        await audioPlayer.setAudioSource(audioSource);

        // Wait a moment for the audio source to be ready
        await Future.delayed(const Duration(milliseconds: 100));

        // Update with current duration if available
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
          await addOrUpdateData('cache', cacheKey, songUrl);
        }

        // Update playback state after successful play
        _updatePlaybackState();

        // Preload upcoming songs and get recommendations
        _preloadUpcomingSongs();
        if (playNextSongAutomatically.value) {
          getSimilarSong(song['ytid']);
        }
      } catch (e, stackTrace) {
        logger.log('Error setting audio source', e, stackTrace);
        if (isOffline) {
          logger.log(
            'Attempting to play online version as fallback',
            null,
            null,
          );
          final onlineUrl = await getSong(
            song['ytid'],
            song['isLive'] ?? false,
          );
          if (onlineUrl != null && onlineUrl.isNotEmpty) {
            final onlineSource = await buildAudioSource(song, onlineUrl, false);
            await audioPlayer.setAudioSource(onlineSource);
            await Future.delayed(const Duration(milliseconds: 100));
            if (audioPlayer.duration != null) {
              final currentMediaItem = mapToMediaItem(song);
              mediaItem.add(
                currentMediaItem.copyWith(duration: audioPlayer.duration),
              );
            }
            await audioPlayer.play();
            _updatePlaybackState();
          }
        }
      }
    } catch (e, stackTrace) {
      logger.log('Error playing song', e, stackTrace);
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

  Future<AudioSource> buildAudioSource(
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
      final tag = mapToMediaItem(song);
      return AudioSource.uri(Uri.parse(songUrl), tag: tag);
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
        // Try to get recommended song if we don't have one
        if (nextRecommendedSong == null && _queueList.isNotEmpty) {
          final currentSong = _queueList[_currentQueueIndex];
          if (currentSong['ytid'] != null) {
            getSimilarSong(currentSong['ytid']);
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        if (nextRecommendedSong != null) {
          await addToQueue(nextRecommendedSong!);
          await _playFromQueue(_queueList.length - 1);
          // Clear the recommendation after using it
          nextRecommendedSong = null;
        }
      }
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
        // Play from history
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
    await audioPlayer.seek(Duration.zero);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final shuffleEnabled = shuffleMode != AudioServiceShuffleMode.none;
    shuffleNotifier.value = shuffleEnabled;
    await audioPlayer.setShuffleModeEnabled(shuffleEnabled);
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
          await audioPlayer.setLoopMode(LoopMode.all);
          break;
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
      if (_sleepTimer != null) {
        _sleepTimer!.cancel();
        _sleepTimer = null;
        sleepTimerExpired = false;
        sleepTimerNotifier.value = Duration.zero;
      }
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
    switch (name) {
      case 'clearQueue':
        clearQueue();
        break;
      case 'addToQueue':
        if (extras != null && extras['song'] != null) {
          await addToQueue(
            extras['song'] as Map,
            playNext: extras['playNext'] ?? false,
          );
        }
        break;
      case 'removeFromQueue':
        if (extras != null && extras['index'] != null) {
          await removeFromQueue(extras['index'] as int);
        }
        break;
      case 'reorderQueue':
        if (extras != null &&
            extras['oldIndex'] != null &&
            extras['newIndex'] != null) {
          await reorderQueue(
            extras['oldIndex'] as int,
            extras['newIndex'] as int,
          );
        }
        break;
      default:
        await super.customAction(name, extras);
    }
  }
}
