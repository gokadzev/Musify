import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
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

    await FileDownloader().download(task);
    await FileDownloader().moveToSharedStorage(task, SharedStorage.audio);
  } catch (e) {
    debugPrint('Error while downloading song: $e');
    showToast(context, '${context.l10n()!.downloadFailed}, $e');
  }
}

Future<void> checkNecessaryPermissions(BuildContext context) async {
  await Permission.audio.request();
  await Permission.notification.request();
  try {
    await Permission.storage.request();
  } catch (e) {
    debugPrint('Error while requesting permissions: $e');
    showToast(
      context,
      '${context.l10n()!.errorWhileRequestingPerms} + $e',
    );
  }
}
