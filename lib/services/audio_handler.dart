import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/helper/mediaitem.dart';
import 'package:musify/services/audio_manager.dart';

class MyAudioHandler extends BaseAudioHandler {
  MyAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
    _listenForPositionChanges();
    _listenProcessingStates();
  }

  @override
  Future<void> onTaskRemoved() async {
    await audioPlayer.stop().then((_) => audioPlayer.dispose());
    await super.onTaskRemoved();
  }

  final ConcatenatingAudioSource _playlist =
      ConcatenatingAudioSource(children: []);

  Future<void> _loadEmptyPlaylist() async {
    try {
      await audioPlayer.setAudioSource(_playlist);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    audioPlayer.playbackEventStream.listen((PlaybackEvent event) {
      final playing = audioPlayer.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop
          ],
          systemActions: const {
            MediaAction.seek,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[audioPlayer.processingState]!,
          repeatMode: const {
            LoopMode.off: AudioServiceRepeatMode.none,
            LoopMode.one: AudioServiceRepeatMode.one,
            LoopMode.all: AudioServiceRepeatMode.all,
          }[audioPlayer.loopMode]!,
          shuffleMode: (audioPlayer.shuffleModeEnabled)
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none,
          playing: playing,
          updatePosition: position.value ?? Duration.zero,
          bufferedPosition: position.value ?? Duration.zero,
          speed: audioPlayer.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  void _listenProcessingStates() {
    audioPlayer.playerStateStream.listen((state) async {
      playerState.value = state;
      if (state.processingState == ProcessingState.completed) {
        await pause();
        await audioPlayer.seek(Duration.zero);
      }
    });
  }

  void _listenForDurationChanges() {
    audioPlayer.durationStream.listen((d) {
      duration.value = d;
      var index = audioPlayer.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (audioPlayer.shuffleModeEnabled) {
        index = audioPlayer.shuffleIndices![index];
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: d);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  bool canBeSkipped = false;

  void _listenForPositionChanges() {
    audioPlayer.positionStream.listen((p) async {
      position.value = p;
      final isNotLoading =
          playerState.value.processingState != ProcessingState.loading;
      final durationIsNotNull = audioPlayer.duration != null;
      if (isNotLoading &&
          durationIsNotNull &&
          p.inSeconds == audioPlayer.duration!.inSeconds - 5) {
        if (!hasNext && playNextSongAutomatically.value) {
          final randomSong = await getRandomSong();
          final randomSongUrl = await getSong(randomSong['ytid'], true);
          await addQueueItem(mapToMediaItem(randomSong, randomSongUrl));
        }
      } else if (isNotLoading &&
          durationIsNotNull &&
          p.inSeconds == audioPlayer.duration!.inSeconds - 1) {
        canBeSkipped = true;
      } else if (isNotLoading &&
          durationIsNotNull &&
          p.inSeconds == audioPlayer.duration!.inSeconds) {
        if (canBeSkipped && hasNext) {
          await skipToNext();
          canBeSkipped = false;
        } else if (canBeSkipped &&
            !hasNext &&
            playNextSongAutomatically.value) {
          await play();
          canBeSkipped = false;
        }
      }
    });
  }

  void _listenForCurrentSongIndexChanges() {
    audioPlayer.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (audioPlayer.shuffleModeEnabled) {
        index = audioPlayer.shuffleIndices![index];
      }
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    audioPlayer.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem);
      queue.add(items.toList());
      shuffleNotifier.value = sequenceState!.shuffleModeEnabled;
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSource = mediaItems.map(_createAudioSource);
    await _playlist.addAll(audioSource.toList());

    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem, [start, end]) async {
    final dynamic audioSource;
    if (start != null || end != null) {
      audioSource = _createClippingAudioSource(mediaItem, start, end);
    } else {
      audioSource = _createAudioSource(mediaItem);
    }

    await _playlist.add(audioSource);

    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(mediaItem.extras!['url'].toString()),
      tag: mediaItem,
    );
  }

  ClippingAudioSource _createClippingAudioSource(
    MediaItem mediaItem, [
    start,
    end,
  ]) {
    if (start != null && end == null) {
      return ClippingAudioSource(
        start: start,
        tag: mediaItem,
        child: AudioSource.uri(
          Uri.parse(mediaItem.extras!['url'].toString()),
          tag: mediaItem,
        ),
      );
    } else if (end != null && start == null) {
      return ClippingAudioSource(
        end: end,
        tag: mediaItem,
        child: AudioSource.uri(
          Uri.parse(mediaItem.extras!['url'].toString()),
          tag: mediaItem,
        ),
      );
    } else {
      return ClippingAudioSource(
        start: start,
        end: end,
        tag: mediaItem,
        child: AudioSource.uri(
          Uri.parse(mediaItem.extras!['url'].toString()),
          tag: mediaItem,
        ),
      );
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);

    final newQueue = queue.value..removeAt(index);
    queue.add(newQueue);
  }

  @override
  Future<void> play() => audioPlayer.play();

  @override
  Future<void> pause() => audioPlayer.pause();

  @override
  Future<void> seek(Duration position) => audioPlayer.seek(position);

  @override
  Future<void> skipToNext() async {
    if (activePlaylist.isEmpty) {
      await audioPlayer.seekToNext();
    } else if (hasNext) {
      await playSong(activePlaylist[id + 1]);
      id = id + 1;
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (activePlaylist.isEmpty) {
      await audioPlayer.seekToPrevious();
    } else if (hasPrevious) {
      await playSong(activePlaylist[id - 1]);
      id = id - 1;
    }
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
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await audioPlayer.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await audioPlayer.setShuffleModeEnabled(false);
    } else {
      await audioPlayer.shuffle();
      await audioPlayer.setShuffleModeEnabled(true);
    }
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await audioPlayer.dispose();
      await super.stop();
    }
  }

  @override
  Future<void> stop() async {
    await audioPlayer.stop();
    return super.stop();
  }
}
