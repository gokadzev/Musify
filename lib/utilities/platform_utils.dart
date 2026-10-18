import 'package:flutter/foundation.dart';

bool get isAndroidPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

bool get isIosPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get isMobilePlatform => isAndroidPlatform || isIosPlatform;

bool get isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);
