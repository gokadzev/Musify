import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:musify/services/desktop_media_artwork.dart';

/// Exposes the audio handler through the Windows runner's SMTC session.
class WindowsMediaControls {
  WindowsMediaControls({
    required this.onError,
    required this.canGoNext,
    required this.canGoPrevious,
    this.navigationChanges,
    this.resolveArtwork,
    this.channel = const MethodChannel('musify/media_controls'),
  });

  final void Function(Object error, StackTrace stackTrace) onError;
  final MethodChannel channel;
  final bool Function() canGoNext;
  final bool Function() canGoPrevious;
  final Listenable? navigationChanges;
  final MediaArtworkResolver? resolveArtwork;
  late final _artwork = MediaArtworkState(
    resolve: resolveArtwork,
    onChanged: _scheduleUpdate,
    onError: onError,
  );
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  AudioHandler? _handler;
  MediaItem? _item;
  PlaybackState _state = PlaybackState();
  Map<String, Object?>? _lastUpdate;
  Future<void> _pending = Future.value();
  bool _disposed = false;

  Future<void> start(AudioHandler handler) async {
    _handler = handler;
    channel.setMethodCallHandler(_onMethodCall);
    try {
      await channel.invokeMethod<void>('initialize');
    } catch (_) {
      channel.setMethodCallHandler(null);
      rethrow;
    }
    navigationChanges?.addListener(_scheduleUpdate);
    _subscriptions.addAll([
      handler.queue.listen((_) => _scheduleUpdate()),
      handler.mediaItem.listen((item) {
        _item = item;
        _artwork.update(item?.artUri);
        _scheduleUpdate();
      }),
      handler.playbackState.listen((state) {
        _state = state;
        _scheduleUpdate();
      }),
    ]);
  }

  bool get _active =>
      _item != null &&
      _state.processingState != AudioProcessingState.idle &&
      _state.processingState != AudioProcessingState.completed &&
      _state.processingState != AudioProcessingState.error;

  void _scheduleUpdate() {
    // Serialize calls using the latest track and playback state.
    _pending = _pending
        .then((_) async {
          if (_disposed) return;
          final artUri = _artwork.uri;
          final update = <String, Object?>{
            'enabled': _active,
            'canGoNext': _active && canGoNext(),
            'canGoPrevious': _active && canGoPrevious(),
            'status': !_active
                ? 'stopped'
                : _state.playing
                ? 'playing'
                : 'paused',
            'title': _item?.title ?? '',
            'artist': _item?.artist ?? '',
            'album': _item?.album ?? '',
            'artUri': artUri?.scheme == 'http' || artUri?.scheme == 'https'
                ? artUri.toString()
                : '',
            'artPath': artUri?.scheme == 'file'
                ? artUri!.toFilePath(windows: true)
                : '',
          };
          // Playback progress ticks do not need to refresh the Windows media card.
          if (mapEquals(update, _lastUpdate)) return;
          await channel.invokeMethod<void>('update', update);
          _lastUpdate = update;
        })
        .catchError(onError);
  }

  Future<void> _onMethodCall(MethodCall call) async {
    if (_disposed || !_active || call.method != 'button') return;
    try {
      switch (call.arguments) {
        case 'play':
          await _handler!.play();
        case 'pause':
          await _handler!.pause();
        case 'next':
          if (canGoNext()) await _handler!.skipToNext();
        case 'previous':
          if (canGoPrevious()) await _handler!.skipToPrevious();
        case 'stop':
          await _handler!.stop();
      }
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    navigationChanges?.removeListener(_scheduleUpdate);
    _artwork.dispose();
    channel.setMethodCallHandler(null);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _pending;
    try {
      await channel.invokeMethod<void>('dispose');
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }
}
