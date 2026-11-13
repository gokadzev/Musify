import 'dart:io';

bool get isAndroidPlatform => Platform.isAndroid;

bool get isIosPlatform => Platform.isIOS;

bool get isMobilePlatform => isAndroidPlatform || isIosPlatform;

bool get isLinuxPlatform => Platform.isLinux;

bool get isWindowsPlatform => Platform.isWindows;

bool get isDesktopPlatform =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;
