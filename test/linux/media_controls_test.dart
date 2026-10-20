import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/linux_media_controls.dart';

class _NavigationChanges extends ChangeNotifier {
  bool get observed => hasListeners;
}

class _Handler extends BaseAudioHandler {
  final commands = <String>[];
  Duration? sought;
  @override
  Future<void> play() async => commands.add('play');
  @override
  Future<void> pause() async => commands.add('pause');
  @override
  Future<void> stop() async => commands.add('stop');
  @override
  Future<void> skipToNext() async => commands.add('next');
  @override
  Future<void> skipToPrevious() async => commands.add('previous');
  @override
  Future<void> seek(Duration position) async {
    sought = position;
  }
}

void main() {
  late Directory directory;
  late DBusServer server;
  late DBusClient observer;
  late LinuxMediaControls controls;
  late DBusRemoteObject remote;
  late _Handler handler;
  late StreamController<double> volumes;
  late List<Object> errors;
  late Future<Uri?> Function(Uri) resolveArtwork;
  var currentVolume = 0.5;
  var canNext = true;
  var canPrevious = true;
  late _NavigationChanges navigationChanges;
  var raised = 0;
  const player = LinuxMediaControls.playerInterface;
  const root = LinuxMediaControls.rootInterface;

  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 30));
  Future<DBusValue> property(String name) => remote.getProperty(player, name);
  Future<void> command(String name, [List<DBusValue> values = const []]) async {
    await remote.callMethod(
      player,
      name,
      values,
      replySignature: DBusSignature(''),
    );
  }

  group('Linux media controls', () {
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('musify_mpris');
      server = DBusServer();
      final address = await server.listenAddress(
        DBusAddress.unix(dir: directory),
      );
      observer = DBusClient(address);
      handler = _Handler();
      errors = [];
      resolveArtwork = (source) async => source;
      volumes = StreamController<double>.broadcast();
      currentVolume = 0.5;
      canNext = true;
      canPrevious = true;
      navigationChanges = _NavigationChanges();
      raised = 0;
      controls = LinuxMediaControls(
        handler: handler,
        skipToNext: handler.skipToNext,
        skipToPrevious: handler.skipToPrevious,
        resolveArtwork: (source) => resolveArtwork(source),
        position: () => handler.sought ?? const Duration(seconds: 10),
        bus: DBusClient(address),
        name: 'org.mpris.MediaPlayer2.musify.test',
        volume: () => currentVolume,
        volumeStream: volumes.stream,
        setVolume: (value) async {
          currentVolume = value;
          volumes.add(value);
        },
        canGoNext: () => canNext,
        canGoPrevious: () => canPrevious,
        navigationChanges: navigationChanges,
        raise: () async {
          raised++;
        },
        onError: (error, _) => errors.add(error),
      );
      await controls.start();
      remote = DBusRemoteObject(
        observer,
        name: controls.name,
        path: controls.path,
      );
      handler.mediaItem.add(
        MediaItem(
          id: 'ytid / track',
          title: 'Song',
          artist: 'Artist',
          duration: const Duration(seconds: 120),
          artUri: Uri.parse('https://example.com/cover.jpg'),
        ),
      );
      handler.playbackState.add(
        PlaybackState(
          processingState: AudioProcessingState.ready,
          playing: true,
          updatePosition: const Duration(seconds: 10),
        ),
      );
      await flush();
    });

    tearDown(() async {
      await controls.dispose();
      expect(navigationChanges.observed, false);
      navigationChanges.dispose();
      await observer.close();
      await volumes.close();
      await server.close();
      await directory.delete(recursive: true);
      expect(errors, isEmpty);
    });

    test(
      'exports Musify identity, artwork, valid track ID and playback state',
      () async {
        expect(
          (await remote.getProperty(root, 'DesktopEntry')).asString(),
          'musify',
        );
        expect(
          (await remote.getProperty(root, 'Identity')).asString(),
          'Musify',
        );
        expect((await property('PlaybackStatus')).asString(), 'Playing');
        final metadata = (await property('Metadata')).asStringVariantDict();
        expect(metadata['xesam:title'], const DBusString('Song'));
        expect(
          metadata['mpris:artUrl'],
          const DBusString('https://example.com/cover.jpg'),
        );
        expect(metadata['mpris:length'], const DBusInt64(120000000));
        expect(metadata['mpris:trackid'], isA<DBusObjectPath>());
        final node = await remote.introspect();
        expect(
          node.interfaces.map((interface) => interface.name),
          containsAll([root, player]),
        );
      },
    );

    test('desktop media commands reach the same audio handler', () async {
      for (final method in ['Pause', 'PlayPause', 'Next', 'Previous', 'Stop']) {
        await command(method);
      }
      expect(handler.commands, ['pause', 'pause', 'next', 'previous', 'stop']);
      await remote.callMethod(
        root,
        'Raise',
        [],
        replySignature: DBusSignature(''),
      );
      expect(raised, 1);
      canNext = false;
      await command('Next');
      expect(handler.commands.where((value) => value == 'next'), hasLength(1));
    });

    test('queue edits refresh navigation while paused', () async {
      handler.playbackState.add(
        handler.playbackState.value.copyWith(playing: false),
      );
      await flush();
      final signal = remote.propertiesChanged.firstWhere(
        (signal) =>
            signal.changedProperties['CanGoNext'] == const DBusBoolean(false),
      );
      await flush();
      canNext = false;
      canPrevious = false;
      handler.queue.add([]);
      await signal.timeout(const Duration(seconds: 2));
      expect((await property('PlaybackStatus')).asString(), 'Paused');
      expect((await property('CanGoNext')).asBoolean(), false);
      expect((await property('CanGoPrevious')).asBoolean(), false);
      await command('Next');
      await command('Previous');
      expect(handler.commands, isEmpty);
      canNext = true;
      handler.queue.add([const MediaItem(id: 'added', title: 'Added')]);
      await flush();
      expect((await property('CanGoNext')).asBoolean(), true);
      expect((await property('CanGoPrevious')).asBoolean(), false);
      await command('Next');
      expect(handler.commands, ['next']);
    });

    test(
      'settings emit navigation changes without playback progress',
      () async {
        handler.playbackState.add(
          handler.playbackState.value.copyWith(playing: false),
        );
        await flush();
        final signal = remote.propertiesChanged.firstWhere(
          (signal) => signal.changedProperties.containsKey('CanGoNext'),
        );
        await flush();
        canNext = false;
        navigationChanges.notifyListeners();
        expect(
          (await signal.timeout(const Duration(seconds: 2)))
              .changedProperties['CanGoNext'],
          const DBusBoolean(false),
        );
        canNext = true;
        navigationChanges.notifyListeners();
        await flush();
        expect((await property('CanGoNext')).asBoolean(), true);
      },
    );

    test('stale system clicks use the current navigation state', () async {
      canNext = false;
      canPrevious = false;
      await command('Next');
      await command('Previous');
      expect(handler.commands, isEmpty);
    });

    test(
      'seeking rejects stale track IDs and invalid absolute positions',
      () async {
        final metadata = (await property('Metadata')).asStringVariantDict();
        final track = metadata['mpris:trackid']!;
        await command('SetPosition', [
          DBusObjectPath('/stale'),
          const DBusInt64(20000000),
        ]);
        expect(handler.sought, isNull);
        await command('SetPosition', [track, const DBusInt64(-1)]);
        expect(handler.sought, isNull);
        await command('SetPosition', [track, const DBusInt64(121000000)]);
        expect(handler.sought, isNull);
        await command('SetPosition', [track, const DBusInt64(20000000)]);
        expect(handler.sought, const Duration(seconds: 20));
        await command('Seek', [const DBusInt64(-20000000)]);
        expect(handler.sought, Duration.zero);
        await command('Seek', [const DBusInt64(200000000)]);
        expect(handler.commands.last, 'next');
      },
    );

    test(
      'Seeked reports the new player position before UI state catches up',
      () async {
        final seeked = DBusSignalStream(
          observer,
          sender: controls.name,
          path: controls.path,
          interface: player,
          name: 'Seeked',
        ).first;
        await flush();
        final metadata = (await property('Metadata')).asStringVariantDict();
        await command('SetPosition', [
          metadata['mpris:trackid']!,
          const DBusInt64(20000000),
        ]);
        expect((await seeked.timeout(const Duration(seconds: 2))).values, [
          const DBusInt64(20000000),
        ]);
        expect((await property('Position')).asInt64(), 20000000);
      },
    );

    test('volume is bidirectional and completion reports stopped', () async {
      await remote.setProperty(player, 'Volume', const DBusDouble(2));
      expect(currentVolume, 1);
      currentVolume = 0.25;
      volumes.add(currentVolume);
      expect((await property('Volume')).asDouble(), 0.25);
      handler.playbackState.add(
        PlaybackState(
          processingState: AudioProcessingState.completed,
          playing: true,
        ),
      );
      await flush();
      expect((await property('PlaybackStatus')).asString(), 'Stopped');
      expect((await property('CanSeek')).asBoolean(), false);
      expect((await property('CanGoNext')).asBoolean(), false);
      expect((await property('CanGoPrevious')).asBoolean(), false);
      await command('Next');
      await command('Previous');
      expect(handler.commands, isEmpty);
    });

    test('emits metadata changes and releases its bus name on exit', () async {
      final released = observer.nameOwnerChanged
          .firstWhere(
            (event) => event.name == controls.name && event.newOwner == null,
          )
          .timeout(const Duration(seconds: 2));
      final signal = remote.propertiesChanged.firstWhere(
        (signal) => signal.changedProperties.containsKey('Metadata'),
      );
      // Complete a round trip after installing the signal matches.
      expect(await observer.nameHasOwner(controls.name), true);
      handler.mediaItem.add(const MediaItem(id: 'next', title: 'Next song'));
      expect(
        (await signal.timeout(const Duration(seconds: 2))).changedProperties,
        contains('Metadata'),
      );
      await controls.dispose();
      await released;
      expect(await observer.nameHasOwner(controls.name), false);
    });
    test(
      'Linux publishes the square cover without blocking media commands',
      () async {
        final cover = Completer<Uri?>();
        resolveArtwork = (_) => cover.future;
        handler.mediaItem.add(
          MediaItem(
            id: 'new',
            title: 'New song',
            artUri: Uri.parse('https://example.com/wide.jpg'),
          ),
        );
        await flush();
        var metadata = (await property('Metadata')).asStringVariantDict();
        expect(metadata['xesam:title'], const DBusString('New song'));
        expect(metadata.containsKey('mpris:artUrl'), false);
        await command('Pause');
        expect(handler.commands.last, 'pause');
        final square = Uri.file('${directory.path}/square.png');
        cover.complete(square);
        await flush();
        metadata = (await property('Metadata')).asStringVariantDict();
        expect(metadata['mpris:artUrl'], DBusString(square.toString()));
      },
    );
  }, skip: !Platform.isLinux);
}
