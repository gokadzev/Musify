import 'dart:io';

import 'package:flutter/services.dart';

class AudioPermissionService {
  static const MethodChannel _channel = MethodChannel(
    'musify/audio_permissions',
  );

  static Future<bool> hasAudioPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final result = await _channel.invokeMethod<bool>('hasAudioPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> requestAudioPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'requestAudioPermission',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
