import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/helper/mediaitem.dart';
import 'package:musify/main.dart';
import 'package:musify/services/audio_handler.dart';
import 'package:musify/services/data_manager.dart';

final _equalizer = AndroidEqualizer();
final _loudnessEnhancer = AndroidLoudnessEnhancer();
final _audioHandler = getIt<AudioHandler>();

AudioPlayer audioPlayer = AudioPlayer(
  audioPipeline: AudioPipeline(
    androidAudioEffects: [
      _loudnessEnhancer,
      _equalizer,
    ],
  ),
);

ValueNotifier<Duration?> duration = ValueNotifier<Duration?>(Duration.zero);
ValueNotifier<Duration?> position = ValueNotifier<Duration?>(Duration.zero);

final shuffleNotifier = ValueNotifier<bool>(false);
final repeatNotifier = ValueNotifier<bool>(false);
final playerState = ValueNotifier<PlayerState>(audioPlayer.playerState);
final prefferedFileExtension = ValueNotifier<String>(
  Hive.box('settings').get('audioFileType', defaultValue: 'mp3') as String,
);
final playNextSongAutomatically = ValueNotifier<bool>(
  Hive.box('settings').get('playNextSongAutomatically', defaultValue: false),
);
final sponsorBlockSupport = ValueNotifier<bool>(
  Hive.box('settings').get('sponsorBlockSupport', defaultValue: false),
);

bool get hasNext => activePlaylist.isEmpty
    ? audioPlayer.hasNext
    : id + 1 <= activePlaylist.length;

bool get hasPrevious =>
    activePlaylist.isEmpty ? audioPlayer.hasPrevious : id - 1 >= 0;

String get durationText =>
    duration.value != null ? duration.value.toString().split('.').first : '';

String get positionText =>
    position.value != null ? position.value.toString().split('.').first : '';

bool isMuted = false;

Future<void> playSong(Map song) async {
  if (song['ytid'].length == 0) {
    await MyAudioHandler()
        .addQueueItem(mapToMediaItem(song, song['songUrl'].toString()));
  } else {
    final songUrl = await getSong(song['ytid'], true);

    if (sponsorBlockSupport.value) {
      final segments = await getSkipSegments(song['ytid']);
      if (segments.isNotEmpty) {
        if (segments.length == 1) {
          await MyAudioHandler().addQueueItem(
            mapToMediaItem(song, songUrl),
            Duration(seconds: segments[0]['end']!),
          );
        } else {
          await MyAudioHandler().addQueueItem(
            mapToMediaItem(song, songUrl),
            Duration(seconds: segments[0]['end']!),
            Duration(seconds: segments[1]['start']!),
          );
        }
      } else {
        await MyAudioHandler().addQueueItem(mapToMediaItem(song, songUrl));
      }
    } else {
      await MyAudioHandler().addQueueItem(mapToMediaItem(song, songUrl));
    }
  }
  play();
}

Future changeShuffleStatus() async {
  if (shuffleNotifier.value == true) {
    await audioPlayer.setShuffleModeEnabled(false);
  } else {
    await audioPlayer.setShuffleModeEnabled(true);
  }
}

void changeAutoPlayNextStatus() {
  if (playNextSongAutomatically.value == false) {
    playNextSongAutomatically.value = true;
    addOrUpdateData('settings', 'playNextSongAutomatically', true);
  } else {
    playNextSongAutomatically.value = false;
    addOrUpdateData('settings', 'playNextSongAutomatically', false);
  }
}

Future changeLoopStatus() async {
  if (repeatNotifier.value == false) {
    repeatNotifier.value = true;
    await audioPlayer.setLoopMode(LoopMode.one);
  } else {
    repeatNotifier.value = false;
    await audioPlayer.setLoopMode(LoopMode.off);
  }
}

void changeSponsorBlockStatus() {
  if (sponsorBlockSupport.value == false) {
    sponsorBlockSupport.value = true;
    addOrUpdateData('settings', 'sponsorBlockSupport', true);
  } else {
    sponsorBlockSupport.value = false;
    addOrUpdateData('settings', 'sponsorBlockSupport', false);
  }
}

Future enableBooster() async {
  await _loudnessEnhancer.setEnabled(true);
  await _loudnessEnhancer.setTargetGain(1);
}

void play() => _audioHandler.play();

void pause() => _audioHandler.pause();

void stop() => _audioHandler.stop();

void playNext() => _audioHandler.skipToNext();

void playPrevious() => _audioHandler.skipToPrevious();

Future mute(bool muted) async {
  if (muted) {
    await audioPlayer.setVolume(0);
  } else {
    await audioPlayer.setVolume(1);
  }
}
