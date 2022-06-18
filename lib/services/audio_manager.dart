import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musify/API/musify.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:musify/services/ext_storage.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/player.dart';
import 'package:permission_handler/permission_handler.dart';

final _equalizer = AndroidEqualizer();
final _loudnessEnhancer = AndroidLoudnessEnhancer();

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

void listenForChangesInSequenceState() {
  audioPlayer?.sequenceStateStream.listen((sequenceState) {
    if (sequenceState == null) return;
    shuffleNotifier.value = sequenceState.shuffleModeEnabled;
  });
}

Future<void> playSong(song, [isFromPlaylist]) async {
  if (isFromPlaylist == null && activePlaylist.isNotEmpty) {
    activePlaylist = [];
    id = 0;
  }
  await setSongDetails(song);
  await play();
}

Future changeShuffleStatus() async {
  if (shuffleNotifier.value == true) {
    await audioPlayer?.setShuffleModeEnabled(false);
  } else {
    await audioPlayer?.setShuffleModeEnabled(true);
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

Future<void>? play() => audioPlayer?.play();

Future<void>? pause() => audioPlayer?.pause();

Future<void>? stop() => audioPlayer?.stop();

Future playNext() async {
  if (id! + 1 <= activePlaylist.length) {
    id = id! + 1;
    await playSong(activePlaylist[id!], true);
  }
}

Future playPrevious() async {
  if (id! - 1 >= 0) {
    id = id! - 1;
    await playSong(activePlaylist[id!], true);
  }
}

Future mute(bool muted) async {
  if (muted) {
    audioPlayer?.setVolume(0);
  } else {
    audioPlayer?.setVolume(1);
  }
}

Future<AudioHandler> initAudioService() async {
  return AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'me.musify',
      androidNotificationChannelName: 'Musify',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/musify',
      androidShowNotificationBadge: true,
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
      playing: false,
      processingState: AudioProcessingState.completed,
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
  Future<void> skipToPrevious() async {
    if (activePlaylist.isNotEmpty && id! - 1 >= 0) {
      playPrevious();
    }
  }

  @override
  Future<void> skipToNext() async {
    if (activePlaylist.isNotEmpty && id! + 1 <= activePlaylist.length) {
      playNext();
    }
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
          duration: duration));
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
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
