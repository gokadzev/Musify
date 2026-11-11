import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/widgets/custom_search_bar.dart';

const desktopPlatforms = TargetPlatformVariant({
  TargetPlatform.linux,
  TargetPlatform.windows,
});

void main() {
  testWidgets('numpad Enter submits once and Escape leaves search', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Muse');
    final focus = FocusNode();
    final submitted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomSearchBar(
            controller: controller,
            focusNode: focus,
            labelText: 'Search',
            onSubmitted: submitted.add,
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    // Flutter's Windows test key map omits Numpad Enter.
    await tester.sendKeyEvent(
      LogicalKeyboardKey.numpadEnter,
      platform: 'linux',
    );
    await tester.pump();
    expect(submitted, ['Muse']);
    expect(focus.hasFocus, isFalse);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    expect(controller.text, 'Muse');
    expect(submitted, ['Muse']);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    focus.dispose();
  }, variant: desktopPlatforms);

  testWidgets('Escape dismisses a sheet after each opening tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showCustomBottomSheet(context, const Text('Sheet content')),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  }, variant: desktopPlatforms);

  testWidgets('Escape from an input inside a sheet dismisses it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showCustomBottomSheet(context, const TextField()),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  }, variant: desktopPlatforms);
  testWidgets(
    'mobile keeps the original persistent sheet behavior',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showCustomBottomSheet(context, const Text('Sheet content')),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsOneWidget);
      closeCurrentBottomSheet();
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
