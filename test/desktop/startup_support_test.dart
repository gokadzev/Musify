import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/utilities/startup_support.dart';

void main() {
  group('desktopAudioErrorMessage', () {
    test('explains how to install libmpv', () {
      final message = desktopAudioErrorMessage(
        Exception('Cannot find libmpv at the usual places.'),
      );

      expect(message, contains('libmpv'));
      expect(message, contains('mpv-libs'));
      expect(message, contains('libmpv2'));
      expect(message, contains('pacman -S mpv'));
      expect(message, contains('Cannot find libmpv'));
    });

    test('falls back to a generic audio-engine message', () {
      final message = desktopAudioErrorMessage(StateError('unknown failure'));

      expect(message, contains('audio engine'));
      expect(message, contains('unknown failure'));
      expect(message, isNot(contains('mpv-libs')));
    });
  });

  testWidgets('StartupErrorApp shows the message and recovery actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StartupErrorApp(message: 'Something went wrong'),
    );

    expect(find.text('Musify could not start'), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Copy details'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Quit'), findsOneWidget);
  });
}
