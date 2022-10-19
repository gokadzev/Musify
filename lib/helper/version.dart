import 'dart:convert';
import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:musify/main.dart';
import 'package:musify/services/ext_storage.dart';

String? version;
late String dlUrl;
const apiUrl =
    'https://raw.githubusercontent.com/gokadzev/Musify/update/check.json';

Future<bool> checkAppUpdates() async {
  version ??= packageInfo.version;
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(apiUrl));
  final response = await request.close();
  final contentAsString = await utf8.decodeStream(response);
  final map = json.decode(contentAsString);
  if (map['version'].toString() != version) {
    return true;
  } else {
    return false;
  }
}

Future<void> downloadAppUpdates() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(apiUrl));
  final response = await request.close();
  final contentAsString = await utf8.decodeStream(response);
  final map = json.decode(contentAsString);
  if (await getCPUArchitecture() == 'aarch64') {
    dlUrl = map['arm64url'].toString();
  } else {
    dlUrl = map['url'].toString();
  }
  final dlPath = await ExtStorageProvider.getExtStorage(dirName: 'Download');
  final file = File('${dlPath!}/Musify.apk');
  if (await file.exists()) {
    await file.delete();
  }
  await FlutterDownloader.enqueue(
    url: dlUrl,
    savedDir: dlPath,
    saveInPublicStorage: true,
  );
}

Future<String> getCPUArchitecture() async {
  final info = await Process.run('uname', ['-m']);
  final cpu = info.stdout.toString().replaceAll('\n', '');
  return cpu;
}
