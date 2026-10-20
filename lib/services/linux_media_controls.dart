import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:musify/services/desktop_media_artwork.dart';

/// Exposes the existing audio handler to Linux desktops and media keys.
class LinuxMediaControls extends DBusObject {
  LinuxMediaControls({
    required this.handler,
    required this.skipToNext,
    required this.skipToPrevious,
    required this.volume,
    required this.volumeStream,
    required this.setVolume,
    required this.canGoNext,
    required this.canGoPrevious,
    required this.onError,
    this.raise,
    this.position,
    this.resolveArtwork,
    this.navigationChanges,
    DBusClient? bus,
    String? name,
  }) : _bus = bus ?? DBusClient.session(),
       name = name ?? 'org.mpris.MediaPlayer2.musify.instance$pid',
       super(DBusObjectPath('/org/mpris/MediaPlayer2'));

  static const rootInterface = 'org.mpris.MediaPlayer2';
  static const playerInterface = '$rootInterface.Player';
  final AudioHandler handler;
  final Future<void> Function() skipToNext;
  final Future<void> Function() skipToPrevious;
  final double Function() volume;
  final Stream<double> volumeStream;
  final Future<void> Function(double) setVolume;
  final bool Function() canGoNext;
  final bool Function() canGoPrevious;
  final Listenable? navigationChanges;
  final void Function(Object, StackTrace) onError;
  final Future<void> Function()? raise;
  final Duration Function()? position;
  final MediaArtworkResolver? resolveArtwork;
  late final _artwork = MediaArtworkState(
    resolve: resolveArtwork,
    onChanged: _update,
    onError: onError,
  );
  final DBusClient _bus;
  final String name;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Map<String, DBusValue> _lastProperties = {};
  PlaybackState _state = PlaybackState();
  MediaItem? _item;
  bool _disposed = false;
  Future<void> _pending = Future.value();

  Future<void> start() async {
    try {
      await _bus.registerObject(this);
      final reply = await _bus.requestName(
        name,
        flags: {DBusRequestNameFlag.doNotQueue},
      );
      if (reply != DBusRequestNameReply.primaryOwner) {
        throw StateError('MPRIS name unavailable: $name');
      }
      navigationChanges?.addListener(_update);
      _subscriptions.addAll([
        handler.queue.listen((_) => _update()),
        handler.mediaItem.listen((item) {
          _item = item;
          _artwork.update(item?.artUri);
          _update();
        }),
        handler.playbackState.listen((state) {
          final jumped =
              _item != null &&
              state.processingState == AudioProcessingState.ready &&
              _state.processingState == AudioProcessingState.ready &&
              (state.position - _state.position).abs() >
                  const Duration(seconds: 1);
          _state = state;
          _update();
          if (jumped) _signalSeeked();
        }),
        volumeStream.listen((_) => _update()),
      ]);
    } catch (_) {
      await dispose();
      rethrow;
    }
  }

  bool get _active =>
      _item != null &&
      _state.processingState != AudioProcessingState.idle &&
      _state.processingState != AudioProcessingState.completed &&
      _state.processingState != AudioProcessingState.error;

  bool get _canSeek =>
      _active && (_item?.duration ?? Duration.zero) > Duration.zero;

  DBusObjectPath get _trackId => DBusObjectPath(
    _item == null
        ? '/org/mpris/MediaPlayer2/TrackList/NoTrack'
        : '/org/mpris/MediaPlayer2/track/t${utf8.encode(_item!.id).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
  );

  int get _position => (position?.call() ?? _state.position).inMicroseconds
      .clamp(0, _item?.duration?.inMicroseconds ?? 0x7fffffffffffffff);

  Map<String, DBusValue> get _rootProperties => {
    'CanQuit': const DBusBoolean(false),
    'CanRaise': DBusBoolean(raise != null),
    'HasTrackList': const DBusBoolean(false),
    'Identity': const DBusString('Musify'),
    'DesktopEntry': const DBusString('musify'),
    'SupportedUriSchemes': DBusArray.string([]),
    'SupportedMimeTypes': DBusArray.string([]),
  };

  Map<String, DBusValue> get _playerProperties => {
    'PlaybackStatus': DBusString(
      !_active
          ? 'Stopped'
          : _state.playing
          ? 'Playing'
          : 'Paused',
    ),
    'Rate': DBusDouble(_state.speed),
    'MinimumRate': const DBusDouble(0.25),
    'MaximumRate': const DBusDouble(3),
    'Volume': DBusDouble(volume()),
    'Position': DBusInt64(_position),
    'CanControl': const DBusBoolean(true),
    'CanPlay': DBusBoolean(_item != null),
    'CanPause': DBusBoolean(_active),
    'CanSeek': DBusBoolean(_canSeek),
    'CanGoNext': DBusBoolean(_active && canGoNext()),
    'CanGoPrevious': DBusBoolean(_active && canGoPrevious()),
    'Metadata': DBusDict.stringVariant({
      'mpris:trackid': _trackId,
      if (_item case final item?) ...{
        'xesam:title': DBusString(item.title),
        'xesam:artist': DBusArray.string([item.artist ?? '']),
        'xesam:album': DBusString(item.album ?? ''),
        if (_artwork.uri != null)
          'mpris:artUrl': DBusString(_artwork.uri.toString()),
        if (item.duration != null)
          'mpris:length': DBusInt64(item.duration!.inMicroseconds),
      },
    }),
  };

  void _update() {
    _pending = _pending
        .then((_) async {
          if (_disposed) return;
          final properties = _playerProperties..remove('Position');
          final changed = Map<String, DBusValue>.fromEntries(
            properties.entries.where(
              (entry) => _lastProperties[entry.key] != entry.value,
            ),
          );
          if (changed.isEmpty) return;
          await emitPropertiesChanged(
            playerInterface,
            changedProperties: changed,
          );
          _lastProperties = properties;
        })
        .catchError(onError);
  }

  void _signalSeeked() {
    _pending = _pending
        .then((_) async {
          if (!_disposed)
            await emitSignal(playerInterface, 'Seeked', [DBusInt64(_position)]);
        })
        .catchError(onError);
  }

  Map<String, DBusValue>? _properties(String interface) => switch (interface) {
    rootInterface => _rootProperties,
    playerInterface => _playerProperties,
    _ => null,
  };

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final properties = _properties(interface);
    if (properties == null) return DBusMethodErrorResponse.unknownInterface();
    final value = properties[name];
    return value == null
        ? DBusMethodErrorResponse.unknownProperty()
        : DBusGetPropertyResponse(value);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    final properties = _properties(interface);
    return properties == null
        ? DBusMethodErrorResponse.unknownInterface()
        : DBusGetAllPropertiesResponse(properties);
  }

  @override
  Future<DBusMethodResponse> setProperty(
    String interface,
    String name,
    DBusValue value,
  ) async {
    if (interface != playerInterface || !{'Volume', 'Rate'}.contains(name)) {
      return _properties(interface)?.containsKey(name) == true
          ? DBusMethodErrorResponse.propertyReadOnly()
          : DBusMethodErrorResponse.unknownProperty();
    }
    if (value is! DBusDouble || !value.value.isFinite)
      return DBusMethodErrorResponse.invalidArgs();
    try {
      if (name == 'Volume') {
        await setVolume(value.value.clamp(0.0, 1.0));
      } else if (value.value == 0) {
        await handler.pause();
      } else if (value.value >= 0.25 && value.value <= 3) {
        await handler.setSpeed(value.value);
      } else {
        return DBusMethodErrorResponse.invalidArgs();
      }
      _update();
      return DBusMethodSuccessResponse();
    } catch (error, stack) {
      onError(error, stack);
      return DBusMethodErrorResponse.failed('Playback command failed');
    }
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    try {
      if (methodCall.interface == rootInterface) {
        if (methodCall.name != 'Raise' && methodCall.name != 'Quit')
          return DBusMethodErrorResponse.unknownMethod();
        if (methodCall.values.isNotEmpty)
          return DBusMethodErrorResponse.invalidArgs();
        if (methodCall.name == 'Raise') await raise?.call();
      } else if (methodCall.interface == playerInterface) {
        switch (methodCall.name) {
          case 'Seek':
            if (methodCall.values case [DBusInt64(value: final offset)]) {
              if (_canSeek) {
                final target = _position + offset;
                if (target > _item!.duration!.inMicroseconds) {
                  if (_active && canGoNext()) await skipToNext();
                } else {
                  await handler.seek(
                    Duration(microseconds: target < 0 ? 0 : target),
                  );
                  _signalSeeked();
                }
              }
            } else {
              return DBusMethodErrorResponse.invalidArgs();
            }
          case 'SetPosition':
            if (methodCall.values case [
              final DBusObjectPath track,
              DBusInt64(value: final position),
            ]) {
              if (_canSeek &&
                  track == _trackId &&
                  position >= 0 &&
                  position <= _item!.duration!.inMicroseconds) {
                await handler.seek(Duration(microseconds: position));
                _signalSeeked();
              }
            } else {
              return DBusMethodErrorResponse.invalidArgs();
            }
          case 'Next' ||
              'Previous' ||
              'Play' ||
              'Pause' ||
              'PlayPause' ||
              'Stop':
            if (methodCall.values.isNotEmpty)
              return DBusMethodErrorResponse.invalidArgs();
            switch (methodCall.name) {
              case 'Next':
                if (_active && canGoNext()) await skipToNext();
              case 'Previous':
                if (_active && canGoPrevious()) await skipToPrevious();
              case 'Play':
                if (_item != null && (!_active || !_state.playing))
                  await handler.play();
              case 'Pause':
                if (_active) await handler.pause();
              case 'PlayPause':
                if (_item != null) {
                  if (_state.playing && _active) {
                    await handler.pause();
                  } else {
                    await handler.play();
                  }
                }
              case 'Stop':
                await handler.stop();
            }
          default:
            return DBusMethodErrorResponse.unknownMethod();
        }
      } else {
        return DBusMethodErrorResponse.unknownInterface();
      }
      return DBusMethodSuccessResponse();
    } catch (error, stack) {
      onError(error, stack);
      return DBusMethodErrorResponse.failed('Playback command failed');
    }
  }

  @override
  List<DBusIntrospectInterface> introspect() => [
    for (final interface in [rootInterface, playerInterface])
      DBusIntrospectInterface(
        interface,
        properties: [
          for (final entry in _properties(interface)!.entries)
            DBusIntrospectProperty(
              entry.key,
              entry.value.signature,
              access:
                  interface == playerInterface &&
                      {'Volume', 'Rate'}.contains(entry.key)
                  ? DBusPropertyAccess.readwrite
                  : DBusPropertyAccess.read,
            ),
        ],
        methods: [
          for (final method
              in interface == rootInterface
                  ? ['Raise', 'Quit']
                  : ['Next', 'Previous', 'Play', 'Pause', 'PlayPause', 'Stop'])
            DBusIntrospectMethod(method),
          if (interface == playerInterface) ...[
            DBusIntrospectMethod(
              'Seek',
              args: [
                DBusIntrospectArgument(
                  DBusSignature('x'),
                  DBusArgumentDirection.in_,
                ),
              ],
            ),
            DBusIntrospectMethod(
              'SetPosition',
              args: [
                DBusIntrospectArgument(
                  DBusSignature('o'),
                  DBusArgumentDirection.in_,
                ),
                DBusIntrospectArgument(
                  DBusSignature('x'),
                  DBusArgumentDirection.in_,
                ),
              ],
            ),
          ],
        ],
        signals: [
          if (interface == playerInterface)
            DBusIntrospectSignal(
              'Seeked',
              args: [
                DBusIntrospectArgument(
                  DBusSignature('x'),
                  DBusArgumentDirection.out,
                ),
              ],
            ),
        ],
      ),
  ];

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    navigationChanges?.removeListener(_update);
    _artwork.dispose();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _pending;
    await _bus.close();
  }
}
