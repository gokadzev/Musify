import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/more_page.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:permission_handler/permission_handler.dart';

final invalidCharacters = RegExp(r'[\\/*?:"<>|^:]');

Future<void> downloadSong(BuildContext context, dynamic song) async {
  try {
    if (!await checkDownloadDirectory(context)) {
      return;
    }

    final filename = song['artist'] +
        ' - ' +
        song['title'].replaceAll(invalidCharacters, '').replaceAll(' ', '') +
        '.${prefferedFileExtension.value}';

    final audio = await getSong(song['ytid'].toString());
    await FlutterDownloader.enqueue(
      url: audio,
      savedDir: downloadDirectory!,
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
    debugPrint('Error while downloading song: $e');
    showToast(
      '${AppLocalizations.of(context)!.downloadFailed}, $e',
    );
  }
}

Future<void> checkNecessaryPermissions(BuildContext context) async {
  await Permission.audio.request();
  await Permission.notification.request();
  try {
    await Permission.storage.request();
  } catch (e) {
    showToast(
      '${AppLocalizations.of(context)!.errorWhileRequestingPerms} + $e',
    );
  }
}

Future<bool> checkDownloadDirectory(BuildContext context) async {
  downloadDirectory ??= await FilePicker.platform.getDirectoryPath();

  if (downloadDirectory == null) {
    showToast('${AppLocalizations.of(context)!.chooseDownloadDir}!');
    return false;
  }

  addOrUpdateData('settings', 'downloadPath', downloadDirectory);

  return true;
}
