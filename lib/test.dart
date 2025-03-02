import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // Use audioplayers if needed
import 'package:phone_state/phone_state.dart';

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool wasPlayingBeforeCall = false; // Store previous state

  @override
  void initState() {
    super.initState();
    _initPhoneCallListener();
  }

  void _initPhoneCallListener() {
    PhoneState.stream.listen((PhoneStateStatus status) {
      if (status == PhoneStateStatus.CALL_STARTED) {
        // Store playback state and pause
        if (_audioPlayer.playing) {
          wasPlayingBeforeCall = true;
          _audioPlayer.pause();
        } else {
          wasPlayingBeforeCall = false;
        }
      } else if (status == PhoneStateStatus.CALL_ENDED) {
        // Restore playback state
        if (wasPlayingBeforeCall) {
          _audioPlayer.play();
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music Player")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _audioPlayer.play(),
              child: Text("Play"),
            ),
            ElevatedButton(
              onPressed: () => _audioPlayer.pause(),
              child: Text("Pause"),
            ),
          ],
        ),
      ),
    );
  }
}
