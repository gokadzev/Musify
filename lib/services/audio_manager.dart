import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../music.dart';

ConcatenatingAudioSource? _playlist = ConcatenatingAudioSource(children: []);

AudioPlayer? audioPlayer = AudioPlayer();
AudioHandler? _audioHandler;

final durationNotifier = ValueNotifier<Duration?>(Duration.zero);

bool get hasNext => audioPlayer!.hasNext;

bool get hasPrevious => audioPlayer!.hasPrevious;

final buttonNotifier = ValueNotifier<MPlayerState>(MPlayerState.paused);
final kUrlNotifier = ValueNotifier<String>('');

get durationText =>
    duration != null ? duration.toString().split('.').first : '';

get positionText =>
    position != null ? position.toString().split('.').first : '';

bool isMuted = false;

Future<void> playSong(int id, var context) async {
  try {
    await fetchSongDetails(id);
    await audioPlayer?.setUrl(kUrl!);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioApp(),
      ),
    );
  } catch (e) {
    artist = "Unknown";
  }
}

Future addToQueue(audioUrl, audio) async {
  // in testing mode
  final song = Uri.parse(audioUrl);
  await _playlist?.add(AudioSource.uri(song, tag: audio));
}

Future play() async {
  await audioPlayer?.setUrl(kUrl!);
  await audioPlayer?.play();
  await _audioHandler?.play();
}

Future pause() async {
  await audioPlayer?.pause();
  await _audioHandler?.pause();
}

Future stop() async {
  await audioPlayer?.stop();
  await _audioHandler?.stop();
}

Future mute(bool muted) async {
  if (muted) {
    audioPlayer?.setVolume(0);
  } else {
    audioPlayer?.setVolume(1);
  }
}

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'me.musify',
      androidNotificationChannelName: 'Musify',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  MyAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  @override
  Future stop() async {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
    ));

    audioPlayer?.stop();
  }

  @override
  Future<void> play() async {
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [MediaControl.pause],
    ));

    audioPlayer?.play();
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [MediaControl.play],
    ));
    audioPlayer?.pause();
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    audioPlayer?.playbackEventStream.listen((PlaybackEvent event) {
      final playing = audioPlayer!.playing;
      mediaItem.add(MediaItem(
        id: kUrl!,
        album: album!,
        title: title!,
        artist: artist!,
        artUri: Uri.parse(image!),
      ));
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious, //not working yet
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext, // not working yet
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
        }[audioPlayer!.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[audioPlayer!.loopMode]!,
        shuffleMode: (audioPlayer!.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: audioPlayer!.position,
        bufferedPosition: audioPlayer!.bufferedPosition,
        speed: audioPlayer!.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }
}
