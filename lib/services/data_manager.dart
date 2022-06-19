import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/ext_storage.dart';

Future<void> addOrUpdateData(String category, key, value) async {
  final box = await Hive.openBox(category);
  box.put(key, value);
}

Future getData(String category, key) async {
  final box = await Hive.openBox(category);
  return box.get(key);
}

Future<void> deleteData(String category, key) async {
  final box = await Hive.openBox(category);
  box.delete(key);
}

Future<void> clearCache() async {
  DefaultCacheManager().emptyCache();
}

Future<void> backupData() async {
  final String? dlPath =
      await ExtStorageProvider.getExtStorage(dirName: 'Musify');
  final box = await Hive.openBox('user');
  File(Hive.box('user').path!).copy('${dlPath!}/userdata.hive');
  box.close();
  final box1 = await Hive.openBox('settings');
  File(Hive.box('settings').path!).copy('$dlPath/settings.hive');
  box1.close();
}

Future<void> restoreData() async {
  await Hive.openBox('user');
  var box = Hive.box('user');
  final boxPath = box.path;
  await box.close();
  final String? uplPath =
      await ExtStorageProvider.getExtStorage(dirName: 'Musify');
  File('${uplPath!}/userdata.hive').copy(boxPath!);
  box = await Hive.openBox('user');
  await Hive.openBox('settings');
  var box1 = Hive.box('settings');
  final boxPath1 = box1.path;
  await box1.close();
  File('$uplPath/settings.hive').copy(boxPath1!);
  box1 = await Hive.openBox('settings');
}
