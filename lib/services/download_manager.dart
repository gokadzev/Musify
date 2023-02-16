import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/more_page.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/download_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> downloadSong(BuildContext context, dynamic song) async {
  await checkAudioPerms();
  if (!await checkDownloadDirectory(context)) {
    return;
  }

  lastDownloadedSongIdListener.value = song['ytid'];

  final tempFileName = song['more_info']['singers'] +
      ' - ' +
      song['title']
          .replaceAll(r'\', '')
          .replaceAll('/', '')
          .replaceAll('*', '')
          .replaceAll('?', '')
          .replaceAll('"', '')
          .replaceAll('<', '')
          .replaceAll('>', '')
          .replaceAll('|', '')
          .replaceAll(' ', '');

  final filename = tempFileName
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

  final filepath = '${downloadDirectory!}/$filename';
  try {
    await downloadFileFromYT(
      context,
      filename,
      filepath,
      downloadDirectory!,
      song,
    );
  } catch (e) {
    await [Permission.manageExternalStorage].request();

    await downloadFileFromYT(
      context,
      filename,
      filepath,
      downloadDirectory!,
      song,
    );
  }
}

Future<void> downloadFileFromYT(
  BuildContext context,
  String filename,
  String filepath,
  String dlPath,
  dynamic song,
) async {
  final manifest =
      await yt.videos.streamsClient.getManifest(song['ytid'].toString());
  final audio = manifest.audioOnly.withHighestBitrate();
  final audioStream = yt.videos.streamsClient.get(audio);
  final file = File(filepath);

  if (file.existsSync()) {
    file.deleteSync();
  }

  final output = file.openWrite(mode: FileMode.writeOnlyAppend);

  final len = audio.size.totalBytes;
  var count = 0;

  showToast(
    AppLocalizations.of(context)!.downloadStarted,
  );

  await for (final data in audioStream) {
    count += data.length;

    downloadListenerNotifier.value = ((count / len) * 100).ceil();

    output.add(data);
  }
  showToast(
    AppLocalizations.of(context)!.downloadCompleted,
  );
  downloadListenerNotifier.value = 0;
  await output.close();
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
    if (await Permission.accessMediaLocation.status.isPermanentlyDenied) {
      await openAppSettings();
    }
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
