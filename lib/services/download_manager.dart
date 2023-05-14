import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadSong(BuildContext context, dynamic song) async {
  try {
    final isDirectoryValid = await checkDownloadDirectory(context);
    if (!isDirectoryValid) {
      showToast('${context.l10n()!.chooseDownloadDir}!');
      return;
    }

    final songName = path
        .basenameWithoutExtension('${song['artist']} ${song['title']}')
        .replaceAll(
          RegExp(r'[^\w\s-]'),
          '',
        ) // remove non-alphanumeric characters except for hyphens and spaces
        .replaceAll(RegExp(r'(\s)+'), '-'); // replace spaces with hyphens

    final filename = '$songName.${prefferedFileExtension.value}';

    final audio = await getSong(song['ytid'].toString(), song['isLive']);
    await FlutterDownloader.enqueue(
      url: audio,
      savedDir: downloadDirectory,
      fileName: filename,
      showNotification: true,
      openFileFromNotification: true,
      headers: {
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36',
        'cookie': 'CONSENT=YES+cb',
        'accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'accept-language': 'en-US,en;q=0.9',
        'sec-fetch-dest': 'document',
        'sec-fetch-mode': 'navigate',
        'sec-fetch-site': 'none',
        'sec-fetch-user': '?1',
        'sec-gpc': '1',
        'upgrade-insecure-requests': '1'
      },
    );
  } catch (e) {
    logger.e('Error while downloading song: $e');
    showToast('${context.l10n()!.downloadFailed}, $e');
  }
}

Future<void> checkNecessaryPermissions(BuildContext context) async {
  await Permission.audio.request();
  await Permission.notification.request();
  try {
    await Permission.storage.request();
  } catch (e) {
    logger.e('Error while requesting permissions: $e');
    showToast(
      '${context.l10n()!.errorWhileRequestingPerms} + $e',
    );
  }
}

Future<bool> checkDownloadDirectory(BuildContext context) async {
  final _localDir = Directory(downloadDirectory);

  try {
    if (!await _localDir.exists()) {
      await _localDir.create(recursive: true);
    }
    return true;
  } catch (e) {
    logger.e('Error while checking the download folder: $e');
    showToast('${context.l10n()!.error}: $e');
    return false;
  }
}

Future<void> chooseDownloadDirectory(BuildContext context) async {
  try {
    final _downloadDirectory = await FilePicker.platform.getDirectoryPath();
    if (_downloadDirectory != null) {
      final folderName = path.basename(_downloadDirectory);
      if (folderName == 'Music' ||
          folderName == 'Documents' ||
          folderName == 'Downloads') {
        downloadDirectory = _downloadDirectory;
        addOrUpdateData(
          'settings',
          'downloadPath',
          downloadDirectory,
        );
      } else {
        showToast('You can only choose Music, Documents or Downloads folder!');
      }
    } else {
      showToast('${context.l10n()!.chooseDownloadDir}!');
    }
  } catch (e) {
    logger.e('Error while choosing the download directory: $e');
    showToast('Error while choosing the download directory: $e');
  }
}
