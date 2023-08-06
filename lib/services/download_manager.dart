import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/logger_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

final supportedFolderNames = ['Music', 'Documents', 'Downloads'];

Future<void> downloadSong(BuildContext context, dynamic song) async {
  try {
    final songName = path
        .basenameWithoutExtension('${song['artist']} ${song['title']}')
        .replaceAll(
          RegExp(r'[^\w\s-]'),
          '',
        ) // remove non-alphanumeric characters except for hyphens and spaces
        .replaceAll(RegExp(r'(\s)+'), '-'); // replace spaces with hyphens

    final filename = '$songName.${prefferedFileExtension.value}';

    final audio = await getSong(song['ytid'].toString(), song['isLive']);
    final task = DownloadTask(
      url: audio,
      filename: filename,
    );

    await FileDownloader().download(
      task,
      onStatus: (status) async {
        if (status == TaskStatus.complete) {
          final newFileLocation = await FileDownloader()
              .moveToSharedStorage(task, SharedStorage.audio);

          if (newFileLocation == null) {
            await FileDownloader()
                .moveToSharedStorage(task, SharedStorage.downloads);
          }
        }
      },
    );
  } catch (e) {
    Logger.log('Error while downloading song: $e');
    showToast(context, '${context.l10n()!.downloadFailed}, $e');
  }
}

Future<void> downloadSongFaster(BuildContext context, dynamic song) async {
  try {
    final songName = path
        .basenameWithoutExtension('${song['artist']} ${song['title']}')
        .replaceAll(
          RegExp(r'[^\w\s-]'),
          '',
        ) // remove non-alphanumeric characters except for hyphens and spaces
        .replaceAll(RegExp(r'(\s)+'), '-'); // replace spaces with hyphens

    final filename = '$songName.${prefferedFileExtension.value}';
    final documentsDir = await getApplicationDocumentsDirectory();

    final audioManifest = await getSongManifest(song['ytid'].toString());
    final stream = yt.videos.streamsClient.get(audioManifest);
    final file = File('${documentsDir.path}/$filename');
    final fileStream = file.openWrite();
    await stream.pipe(fileStream);

    await fileStream.flush();
    await fileStream.close();

    final newFileLocation = await FileDownloader()
        .moveFileToSharedStorage(file.path, SharedStorage.audio);
    if (newFileLocation == null) {
      await FileDownloader()
          .moveFileToSharedStorage(file.path, SharedStorage.downloads);
    }
    showToast(context, '${context.l10n()!.downloadCompleted} - $songName');
  } catch (e) {
    Logger.log('Error while downloading song: $e');
    showToast(context, '${context.l10n()!.downloadFailed}, $e');
  }
}

Future<void> downloadSongsFromPlaylist(
  BuildContext context,
  List list,
) async {
  try {
    final _isHeavyProcess = list.length > 50;
    final _pauseDuration = _isHeavyProcess
        ? const Duration(seconds: 10)
        : const Duration(seconds: 5);
    showToast(context, context.l10n()!.fasterDownloadMsg);
    for (final song in list) {
      await downloadSongFaster(context, song);
      await Future.delayed(_pauseDuration);
    }
  } catch (e) {
    Logger.log('Error while downloading playlist songs: $e');
    showToast(context, '${context.l10n()!.downloadFailed}, $e');
  }
}

Future<void> checkNecessaryPermissions(BuildContext context) async {
  await Permission.audio.request();
  await Permission.notification.request();
  try {
    await Permission.storage.request();
  } catch (e) {
    Logger.log('Error while requesting permissions: $e');
    showToast(
      context,
      '${context.l10n()!.errorWhileRequestingPerms} + $e',
    );
  }
}
