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
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/io_service.dart';
import 'package:musify/services/playlist_download_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:rxdart/rxdart.dart';

class MusifyAudioHandler extends BaseAudioHandler {
  MusifyAudioHandler() {
    _setupEventSubscriptions();
    _updatePlaybackState();

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

  bool _playInterrupted = false;

  late StreamSubscription<PlaybackEvent> _playbackEventSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<int?> _currentIndexSubscription;
  late StreamSubscription<SequenceState?> _sequenceStateSubscription;

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

  void _handlePlaybackEvent(PlaybackEvent event) {
    try {
      if (event.processingState == ProcessingState.completed &&
          audioPlayer.playing &&
          !sleepTimerExpired) {
        skipToNext();
      }
      _updatePlaybackState();
    } catch (e, stackTrace) {
      logger.log('Error handling playback event', e, stackTrace);
    }
  }

  void _handleDurationChange(Duration? duration) {
    try {
      final index = audioPlayer.currentIndex;
      if (index == null || queue.value.isEmpty) return;

      final newMediaItem = queue.value[index].copyWith(duration: duration);
      mediaItem.add(newMediaItem);

      // Update the queue item with the new duration
      final newQueue = List<MediaItem>.from(queue.value);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);

      _updatePlaybackState();
    } catch (e, stackTrace) {
      logger.log('Error handling duration change', e, stackTrace);
    }
  }

  void _handleCurrentSongIndexChanged(int? index) {
    try {
      if (index != null && queue.value.isNotEmpty) {
        final playlist = queue.value;
        mediaItem.add(playlist[index]);
      }
    } catch (e, stackTrace) {
      logger.log('Error handling current song index change', e, stackTrace);
    }
  }

  void _handleSequenceStateChange(SequenceState? sequenceState) {
    try {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence != null && sequence.isNotEmpty) {
        final items =
            sequence.map((source) => source.tag as MediaItem).toList();
        queue.add(items);
        shuffleNotifier.value = sequenceState?.shuffleModeEnabled ?? false;
      }
    } catch (e, stackTrace) {
      logger.log('Error handling sequence state change', e, stackTrace);
    }
  }

  void _setupEventSubscriptions() {
    _playbackEventSubscription = audioPlayer.playbackEventStream.listen(
      _handlePlaybackEvent,
    );
    _durationSubscription = audioPlayer.durationStream.listen(
      _handleDurationChange,
    );
    _currentIndexSubscription = audioPlayer.currentIndexStream.listen(
      _handleCurrentSongIndexChanged,
    );
    _sequenceStateSubscription = audioPlayer.sequenceStateStream.listen(
      _handleSequenceStateChange,
    );
  }

  void _updatePlaybackState() {
    final hasPreviousOrNext = hasPrevious || hasNext;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (hasPreviousOrNext)
            MediaControl.skipToPrevious
          else
            MediaControl.rewind,
          if (audioPlayer.playing) MediaControl.pause else MediaControl.play,
          if (hasPreviousOrNext)
            MediaControl.skipToNext
          else
            MediaControl.fastForward,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState:
            processingStateMap[audioPlayer.processingState] ??
            AudioProcessingState.idle,
        repeatMode: repeatNotifier.value,
        shuffleMode:
            audioPlayer.shuffleModeEnabled
                ? AudioServiceShuffleMode.all
                : AudioServiceShuffleMode.none,
        playing: audioPlayer.playing,
        updatePosition: audioPlayer.position,
        bufferedPosition: audioPlayer.bufferedPosition,
        speed: audioPlayer.speed,
        queueIndex: audioPlayer.currentIndex ?? 0,
      ),
    );
  }

  Future<void> _initialize() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (!audioPlayer.playing) return;
          switch (event.type) {
            case AudioInterruptionType.duck:
              audioPlayer.setVolume(audioPlayer.volume * 0.5);
              break;
            case AudioInterruptionType.pause:
              pause();
              _playInterrupted = true;
              break;
            case AudioInterruptionType.unknown:
              pause();
              _playInterrupted = true;
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              audioPlayer.setVolume(audioPlayer.volume * 2);
              break;
            case AudioInterruptionType.pause:
              if (_playInterrupted) play();
              break;
            case AudioInterruptionType.unknown:
              break;
          }
          _playInterrupted = false;
        }
      });

      session.becomingNoisyEventStream.listen((_) {
        if (audioPlayer.playing) {
          audioPlayer.pause();
        }
      });
    } catch (e, stackTrace) {
      logger.log('Error initializing audio session', e, stackTrace);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await audioPlayer.stop().then((_) => audioPlayer.dispose());

    await _playbackEventSubscription.cancel();
    await _durationSubscription.cancel();
    await _currentIndexSubscription.cancel();
    await _sequenceStateSubscription.cancel();

    await super.onTaskRemoved();
  }

  bool get hasNext =>
      activePlaylist['list'].isEmpty
          ? audioPlayer.hasNext
          : activeSongId + 1 < activePlaylist['list'].length;

  bool get hasPrevious =>
      activePlaylist['list'].isEmpty
          ? audioPlayer.hasPrevious
          : activeSongId > 0;

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
      final isOffline = song['isOffline'] ?? false;

      if (audioPlayer.playing) await audioPlayer.stop();

      final songUrl =
          isOffline
              ? song['audioPath']
              : await getSong(song['ytid'], song['isLive']);

      final audioSource = await buildAudioSource(song, songUrl, isOffline);

      await audioPlayer.setAudioSource(audioSource);

      await audioPlayer.play();
      if (!isOffline) {
        final cacheKey =
            'song_${song['ytid']}_${audioQualitySetting.value}_url';
        await addOrUpdateData('cache', cacheKey, songUrl);
      }
      if (playNextSongAutomatically.value) getSimilarSong(song['ytid']);
    } catch (e, stackTrace) {
      logger.log('Error playing song', e, stackTrace);
    }
  }

  Future<void> playNext(Map song) async {
    try {
      if (activePlaylist['title'] != 'User queue' &&
          activePlaylist['list'].isEmpty) {
        activePlaylist = {
          'ytid': '',
          'title': 'No Playlist',
          'source': 'user-created',
          'list': [song],
        };
        return playSong(song);
      } else {
        activePlaylist['list'].insert(activeSongId + 1, song);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding song to play next', e, stackTrace);
    }
  }

  Future<void> playPlaylistSong({
    Map<dynamic, dynamic>? playlist,
    required int songIndex,
  }) async {
    try {
      if (playlist != null) {
        final playlistId = playlist['ytid'] ?? playlist['title'];
        final isOffline = offlinePlaylistService.isPlaylistDownloaded(
          playlistId,
        );

        if (isOffline) {
          // For offline playlists, mark each song as offline
          final playlistWithOfflineSongs = Map<String, dynamic>.from(playlist);
          final updatedSongs =
              List.from(playlist['list']).map((song) {
                final updatedSong = Map<dynamic, dynamic>.from(song);
                final audioPath = FilePaths.getAudioPath(song['ytid']);
                final artWorkFilePath = FilePaths.getArtworkPath(song['ytid']);
                final audioFile = File(audioPath);
                final artworkFile = File(artWorkFilePath);

                updatedSong['isOffline'] = audioFile.existsSync();

                if (artworkFile.existsSync()) {
                  updatedSong['artworkPath'] = artWorkFilePath;
                  updatedSong['highResImage'] = artWorkFilePath;
                  updatedSong['lowResImage'] = artWorkFilePath;
                }

                updatedSong['audioPath'] = audioPath;

                return updatedSong;
              }).toList();
          playlistWithOfflineSongs['list'] = updatedSongs;
          activePlaylist = playlistWithOfflineSongs;
        } else {
          activePlaylist = playlist;
        }
      } else if (activePlaylist['list'].isEmpty) {
        logger.log('Error: Attempted to play empty playlist', null, null);
        return;
      }

      activeSongId = songIndex;

      await playSong(activePlaylist['list'][activeSongId]);
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
        final uri = Uri.file(songUrl);
        return AudioSource.uri(uri, tag: tag);
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

      if (segments.isNotEmpty) {
        final start = Duration(seconds: segments[0]['end']!);
        final end =
            segments.length > 1
                ? Duration(seconds: segments[1]['start']!)
                : null;

        return end != null && end != Duration.zero && start < end
            ? ClippingAudioSource(
              child: audioSource,
              start: start,
              end: end,
              tag: audioSource.tag,
            )
            : null;
      }
    } catch (e, stackTrace) {
      logger.log('Error checking sponsor block', e, stackTrace);
    }
    return null;
  }

  Future<void> skipToSong(int newIndex) async {
    if (newIndex >= 0 && newIndex < activePlaylist['list'].length) {
      activeSongId =
          shuffleNotifier.value
              ? _generateRandomIndex(activePlaylist['list'].length)
              : newIndex;

      await playSong(activePlaylist['list'][activeSongId]);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (!hasNext && repeatNotifier.value == AudioServiceRepeatMode.all) {
      // If repeat mode is set to repeat the playlist, start from the beginning
      await skipToSong(0);
    } else if (!hasNext &&
        playNextSongAutomatically.value &&
        nextRecommendedSong != null) {
      // If there's no next song but playNextSongAutomatically is enabled, play the recommended song
      await playSong(nextRecommendedSong);
    } else if (hasNext) {
      // If there is a next song, skip to the next song
      await skipToSong(activeSongId + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (!hasPrevious && repeatNotifier.value == AudioServiceRepeatMode.all) {
      // If repeat mode is set to repeat the playlist, start from the end
      await skipToSong(activePlaylist['list'].length - 1);
    } else if (hasPrevious) {
      // If there is a previous song, skip to the previous song
      await skipToSong(activeSongId - 1);
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
  }

  Future<void> setSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    sleepTimerExpired = false;
    sleepTimerNotifier.value = duration;
    _sleepTimer = Timer(duration, () async {
      // Fade out the volume
      final originalVolume = audioPlayer.volume;
      const fadeSteps = 10;

      for (var i = fadeSteps; i > 0; i--) {
        await audioPlayer.setVolume(originalVolume * i / fadeSteps);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await stop();

      // Reset volume for next playback
      await audioPlayer.setVolume(originalVolume);

      playNextSongAutomatically.value = false;
      sleepTimerExpired = true;
      _sleepTimer = null;
      sleepTimerNotifier.value = null;
    });
  }

  void cancelSleepTimer() {
    if (_sleepTimer != null) {
      _sleepTimer!.cancel();
      _sleepTimer = null;
      sleepTimerExpired = false;
      sleepTimerNotifier.value = null;
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

  int _generateRandomIndex(int length) {
    final random = Random();
    var randomIndex = random.nextInt(length);

    while (randomIndex == activeSongId) {
      randomIndex = random.nextInt(length);
    }

    return randomIndex;
  }
}
