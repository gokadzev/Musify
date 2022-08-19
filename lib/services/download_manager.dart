import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/ext_storage.dart';
import 'package:musify/style/appColors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> downloadSong(dynamic song) async {
  PermissionStatus status = await Permission.storage.status;
  if (status.isDenied) {
    await [
      Permission.storage,
      Permission.accessMediaLocation,
      Permission.mediaLibrary,
    ].request();
    status = await Permission.storage.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  await Fluttertoast.showToast(
    msg: 'Download Started!',
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: accent,
    textColor: accent != const Color(0xFFFFFFFF) ? Colors.white : Colors.black,
    fontSize: 14,
  );

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

  String filepath = '';
  final String? dlPath =
      await ExtStorageProvider.getExtStorage(dirName: 'Musify');
  try {
    await File('${dlPath!}/$filename')
        .create(recursive: true)
        .then((value) => filepath = value.path);
    await downloadFileFromYT(filename, filepath, dlPath, song);
  } catch (e) {
    await [Permission.manageExternalStorage].request();
    await File('${dlPath!}/$filename')
        .create(recursive: true)
        .then((value) => filepath = value.path);
    await downloadFileFromYT(filename, filepath, dlPath, song);
  }

  await Fluttertoast.showToast(
    msg: 'Download Completed!',
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: accent,
    textColor: accent != const Color(0xFFFFFFFF) ? Colors.white : Colors.black,
    fontSize: 14,
  );
}

Future<void> downloadFileFromYT(
    String filename, String filepath, String dlPath, dynamic song) async {
  final audioStream = await getSong(song['ytid'].toString(), false);
  final File file = File(filepath);
  final fileStream = file.openWrite();
  await yt.videos.streamsClient.get(audioStream as StreamInfo).pipe(fileStream);
  await fileStream.flush();
  await fileStream.close();
}
