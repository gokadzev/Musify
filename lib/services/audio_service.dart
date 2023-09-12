import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/logger_service.dart';
import 'package:musify/services/settings_manager.dart';

class MyAudioHandler extends BaseAudioHandler {
  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  @override
  Future<void> onTaskRemoved() async {
    await audioPlayer.stop().then((_) => audioPlayer.dispose());

    await super.onTaskRemoved();
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    try {
      audioPlayer.playbackEventStream.listen((PlaybackEvent event) {
        playbackState.add(
          playbackState.value.copyWith(
            controls: [
              MediaControl.skipToPrevious,
              if (audioPlayer.playing)
                MediaControl.pause
              else
                MediaControl.play,
              MediaControl.skipToNext,
              MediaControl.stop,
            ],
            systemActions: const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
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
            playing: audioPlayer.playing,
            updatePosition: audioPlayer.position,
            bufferedPosition: audioPlayer.bufferedPosition,
            speed: audioPlayer.speed,
            queueIndex: event.currentIndex,
          ),
        );
      });
    } catch (e) {
      Logger.log('Error in playbackEventStream: $e');
    }
  }

  void _listenForDurationChanges() {
    try {
      audioPlayer.durationStream.listen((d) {
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
    } catch (e) {
      Logger.log('Error in durationStream: $e');
    }
  }

  void _listenForCurrentSongIndexChanges() {
    try {
      audioPlayer.currentIndexStream.listen((index) {
        final playlist = queue.value;
        if (index == null || playlist.isEmpty) return;
        if (audioPlayer.shuffleModeEnabled) {
          index = audioPlayer.shuffleIndices![index];
        }
        mediaItem.add(playlist[index]);
      });
    } catch (e) {
      Logger.log('Error in currentIndexStream: $e');
    }
  }

  void _listenForSequenceStateChanges() {
    try {
      audioPlayer.sequenceStateStream.listen((SequenceState? sequenceState) {
        final sequence = sequenceState?.effectiveSequence;
        if (sequence == null || sequence.isEmpty) return;
        final items = sequence.map((source) => source.tag as MediaItem);
        queue.add(items.toList());
        shuffleNotifier.value = sequenceState!.shuffleModeEnabled;
      });
    } catch (e) {
      Logger.log('Error in sequenceStateStream: $e');
    }
  }

  @override
  Future<void> play() async => audioPlayer.play();
  @override
  Future<void> pause() async => audioPlayer.pause();
  @override
  Future<void> stop() async => audioPlayer.stop();
  @override
  Future<void> seek(Duration position) async => audioPlayer.seek(position);
  @override
  Future<void> skipToNext() async => playNext();
  @override
  Future<void> skipToPrevious() async => playPrevious();
  @override
  Future<void> skipToQueueItem(int index) async {
    await audioPlayer.seek(
      Duration.zero,
      index: audioPlayer.shuffleModeEnabled
          ? audioPlayer.shuffleIndices![index]
          : index,
    );
  }
}
