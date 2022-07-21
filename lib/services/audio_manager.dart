import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/helper/mediaitem.dart';
import 'package:musify/main.dart';
import 'package:musify/services/audio_handler.dart';
import 'package:musify/services/ext_storage.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final _equalizer = AndroidEqualizer();
final _loudnessEnhancer = AndroidLoudnessEnhancer();
final _audioHandler = getIt<AudioHandler>();

AudioPlayer? audioPlayer = AudioPlayer(
  audioPipeline: AudioPipeline(
    androidAudioEffects: [
      _loudnessEnhancer,
      _equalizer,
    ],
  ),
);

final durationNotifier = ValueNotifier<Duration?>(Duration.zero);
final buttonNotifier = ValueNotifier<MPlayerState>(MPlayerState.stopped);
final shuffleNotifier = ValueNotifier<bool>(false);
final repeatNotifier = ValueNotifier<bool>(false);
final prefferedFileExtension = ValueNotifier<String>('mp3');
final playNextSongAutomatically = ValueNotifier<bool>(false);

bool get hasNext => audioPlayer!.hasNext;

bool get hasPrevious => audioPlayer!.hasPrevious;

String get durationText =>
    duration != null ? duration.toString().split('.').first : '';

String get positionText =>
    position != null ? position.toString().split('.').first : '';

bool isMuted = false;

Future<void> downloadSong(dynamic song) async {
  if (await Permission.storage.request().isGranted) {
    final filename = song['title']
            .replaceAll(r'\', '')
            .replaceAll('/', '')
            .replaceAll('*', '')
            .replaceAll('?', '')
            .replaceAll('"', '')
            .replaceAll('<', '')
            .replaceAll('>', '')
            .replaceAll('|', '') +
        '.' +
        prefferedFileExtension.value;

    String filepath = '';
    final String? dlPath =
        await ExtStorageProvider.getExtStorage(dirName: 'Musify');
    try {
      await File('${dlPath!}/$filename')
          .create(recursive: true)
          .then((value) => filepath = value.path);
    } catch (e) {
      await [Permission.manageExternalStorage].request();
      await File('${dlPath!}/$filename')
          .create(recursive: true)
          .then((value) => filepath = value.path);
    }
    Fluttertoast.showToast(
      msg: 'Download Started!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: accent,
      textColor: Colors.white,
      fontSize: 14.0,
    );
    final audioStream = await getSongStream(song['ytid'].toString());
    final File file = File(filepath);
    final fileStream = file.openWrite();
    await yt.videos.streamsClient
        .get(audioStream as StreamInfo)
        .pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    debugPrint('Done');
    Fluttertoast.showToast(
      msg: 'Download Completed!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: accent,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}

Future<void> playSong(Map song) async {
  if (song['ytid'].length == 0) {
    await MyAudioHandler()
        .addQueueItem(mapToMediaItem(song, song['songUrl'].toString()));
  } else {
    final songUrl = await getSongUrl(song['ytid']);
    await MyAudioHandler().addQueueItem(mapToMediaItem(song, songUrl));
  }
  await play();
}

Future changeShuffleStatus() async {
  if (shuffleNotifier.value == true) {
    await audioPlayer?.setShuffleModeEnabled(false);
  } else {
    await audioPlayer?.setShuffleModeEnabled(true);
  }
}

void changeAutoPlayNextStatus() {
  if (playNextSongAutomatically.value == false) {
    playNextSongAutomatically.value = true;
  } else {
    playNextSongAutomatically.value = false;
  }
}

Future changeLoopStatus() async {
  if (repeatNotifier.value == false) {
    repeatNotifier.value = true;
    await audioPlayer?.setLoopMode(LoopMode.one);
  } else {
    repeatNotifier.value = false;
    await audioPlayer?.setLoopMode(LoopMode.off);
  }
}

Future enableBooster() async {
  _loudnessEnhancer.setEnabled(true);
  _loudnessEnhancer.setTargetGain(1);
}

Future<void>? play() => _audioHandler.play();

Future<void>? pause() => _audioHandler.pause();

Future<void>? stop() => _audioHandler.stop();

Future playNext() async {
  _audioHandler.skipToNext();
}

Future playPrevious() async {
  _audioHandler.skipToPrevious();
}

Future mute(bool muted) async {
  if (muted) {
    audioPlayer?.setVolume(0);
  } else {
    audioPlayer?.setVolume(1);
  }
}
