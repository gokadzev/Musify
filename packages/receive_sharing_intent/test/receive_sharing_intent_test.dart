import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  const channel = MethodChannel('receive_sharing_intent/messages');

  const _testUriString = 'content://media/external/images/media/43993';

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getInitialText':
          return _testUriString;
        case 'getInitialTextAsUri':
          return Uri.parse(_testUriString);
        default:
          throw UnimplementedError();
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getInitialText', () async {
    final actual = await ReceiveSharingIntent.getInitialText();
    expect(actual, _testUriString);
  });

  test('getInitialTextAsUri', () async {
    final actual = await ReceiveSharingIntent.getInitialTextAsUri();
    expect(actual, Uri.parse(_testUriString));
  });
}
