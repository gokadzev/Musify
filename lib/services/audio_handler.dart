import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Future<AudioHandler> initAudioHandler() async {
  return AudioService.init(
    builder: SimpleAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.musify.channel.audio',
      androidNotificationChannelName: 'Musify Audio Playback',
      androidNotificationOngoing: true,
    ),
  );
}

class SimpleAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  SimpleAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }
  final _player = AudioPlayer();

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.pause,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    await _player.setAudioSource(AudioSource.uri(Uri.parse(mediaItem.id)));
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();
}
