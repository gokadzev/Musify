import 'dart:async';
import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musify/API/musify.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../music.dart';
import 'ext_storage.dart';

ConcatenatingAudioSource? _playlist = ConcatenatingAudioSource(children: []);

AudioPlayer? audioPlayer = AudioPlayer();
AudioHandler? _audioHandler;

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
  String filepath;
  String filepath2;
  var status = await Permission.storage.status;
  if (status.isDenied) {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.storage, Permission.manageExternalStorage].request();
    debugPrint(statuses[Permission.storage].toString());
  }
  status = await Permission.storage.status;
  await setSongDetails(song);
  if (status.isGranted) {
    Fluttertoast.showToast(
        msg: "Download Started!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Color(0xff61e88a),
        fontSize: 14.0);

    final filename = title! + ".mp3";
    final artname = title! + "_artwork.jpg";
    filepath = '';
    filepath2 = '';
    String? dlPath = await ExtStorageProvider.getExtStorage(dirName: 'Music');
    await File(dlPath! + "/" + filename)
        .create(recursive: true)
        .then((value) => filepath = value.path);
    await File(dlPath + "/" + artname)
        .create(recursive: true)
        .then((value) => filepath2 = value.path);
    debugPrint('Audio path $filepath');
    debugPrint('Image path $filepath2');
    var request = await HttpClient().getUrl(Uri.parse(kUrl!));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    File file = File(filepath);

    var request2 = await HttpClient().getUrl(Uri.parse(image!));
    var response2 = await request2.close();
    var bytes2 = await consolidateHttpClientResponseBytes(response2);
    File file2 = File(filepath2);

    await file.writeAsBytes(bytes);
    await file2.writeAsBytes(bytes2);
    debugPrint("Started tag editing");

    final tag = Tag(
      title: title,
      artist: artist,
      artwork: filepath2,
      album: album,
      lyrics: lyrics,
      genre: null,
    );

    debugPrint("Setting up Tags");
    final tagger = Audiotagger();
    await tagger.writeTags(
      path: filepath,
      tag: tag,
    );
    await Future.delayed(const Duration(seconds: 1), () {});

    if (await file2.exists()) {
      await file2.delete();
    }
    debugPrint("Done");
    Fluttertoast.showToast(
        msg: "Download Completed!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Color(0xff61e88a),
        fontSize: 14.0);
  } else if (status.isDenied || status.isPermanentlyDenied) {
    Fluttertoast.showToast(
        msg: "Storage Permission Denied!\nCan't Download Songs",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Color(0xff61e88a),
        fontSize: 14.0);
  } else {
    Fluttertoast.showToast(
        msg: "Permission Error!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.values[50],
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Color(0xff61e88a),
        fontSize: 14.0);
  }
}

void listenForChangesInSequenceState() {
  audioPlayer?.sequenceStateStream.listen((sequenceState) {
    if (sequenceState == null) return;
    shuffleNotifier.value = sequenceState.shuffleModeEnabled;
  });
}

Future<void> playSong(
  song,
) async {
  try {
    await setSongDetails(song);
    await audioPlayer?.setUrl(kUrl!);
    await play();
  } catch (e) {
    artist = "Unknown";
  }
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

Future addToQueue(audioUrl, audio) async {
  // in testing mode
  final song = Uri.parse(audioUrl);
  await _playlist?.add(AudioSource.uri(song, tag: audio));
}

Future play() async {
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
