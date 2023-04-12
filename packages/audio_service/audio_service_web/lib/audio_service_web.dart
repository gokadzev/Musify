import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util';

import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'js/media_session_web.dart';

class AudioServiceWeb extends AudioServicePlatform {
  static void registerWith(Registrar registrar) {
    AudioServicePlatform.instance = AudioServiceWeb();
  }

  final _mediaSessionSupported = _SupportChecker(
    () => js.context.hasProperty('MediaSession'),
    "MediaSession is not supported in this browser, so plugin is no-op",
  );
  final _setPositionStateSupported = _SupportChecker(
    () => hasProperty(html.window.navigator.mediaSession!, 'setPositionState'),
    "MediaSession.setPositionState is not supported in this browser",
  );

  AudioHandlerCallbacks? handlerCallbacks;
  MediaItemMessage? mediaItem;

  @override
  Future<void> configure(ConfigureRequest request) async {
    _mediaSessionSupported.check();
  }

  @override
  Future<void> setState(SetStateRequest request) async {
    if (!_mediaSessionSupported.check()) {
      return;
    }

    final state = request.state;

    if (state.processingState == AudioProcessingStateMessage.idle) {
      MediaSession.playbackState = MediaSessionPlaybackState.none;
    } else {
      if (state.playing) {
        MediaSession.playbackState = MediaSessionPlaybackState.playing;
      } else {
        MediaSession.playbackState = MediaSessionPlaybackState.paused;
      }
    }

    for (final control in state.controls) {
      switch (control.action) {
        case MediaActionMessage.play:
          MediaSession.setActionHandler(
            MediaSessionActions.play,
            (details) => handlerCallbacks?.play(const PlayRequest()),
          );
          break;
        case MediaActionMessage.pause:
          MediaSession.setActionHandler(
            MediaSessionActions.pause,
            (details) => handlerCallbacks?.pause(const PauseRequest()),
          );
          break;
        case MediaActionMessage.skipToPrevious:
          MediaSession.setActionHandler(
            MediaSessionActions.previoustrack,
            (details) =>
                handlerCallbacks?.skipToPrevious(const SkipToPreviousRequest()),
          );
          break;
        case MediaActionMessage.skipToNext:
          MediaSession.setActionHandler(
            MediaSessionActions.nexttrack,
            (details) =>
                handlerCallbacks?.skipToNext(const SkipToNextRequest()),
          );
          break;
        case MediaActionMessage.rewind:
          MediaSession.setActionHandler(
            MediaSessionActions.seekbackward,
            (details) => handlerCallbacks?.rewind(const RewindRequest()),
          );
          break;
        case MediaActionMessage.fastForward:
          MediaSession.setActionHandler(
            MediaSessionActions.seekforward,
            (details) =>
                handlerCallbacks?.fastForward(const FastForwardRequest()),
          );
          break;
        case MediaActionMessage.stop:
          MediaSession.setActionHandler(
            MediaSessionActions.stop,
            (details) => handlerCallbacks?.stop(const StopRequest()),
          );
          break;
        default:
          // no-op
          break;
      }
    }

    for (final message in state.systemActions) {
      switch (message) {
        case MediaActionMessage.seek:
          MediaSession.setActionHandler('seekto',
              (MediaSessionActionDetails details) {
            // Browsers use seconds
            handlerCallbacks?.seek(SeekRequest(
              position:
                  Duration(milliseconds: (details.seekTime * 1000).round()),
            ));
          });
          break;
        default:
          // no-op
          break;
      }
    }

    if (_setPositionStateSupported.check()) {
      // Update the position
      //
      // Factor out invalid states according to
      // https://developer.mozilla.org/en-US/docs/Web/API/MediaSession/setPositionState#exceptions
      final duration = mediaItem?.duration ?? Duration.zero;
      final position = _minDuration(state.updatePosition, duration);

      // Browsers expect for seconds
      MediaSession.setPositionState(MediaSessionPositionState(
        duration: duration.inMilliseconds / 1000,
        playbackRate: state.speed,
        position: position.inMilliseconds / 1000,
      ));
    }
  }

  @override
  Future<void> setQueue(SetQueueRequest request) async {
    // no-op as there is not a queue concept on the web
  }

  @override
  Future<void> setMediaItem(SetMediaItemRequest request) async {
    if (!_mediaSessionSupported.check()) {
      return;
    }
    mediaItem = request.mediaItem;
    final artist = mediaItem!.artist;
    final album = mediaItem!.album;
    final artUri = mediaItem!.artUri;

    MediaSession.metadata = html.MediaMetadata(<String, dynamic>{
      'title': mediaItem!.title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      'artwork': [
        {
          'src': artUri,
          'sizes': '512x512',
        }
      ],
    });
  }

  @override
  Future<void> stopService(StopServiceRequest request) async {
    if (!_mediaSessionSupported.check()) {
      return;
    }
    final session = html.window.navigator.mediaSession!;
    session.metadata = null;
    mediaItem = null;
  }

  @override
  void setHandlerCallbacks(AudioHandlerCallbacks callbacks) {
    if (!_mediaSessionSupported.check()) {
      return;
    }
    // Save this here so that we can modify which handlers are set based
    // on which actions are enabled
    handlerCallbacks = callbacks;
  }
}

/// Runs a [check], and prints a warning the first time check doesn't pass.
class _SupportChecker {
  final String _warningMessage;
  final ValueGetter<bool> _checkCallback;

  _SupportChecker(this._checkCallback, this._warningMessage);

  bool _logged = false;
  bool check() {
    final result = _checkCallback();
    if (!_logged && !result) {
      _logged = true;
      // ignore: avoid_print
      print("[warning] audio_service: $_warningMessage");
    }
    return result;
  }
}

Duration _minDuration(Duration a, Duration b) => a < b ? a : b;
