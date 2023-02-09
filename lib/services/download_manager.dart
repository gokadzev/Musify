import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/morePage.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> downloadSong(BuildContext context, dynamic song) async {
  await checkAudioPerms();
  if (!await checkDownloadDirectory(context)) {
    return;
  }

  final filename = song['more_info']['singers'] +
      ' - ' +
      song['title']
          .replaceAll(r'\', '')
          .replaceAll('/', '')
          .replaceAll('*', '')
          .replaceAll('?', '')
          .replaceAll('"', '')
          .replaceAll('<', '')
          .replaceAll('>', '')
          .replaceAll('|', '') +
      '.' +
      prefferedFileExtension.value;

  var filepath = '';
  try {
    showToast(
      AppLocalizations.of(context)!.downloadStarted,
    );
    await File('${downloadDirectory!}/$filename')
        .create(recursive: true)
        .then((value) => filepath = value.path);
    await downloadFileFromYT(filename, filepath, downloadDirectory!, song)
        .whenComplete(
      () => showToast(
        AppLocalizations.of(context)!.downloadCompleted,
      ),
    );
  } catch (e) {
    await [Permission.manageExternalStorage].request();
    await File('${downloadDirectory!}/$filename')
        .create(recursive: true)
        .then((value) => filepath = value.path);
    await downloadFileFromYT(filename, filepath, downloadDirectory!, song)
        .whenComplete(
      () => showToast(
        AppLocalizations.of(context)!.downloadCompleted,
      ),
    );
  }
}

Future<void> downloadFileFromYT(
  String filename,
  String filepath,
  String dlPath,
  dynamic song,
) async {
  final audioStream = await getSong(song['ytid'].toString(), false);
  final file = File(filepath);
  final fileStream = file.openWrite();
  await yt.videos.streamsClient.get(audioStream as StreamInfo).pipe(fileStream);
  await fileStream.flush();
  await fileStream.close();
}

Future<void> checkAudioPerms() async {
  if (await Permission.storage.status.isDenied) {
    await Permission.storage.request();

    if (await Permission.storage.status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  if (await Permission.accessMediaLocation.status.isDenied) {
    await Permission.accessMediaLocation.request();
  }

  if (await Permission.manageExternalStorage.status.isDenied) {
    await Permission.manageExternalStorage.request();
  }

  if (await Permission.audio.status.isDenied) {
    await Permission.audio.request();
    if (await Permission.audio.status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}

Future<bool> checkDownloadDirectory(context) async {
  if (downloadDirectory == null) {
    downloadDirectory = await FilePicker.platform.getDirectoryPath();

    if (downloadDirectory == null) {
      showToast('${AppLocalizations.of(context)!.chooseDownloadDir}!');
      return false;
    }

    addOrUpdateData('settings', 'downloadPath', downloadDirectory);

    return true;
  }
  return true;
}
