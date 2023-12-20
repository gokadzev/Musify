import 'dart:async';
import 'dart:math';

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
    audioPlayer = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          _loudnessEnhancer,
        ],
      ),
    );
    enableBooster();
    _playbackEventSubscription =
        audioPlayer.playbackEventStream.listen(_handlePlaybackEvent);
    _durationSubscription =
        audioPlayer.durationStream.listen(_handleDurationChange);
    _currentIndexSubscription =
        audioPlayer.currentIndexStream.listen(_handleCurrentSongIndexChanged);
    _sequenceStateSubscription =
        audioPlayer.sequenceStateStream.listen(_handleSequenceStateChange);

    _updatePlaybackState();
    try {
      audioPlayer.setAudioSource(_playlist);
    } catch (e) {
      logger.log('Error in setNewPlaylist: $e');
    }

    _initialize();
  }

  final AndroidLoudnessEnhancer _loudnessEnhancer = AndroidLoudnessEnhancer();
  late AudioPlayer audioPlayer;

  late StreamSubscription<PlaybackEvent> _playbackEventSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<int?> _currentIndexSubscription;
  late StreamSubscription<SequenceState?> _sequenceStateSubscription;

  final _playlist = ConcatenatingAudioSource(children: []);
  final Random _random = Random();

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        audioPlayer.positionStream,
        audioPlayer.bufferedPositionStream,
        audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  void _handlePlaybackEvent(PlaybackEvent event) {
    if (event.processingState == ProcessingState.completed &&
        audioPlayer.playing) {
      if (!hasNext) {
        if (playNextSongAutomatically.value) {
          getRandomSong().then(playSong);
        }
      } else {
        skipToNext();
      }
    }
    _updatePlaybackState();
  }

  void _handleDurationChange(Duration? duration) {
    final index = audioPlayer.currentIndex;
    if (index != null && queue.value.isNotEmpty) {
      final newQueue = List<MediaItem>.from(queue.value);
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    }
  }

  void _handleCurrentSongIndexChanged(int? index) {
    if (index != null && queue.value.isNotEmpty) {
      final playlist = queue.value;
      mediaItem.add(playlist[index]);
    }
  }

  void _handleSequenceStateChange(SequenceState? sequenceState) {
    final sequence = sequenceState?.effectiveSequence;
    if (sequence != null && sequence.isNotEmpty) {
      final items = sequence.map((source) => source.tag as MediaItem).toList();
      queue.add(items);
      shuffleNotifier.value = sequenceState?.shuffleModeEnabled ?? false;
    }
  }

  void _updatePlaybackState() {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (audioPlayer.playing) MediaControl.pause else MediaControl.play,
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
        shuffleMode: audioPlayer.shuffleModeEnabled
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
    final session = await AudioSession.instance;
    try {
      await session.configure(const AudioSessionConfiguration.music());
      session.interruptionEventStream.listen((event) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await audioPlayer.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              await audioPlayer.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await audioPlayer.setVolume(1);
              break;
            case AudioInterruptionType.pause:
              await audioPlayer.play();
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });
    } catch (e) {
      logger.log('Error initializing audio session: $e');
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

  bool get hasNext => activePlaylist['list'].isEmpty
      ? audioPlayer.hasNext
      : id + 1 < activePlaylist['list'].length;

  bool get hasPrevious =>
      activePlaylist['list'].isEmpty ? audioPlayer.hasPrevious : id > 0;

  @override
  Future<void> play() => audioPlayer.play();
  @override
  Future<void> pause() => audioPlayer.pause();
  @override
  Future<void> stop() => audioPlayer.stop();
  @override
  Future<void> seek(Duration position) => audioPlayer.seek(position);

  Future<void> playSong(Map song) async {
    try {
      if (song['isOffline'] != null) {
        song['highResImage'] = song['artworkPath'];
        song['lowResImage'] = song['artworkPath'];
        final _audioSource = AudioSource.uri(
          Uri.parse(song['audioPath']),
          tag: mapToMediaItem(song, song['audioPath']),
        );
        await audioPlayer.setAudioSource(_audioSource);
      } else {
        final songUrl = await getSong(
          song['ytid'],
          song['isLive'],
        );
        await checkIfSponsorBlockIsAvailable(song, songUrl);
      }
      await audioPlayer.play();
    } catch (e) {
      logger.log('Error playing song: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    if (id + 1 < activePlaylist['list'].length) {
      id = shuffleNotifier.value
          ? _generateRandomIndex(activePlaylist['list'].length)
          : id + 1;

      await playSong(activePlaylist['list'][id]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (id > 0) {
      id = shuffleNotifier.value
          ? _generateRandomIndex(activePlaylist['list'].length)
          : id - 1;

      await playSong(activePlaylist['list'][id]);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await audioPlayer.seek(
      Duration.zero,
      index: audioPlayer.shuffleModeEnabled
          ? audioPlayer.shuffleIndices![index]
          : index,
    );
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    await _playlist.clear();
    await _playlist.addAll(createAudioSources(queue));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final shuffleEnabled = shuffleMode != AudioServiceShuffleMode.none;
    shuffleNotifier.value = shuffleEnabled;
    await audioPlayer.setShuffleModeEnabled(shuffleEnabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final repeatEnabled = repeatMode != AudioServiceRepeatMode.none;
    repeatNotifier.value = repeatEnabled;
    await audioPlayer.setLoopMode(repeatEnabled ? LoopMode.one : LoopMode.off);
  }

  Future<void> checkIfSponsorBlockIsAvailable(song, songUrl) async {
    try {
      final _audioSource = AudioSource.uri(
        Uri.parse(songUrl),
        tag: mapToMediaItem(song, songUrl),
      );

      if (sponsorBlockSupport.value) {
        final segments = await getSkipSegments(song['ytid']);

        if (segments.isNotEmpty) {
          final start = Duration(seconds: segments[0]['end']!);
          final end = segments.length == 1
              ? null
              : Duration(seconds: segments[1]['start']!);

          await audioPlayer.setAudioSource(
            ClippingAudioSource(
              child: _audioSource,
              start: start,
              end: end,
              tag: _audioSource.tag,
            ),
          );
          return;
        }
      }

      await audioPlayer.setAudioSource(_audioSource);
    } catch (e) {
      logger.log('Error checking sponsor block: $e');
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

  Future enableBooster() async {
    await _loudnessEnhancer.setEnabled(true);
    await _loudnessEnhancer.setTargetGain(0.5);
  }

  Future mute() async {
    await audioPlayer.setVolume(audioPlayer.volume == 0 ? 1 : 0);
    muteNotifier.value = audioPlayer.volume == 0;
  }

  int _generateRandomIndex(int length) {
    var randomIndex = _random.nextInt(length);

    while (randomIndex == id) {
      randomIndex = _random.nextInt(length);
    }

    return randomIndex;
  }
}
