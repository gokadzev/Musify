import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/widgets/custom_search_bar.dart';
import 'package:musify/widgets/desktop_shortcuts.dart';

const desktopPlatforms = TargetPlatformVariant({
  TargetPlatform.linux,
  TargetPlatform.windows,
});

void main() {
  final actions = <DesktopShortcut>[];
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('musify_shortcuts');
    Hive.init(directory.path);
    await Hive.openBox('user');
  });
  setUp(actions.clear);
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> mount(WidgetTester tester, {Widget? child}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DesktopShortcuts(
          onAction: actions.add,
          child: child ?? const Scaffold(body: Text('Player')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  testWidgets('fixed shortcuts dispatch once on key down', (tester) async {
    await mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    for (final key in [
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyP,
    ]) {
      await ctrl(tester, key);
    }
    expect(actions, DesktopShortcut.values);
  }, variant: desktopPlatforms);

  testWidgets('holding transport keys does not skip multiple tracks', (
    tester,
  ) async {
    await mount(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(actions, [
      DesktopShortcut.next,
      DesktopShortcut.volumeUp,
      DesktopShortcut.volumeUp,
    ]);
  }, variant: desktopPlatforms);

  testWidgets('typing and editing keys are left to the focused field', (
    tester,
  ) async {
    await mount(
      tester,
      child: const Scaffold(body: TextField(autofocus: true)),
    );
    await tester.enterText(find.byType(TextField), 'a');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await ctrl(tester, LogicalKeyboardKey.arrowLeft);
    await ctrl(tester, LogicalKeyboardKey.arrowUp);
    await ctrl(tester, LogicalKeyboardKey.keyP);
    expect(actions, isEmpty);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'a',
    );
    await ctrl(tester, LogicalKeyboardKey.keyF);
    expect(actions, [DesktopShortcut.search]);
  }, variant: desktopPlatforms);

  testWidgets(
    'mobile does not capture desktop shortcuts',
    (tester) async {
      await mount(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await ctrl(tester, LogicalKeyboardKey.keyF);
      expect(actions, isEmpty);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('search focus survives first navigation and repeated requests', (
    tester,
  ) async {
    requestSearchFocus();
    await mount(tester, child: const SearchPage());
    final bar = tester.widget<CustomSearchBar>(find.byType(CustomSearchBar));
    expect(bar.focusNode.hasFocus, isTrue);
    bar.focusNode.unfocus();
    await tester.pump();
    requestSearchFocus();
    await tester.pumpAndSettle();
    expect(bar.focusNode.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    requestSearchFocus();
    await tester.pump();
    expect(tester.takeException(), isNull);
  }, variant: desktopPlatforms);
}
