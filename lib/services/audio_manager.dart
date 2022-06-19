import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musify/API/musify.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/helper/mediaitem.dart';
import 'package:musify/main.dart';
import 'package:musify/services/audio_handler.dart';
import 'package:musify/services/ext_storage.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/player.dart';
import 'package:permission_handler/permission_handler.dart';

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
final kUrlNotifier = ValueNotifier<String>('');
final shuffleNotifier = ValueNotifier<bool>(false);
final repeatNotifier = ValueNotifier<bool>(false);

bool get hasNext => audioPlayer!.hasNext;

bool get hasPrevious => audioPlayer!.hasPrevious;

get durationText =>
    duration != null ? duration.toString().split('.').first : '';

get positionText =>
    position != null ? position.toString().split('.').first : '';

bool isMuted = false;

downloadSong(song) async {
  var status = await Permission.storage.status;
  if (status.isDenied) {
    final Map<Permission, PermissionStatus> statuses =
        await [Permission.storage].request();
    debugPrint(statuses[Permission.storage].toString());
  }
  status = await Permission.storage.status;
  if (status.isGranted) {
    Fluttertoast.showToast(
        msg: "Download Started!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: accent,
        textColor: Colors.white,
        fontSize: 14.0);

    final filename = song["title"]
            .replaceAll(r'\', '')
            .replaceAll('/', '')
            .replaceAll('*', '')
            .replaceAll('?', '')
            .replaceAll('"', '')
            .replaceAll('<', '')
            .replaceAll('>', '')
            .replaceAll('|', '') +
        ".mp3";

    String filepath = '';
    final String? dlPath =
        await ExtStorageProvider.getExtStorage(dirName: 'Music');
    try {
      await File(dlPath! + "/" + filename)
          .create(recursive: true)
          .then((value) => filepath = value.path);
    } catch (e) {
      await [
        Permission.manageExternalStorage,
      ].request();
      await File(dlPath! + "/" + filename)
          .create(recursive: true)
          .then((value) => filepath = value.path);
    }
    final audioStream = await getSongStream(song["ytid"].toString());
    final File file = File(filepath);
    final fileStream = file.openWrite();
    await yt.videos.streamsClient.get(audioStream).pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    debugPrint("Done");
    Fluttertoast.showToast(
        msg: "Download Completed!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: accent,
        textColor: Colors.white,
        fontSize: 14.0);
  } else if (status.isDenied || status.isPermanentlyDenied) {
    Fluttertoast.showToast(
        msg: "Storage Permission Denied!\nCan't Download Songs",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: accent,
        textColor: Colors.white,
        fontSize: 14.0);
  } else {
    Fluttertoast.showToast(
        msg: "Permission Error!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.values[50],
        timeInSecForIosWeb: 1,
        backgroundColor: accent,
        textColor: Colors.white,
        fontSize: 14.0);
  }
}

Future<void> playSong(song, [isFromPlaylist]) async {
  final songUrl = await getSongUrl(song["ytid"]);
  await MyAudioHandler().addQueueItem(mapToMediaItem(song, songUrl));
  await play();
}

Future changeShuffleStatus() async {
  if (shuffleNotifier.value == true) {
    MyAudioHandler().setShuffleMode(AudioServiceShuffleMode.none);
  } else {
    MyAudioHandler().setShuffleMode(AudioServiceShuffleMode.all);
  }
}

Future changeLoopStatus() async {
  if (repeatNotifier.value == false) {
    repeatNotifier.value = true;
    MyAudioHandler().setRepeatMode(AudioServiceRepeatMode.one);
  } else {
    repeatNotifier.value = false;
    MyAudioHandler().setRepeatMode(AudioServiceRepeatMode.none);
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
