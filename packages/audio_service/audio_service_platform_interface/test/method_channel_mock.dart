import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MockMethodChannel {
  final MethodChannel methodChannel;
  final Map<String, dynamic>? methods;
  final log = <MethodCall>[];

  MockMethodChannel({
    required String channelName,
    this.methods,
  }) : methodChannel = MethodChannel(channelName) {
    //TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
    //    .setMockMethodCallHandler(methodChannel, _handler);
    methodChannel.setMockMethodCallHandler(_handler);
  }

  MockMethodChannel copyWith(Map<String, dynamic> methods) {
    return MockMethodChannel(channelName: methodChannel.name, methods: methods);
  }

  Future _handler(MethodCall call) async {
    log.add(call);

    if (!methods!.containsKey(call.method)) {
      throw MissingPluginException(
        'No implementation found for method '
        '${call.method} on channel ${methodChannel.name}',
      );
    }

    final dynamic result = methods![call.method];
    if (result is Exception) {
      throw result;
    }

    return Future<dynamic>.value(result);
  }
}
