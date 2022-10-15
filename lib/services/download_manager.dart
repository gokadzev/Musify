import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/helper/flutter_toast.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> downloadSong(BuildContext context, dynamic song) async {
  if (await Permission.audio.status.isDenied) {
    await Permission.audio.request();
    if (await Permission.audio.status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  if (await Permission.storage.status.isDenied) {
    await [
      Permission.storage,
      Permission.accessMediaLocation,
      Permission.mediaLibrary,
    ].request();

    if (await Permission.storage.status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  final filename = song['title']
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
  final dlPath = await ExtStorageProvider.getExtStorage(dirName: 'Music');
  try {
    showToast(
      AppLocalizations.of(context)!.downloadStarted,
    );
    await File('${dlPath!}/$filename')
        .create(recursive: true)
        .then((value) => filepath = value.path);
    await downloadFileFromYT(filename, filepath, dlPath, song).whenComplete(
      () => showToast(
        AppLocalizations.of(context)!.downloadCompleted,
      ),
    );
  } catch (e) {
    await [Permission.manageExternalStorage].request();
    await File('${dlPath!}/$filename')
        .create(recursive: true)
        .then((value) => filepath = value.path);
    await downloadFileFromYT(filename, filepath, dlPath, song).whenComplete(
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
