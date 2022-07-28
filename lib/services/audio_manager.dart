import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
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
final prefferedFileExtension = ValueNotifier<String>(
    Hive.box('settings').get('audioFileType', defaultValue: 'mp3') as String);
final playNextSongAutomatically = ValueNotifier<bool>(false);

bool get hasNext => activePlaylist.isEmpty
    ? audioPlayer!.hasNext
    : id + 1 <= activePlaylist.length;

bool get hasPrevious =>
    activePlaylist.isEmpty ? audioPlayer!.hasPrevious : id - 1 >= 0;

String get durationText =>
    duration != null ? duration.toString().split('.').first : '';

String get positionText =>
    position != null ? position.toString().split('.').first : '';

bool isMuted = false;

Future<void> downloadSong(dynamic song) async {
  PermissionStatus status = await Permission.storage.status;
  if (status.isDenied) {
    await [
      Permission.storage,
      Permission.accessMediaLocation,
      Permission.mediaLibrary,
    ].request();
    status = await Permission.storage.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
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
  await Fluttertoast.showToast(
    msg: 'Download Started!',
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: accent,
    textColor: accent != const Color(0xFFFFFFFF) ? Colors.white : Colors.black,
    fontSize: 14.0,
  );
  final audioStream = await getSongStream(song['ytid'].toString());
  final File file = File(filepath);
  final fileStream = file.openWrite();
  await yt.videos.streamsClient.get(audioStream as StreamInfo).pipe(fileStream);
  await fileStream.flush();
  await fileStream.close();

  debugPrint('Done');
  await Fluttertoast.showToast(
    msg: 'Download Completed!',
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: accent,
    textColor: accent != const Color(0xFFFFFFFF) ? Colors.white : Colors.black,
    fontSize: 14.0,
  );
}

Future<void> playSong(Map song, bool isFromYT) async {
  if (!isFromYT) {
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
  await _loudnessEnhancer.setEnabled(true);
  await _loudnessEnhancer.setTargetGain(1);
}

Future<void>? play() => _audioHandler.play();

Future<void>? pause() => _audioHandler.pause();

Future<void>? stop() => _audioHandler.stop();

Future playNext() async {
  if (activePlaylist.isEmpty) {
    await _audioHandler.skipToNext();
  } else {
    if (id + 1 <= activePlaylist.length) {
      await playSong(activePlaylist[id + 1], true);
      id = id + 1;
    }
  }
}

Future playPrevious() async {
  if (activePlaylist.isEmpty) {
    await _audioHandler.skipToPrevious();
  } else {
    if (id - 1 >= 0) {
      await playSong(activePlaylist[id - 1], true);
      id = id - 1;
    }
  }
}

Future mute(bool muted) async {
  if (muted) {
    await audioPlayer?.setVolume(0);
  } else {
    await audioPlayer?.setVolume(1);
  }
}
