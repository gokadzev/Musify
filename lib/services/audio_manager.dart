import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Musify/API/musify.dart';
import 'package:just_audio/just_audio.dart';
import '../music.dart';

AudioPlayer? audioPlayer = AudioPlayer();

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

Future play() async {
  await audioPlayer?.setUrl(kUrl!);
  await audioPlayer?.play();
}

Future pause() async {
  await audioPlayer?.pause();
}

Future stop() async {
  await audioPlayer?.stop();
}

Future mute(bool muted) async {
  if (muted) {
    audioPlayer?.setVolume(0);
  } else {
    audioPlayer?.setVolume(1);
  }
}
