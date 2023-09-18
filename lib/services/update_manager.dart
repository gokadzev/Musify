import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:musify/API/version.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/logger_service.dart';
import 'package:musify/utilities/flutter_toast.dart';

late String dlUrl;
const apiUrl =
    'https://raw.githubusercontent.com/gokadzev/Musify/update/check.json';

Future<void> checkAppUpdates(
  BuildContext context, {
  bool downloadUpdateAutomatically = false,
}) async {
  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode != 200) {
      Logger.log(
        'Fetch update API call returned status code ${response.statusCode}',
      );
      throw Exception('Failed to fetch app updates');
    }
    final map = json.decode(response.body) as Map<String, dynamic>;
    if (isLatestVersionHigher(appVersion, map['version'].toString())) {
      if (downloadUpdateAutomatically) {
        await downloadAppUpdates();
        showToast(
          context,
          '${context.l10n()!.appUpdateAvailableAndDownloading}!',
        );
      } else {
        showToast(
          context,
          '${context.l10n()!.appUpdateIsAvailable}!',
        );
      }
    }
  } catch (e) {
    Logger.log('Error in checkAppUpdates: $e');
  }
}

Future<void> downloadAppUpdates() async {
  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode != 200) {
      Logger.log(
        'Download update API call returned status code ${response.statusCode}',
      );
      throw Exception('Failed to fetch app updates');
    }
    final map = json.decode(response.body) as Map<String, dynamic>;
    final dlUrl = await getCPUArchitecture() == 'aarch64'
        ? map['arm64url'].toString()
        : map['url'].toString();

    final task = DownloadTask(
      url: dlUrl,
      filename: 'Musify.apk',
    );

    await FileDownloader().download(task);
    await FileDownloader().moveToSharedStorage(task, SharedStorage.downloads);
  } catch (e) {
    Logger.log('Error in downloadAppUpdates: $e');
  }
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
