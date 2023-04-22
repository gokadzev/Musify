import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:musify/API/version.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/utilities/flutter_toast.dart';

late String dlUrl;
const apiUrl =
    'https://raw.githubusercontent.com/gokadzev/Musify/update/check.json';

Future<void> checkAppUpdates(
  BuildContext context, {
  bool downloadUpdateAutomatically = false,
}) async {
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch app updates');
  }
  final map = json.decode(response.body) as Map<String, dynamic>;
  if (isLatestVersionHigher(appVersion, map['version'].toString())) {
    if (downloadUpdateAutomatically) {
      await downloadAppUpdates();
      showToast(
        '${context.l10n()!.appUpdateAvailableAndDownloading}!',
      );
    } else {
      showToast(
        '${context.l10n()!.appUpdateIsAvailable}!',
      );
    }
  }
}

Future<void> downloadAppUpdates() async {
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch app updates');
  }
  final map = json.decode(response.body) as Map<String, dynamic>;
  final dlUrl = await getCPUArchitecture() == 'aarch64'
      ? map['arm64url'].toString()
      : map['url'].toString();
  final dlPath = await FilePicker.platform.getDirectoryPath();
  final file = File('$dlPath/Musify.apk');
  if (await file.exists()) {
    await file.delete();
  }
  await FlutterDownloader.enqueue(
    url: dlUrl,
    savedDir: dlPath!,
    fileName: 'Musify.apk',
    showNotification: true,
  );
}

bool isLatestVersionHigher(String appVersion, String latestVersion) {
  final parsedAppVersion = appVersion.split('.');
  final parsedAppLatestVersion = latestVersion.split('.');
  final length = parsedAppVersion.length > parsedAppLatestVersion.length
      ? parsedAppVersion.length
      : parsedAppLatestVersion.length;
  for (var i = 0; i < length; i++) {
    final value1 =
        i < parsedAppVersion.length ? int.parse(parsedAppVersion[i]) : 0;
    final value2 = i < parsedAppLatestVersion.length
        ? int.parse(parsedAppLatestVersion[i])
        : 0;
    if (value2 > value1) {
      return true;
    } else if (value2 < value1) {
      return false;
    }
  }
  return false;
}

Future<String> getCPUArchitecture() async {
  final info = await Process.run('uname', ['-m']);
  final cpu = info.stdout.toString().replaceAll('\n', '');
  return cpu;
}
