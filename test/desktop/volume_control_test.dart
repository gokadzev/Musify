import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/localization/app_localizations_en.dart';
import 'package:musify/main.dart' show audioHandler;
import 'package:musify/services/audio_service.dart';
import 'package:musify/widgets/desktop_volume_control.dart';
import 'package:musify/widgets/mini_player.dart';
import 'package:musify/widgets/now_playing/bottom_actions_row.dart';

class _Handler extends MusifyAudioHandler {
  final changes = StreamController<double>.broadcast();
  double value = 0.5;
  @override
  double get volume => value;
  @override
  Stream<double> get volumeStream => changes.stream;
  @override
  Stream<List<Map>> get queueAsMapStream => Stream.value([
    {'ytid': 'test'},
  ]);
  @override
  Future<void> setVolume(double next) async {
    value = next;
    changes.add(next);
  }
}

class _LyricsController {
  const _LyricsController();
  void flipcard() {}
}

class _VolumeLocalizations extends AppLocalizationsEn {
  @override
  String get volume => 'Localized volume';
}

class _VolumeDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _VolumeDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(_VolumeLocalizations());
  @override
  bool shouldReload(_VolumeDelegate old) => false;
}

void main() {
  late Directory directory;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('musify_volume_test');
    Hive.init(directory.path);
    for (final name in ['settings', 'user', 'userNoBackup', 'cache']) {
      await Hive.openBox(name);
    }
  });
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    audioHandler = _Handler();
    await audioHandler.setVolume(0.5);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    debugDefaultTargetPlatformOverride = null;
  });
  tearDown(() async {
    unawaited((audioHandler as _Handler).changes.close());
    await audioHandler.audioPlayer.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    debugDefaultTargetPlatformOverride = null;
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> mount(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: [
        const _VolumeDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const Scaffold(body: Center(child: DesktopVolumeControl())),
    ),
  );

  testWidgets(
    'desktop control uses theme colors and publishes volume changes',
    (tester) async {
      await mount(tester);
      final colors = Theme.of(tester.element(find.byType(IconButton)))
          .colorScheme;
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.style!.backgroundColor!.resolve({}), Colors.transparent);
      expect(button.style!.side!.resolve({}), BorderSide.none);
      expect((button.icon as Icon).color, colors.onSurfaceVariant);
      expect(
        button.tooltip,
        AppLocalizations.of(tester.element(find.byType(IconButton)))!.volume,
      );
      final slider = tester.widget<Slider>(find.byType(Slider));
      final theme = SliderTheme.of(tester.element(find.byType(Slider)));
      expect(theme.trackHeight, 4);
      expect(theme.activeTrackColor, colors.onSurfaceVariant);
      expect(theme.inactiveTrackColor, colors.surfaceContainerHighest);
      slider.onChanged!(0.75);
      await tester.pumpAndSettle();
      expect(audioHandler.volume, 0.75);

      await audioHandler.setVolume(0.25);
      await tester.pumpAndSettle();

      expect(tester.widget<Slider>(find.byType(Slider)).value, 0.25);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.linux,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'wheel adjusts current volume and clamps both ends',
    (tester) async {
      await mount(tester);
      final center = tester.getCenter(find.byType(Slider));
      Future<void> scroll(double delta) async {
        await tester.sendEventToBinding(
          PointerScrollEvent(position: center, scrollDelta: Offset(0, delta)),
        );
        await tester.pumpAndSettle();
      }

      await scroll(-20);
      expect(audioHandler.volume, closeTo(0.55, 0.0001));
      await scroll(20);
      expect(audioHandler.volume, closeTo(0.5, 0.0001));
      for (var i = 0; i < 20; i++) {
        await scroll(-1);
      }
      expect(audioHandler.volume, closeTo(0.55, 0.0001));
      await scroll(20);
      expect(audioHandler.volume, closeTo(0.5, 0.0001));
      await audioHandler.setVolume(1);
      await scroll(-20);
      expect(audioHandler.volume, 1);
      await audioHandler.setVolume(0);
      await scroll(20);
      expect(audioHandler.volume, 0);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.linux,
      TargetPlatform.windows,
    }),
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform keeps the desktop control hidden', (tester) async {
      await mount(tester);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(Slider), findsNothing);
    }, variant: TargetPlatformVariant.only(platform));
  }
  testWidgets(
    'mobile action buttons keep their original spacing',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: BottomActionsRow(
                metadata: MediaItem(
                  id: 'radio',
                  title: 'Radio',
                  extras: {'isLive': true, 'ytid': 'radio'},
                ),
                iconSize: 24,
                isLargeScreen: true,
                lyricsController: null,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final buttons = find.byType(IconButton);
      expect(buttons, findsNWidgets(2));
      final panel = tester.getRect(find.byType(BottomActionsRow));
      final first = tester.getRect(buttons.first);
      final last = tester.getRect(buttons.last);
      expect(first.left - panel.left, closeTo(panel.right - last.right, 0.01));
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'full-player volume stays small, adjusts and restores mute at 400 px',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: BottomActionsRow(
                metadata: MediaItem(
                  id: 'test',
                  title: 'Song',
                  extras: {'ytid': 'test'},
                ),
                iconSize: 24,
                isLargeScreen: false,
                lyricsController: _LyricsController(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final volume = find.descendant(
        of: find.byType(DesktopVolumeControl),
        matching: find.byType(IconButton),
      );
      final panel = tester.getRect(find.byType(BottomActionsRow));
      final buttonBounds = tester.getRect(volume);
      final button = tester.widget<IconButton>(volume);
      final colors = Theme.of(tester.element(volume)).colorScheme;
      expect((button.icon as Icon).color, colors.onSurfaceVariant);
      expect(button.style!.backgroundColor!.resolve({}), Colors.transparent);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('50%'), findsNothing);
      final bounds = tester.getRect(find.byType(Slider));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(400));
      expect(bounds.height, 32);
      expect(bounds.width, 96);
      final theme = SliderTheme.of(tester.element(find.byType(Slider)));
      expect(theme.trackHeight, 4);
      expect(theme.activeTrackColor, colors.onSurfaceVariant);
      expect(
        (theme.thumbShape! as RoundSliderThumbShape).enabledThumbRadius,
        4,
      );
      await tester.tap(volume);
      await tester.pumpAndSettle();
      expect(audioHandler.volume, 0);
      expect(find.byType(Slider), findsOneWidget);
      await tester.tap(volume);
      await tester.pumpAndSettle();
      expect(audioHandler.volume, 0.5);
      await audioHandler.setVolume(0.75);
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider)).value, 0.75);
      final center = tester.getCenter(find.byType(Slider));
      await tester.sendEventToBinding(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 20)),
      );
      await tester.pumpAndSettle();
      expect(audioHandler.volume, closeTo(0.7, 0.0001));
      await tester.tap(volume);
      await tester.pumpAndSettle();
      expect(audioHandler.volume, 0);
      await tester.tap(volume);
      await tester.pumpAndSettle();
      expect(audioHandler.volume, closeTo(0.7, 0.0001));
      final thumb = Offset(
        bounds.left + 8 + (bounds.width - 16) * 0.7,
        center.dy,
      );
      await tester.dragFrom(thumb, const Offset(15, 0));
      await tester.pumpAndSettle();
      expect(audioHandler.volume, greaterThan(0.7));
      expect(tester.getRect(find.byType(BottomActionsRow)), panel);
      expect(tester.getRect(volume), buttonBounds);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.linux,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'separate controls share volume and mute restoration',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            _VolumeDelegate(),
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [DesktopVolumeControl(), DesktopVolumeControl()],
            ),
          ),
        ),
      );
      final buttons = find.byType(IconButton);
      tester.widget<Slider>(find.byType(Slider).first).onChanged!(0.35);
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider).last).value, 0.35);
      await tester.tap(buttons.first);
      await tester.pumpAndSettle();
      expect(audioHandler.volume, 0);
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();
      expect(audioHandler.volume, 0.35);
      expect(tester.widget<Slider>(find.byType(Slider).first).value, 0.35);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.linux,
      TargetPlatform.windows,
    }),
  );

  testWidgets('standard volume fits a 400 px mini player', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const item = MediaItem(id: 'test', title: 'Song', artist: 'Artist');
    audioHandler.mediaItem.add(item);
    audioHandler.queue.add([item, const MediaItem(id: 'next', title: 'Next')]);
    audioHandler.playbackState.add(
      PlaybackState(processingState: AudioProcessingState.ready, queueIndex: 0),
    );
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(Slider), findsOneWidget);
    final bounds = tester.getRect(find.byType(Slider));
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(400));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
