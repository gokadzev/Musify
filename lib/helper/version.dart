import 'dart:convert';
import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:musify/services/ext_storage.dart';

late var version;
const apiUrl =
    "https://raw.githubusercontent.com/gokadzev/Musify/update/check.json";

checkAppUpdates() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(apiUrl));
  final response = await request.close();
  final contentAsString = await utf8.decodeStream(response);
  final map = json.decode(contentAsString);
  if (map["version"].toString() != version) {
    return true;
  } else {
    return false;
  }
}

downloadAppUpdates() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(apiUrl));
  final response = await request.close();
  final contentAsString = await utf8.decodeStream(response);
  final map = json.decode(contentAsString);
  final String? dlPath =
      await ExtStorageProvider.getExtStorage(dirName: 'Download');
  final File file = File("${dlPath!}/Musify.apk");
  if (await file.exists()) {
    await file.delete();
  }
  await FlutterDownloader.enqueue(
    url: map["url"].toString(),
    savedDir: dlPath,
    saveInPublicStorage: true,
    showNotification:
        true, // show download progress in status bar (for Android)
    openFileFromNotification:
        true, // click on notification to open downloaded file (for Android)
  );
}
