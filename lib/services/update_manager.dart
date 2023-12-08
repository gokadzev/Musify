import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:musify/API/version.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:permission_handler/permission_handler.dart';

const String checkUrl =
    'https://raw.githubusercontent.com/gokadzev/Musify/update/check.json';
const String downloadUrlKey = 'url';
const String downloadUrlArm64Key = 'arm64url';
const String downloadFilename = 'Musify.apk';

Future<void> checkAppUpdates(BuildContext context) async {
  try {
    final response = await http.get(Uri.parse(checkUrl));
    if (response.statusCode == 200) {
      final map = json.decode(response.body) as Map<String, dynamic>;
      final latestVersion = map['version'].toString();
      if (isLatestVersionHigher(appVersion, latestVersion)) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n!.appUpdateIsAvailable,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'V$latestVersion',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: <Widget>[
                ButtonBar(
                  alignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        context.l10n!.cancel.toUpperCase(),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                      ),
                      onPressed: () {
                        downloadAppUpdates(map);
                        Navigator.pop(context);
                      },
                      child: Text(
                        context.l10n!.download.toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } else {
      logger.log(
        'Fetch update API call returned status code ${response.statusCode}',
      );
    }
  } catch (e) {
    logger.log('Error in checkAppUpdates: $e');
  }
}

Future<void> downloadAppUpdates(Map<String, dynamic> map) async {
  try {
    final dlUrl = await getDownloadUrl(map);
    final task = DownloadTask(
      url: dlUrl,
      filename: downloadFilename,
    );

    await FileDownloader().download(
      task,
      onStatus: (status) async {
        if (status == TaskStatus.complete) {
          await FileDownloader()
              .moveToSharedStorage(task, SharedStorage.downloads);
        }
      },
    );
  } catch (e) {
    logger.log('Error in downloadAppUpdates: $e');
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

Future<String> getDownloadUrl(Map<String, dynamic> map) async {
  final cpuArchitecture = await getCPUArchitecture();
  final url = cpuArchitecture == 'aarch64'
      ? map[downloadUrlArm64Key].toString()
      : map[downloadUrlKey].toString();
  return url;
}

Future<void> checkNecessaryPermissions(BuildContext context) async {
  await Permission.audio.request();
  await Permission.notification.request();
  try {
    await Permission.storage.request();
  } catch (e) {
    logger.log('Error while requesting permissions: $e');
    showToast(
      context,
      '${context.l10n!.errorWhileRequestingPerms} + $e',
    );
  }
}
