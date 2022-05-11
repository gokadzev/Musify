import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/ext_storage.dart';

addOrUpdateData(category, key, value) async {
  var box = await Hive.openBox(category);
  box.put(key, value);
}

getData(category, key) async {
  var box = await Hive.openBox(category);
  return box.get(key);
}

deleteData(category, key) async {
  var box = await Hive.openBox(category);
  box.delete(key);
}

clearCache() {
  DefaultCacheManager().emptyCache();
}

backupData() async {
  String? dlPath = await ExtStorageProvider.getExtStorage(dirName: 'Musify');
  var box = await Hive.openBox('user');
  File(Hive.box('user').path!).copy(dlPath! + '/backup.hive');
  box.close();
}

restoreData() async {
  await Hive.openBox('user');
  var box = Hive.box('user');
  var boxPath = box.path;
  await box.close();
  String? uplPath = await ExtStorageProvider.getExtStorage(dirName: 'Musify');
  File(uplPath! + '/backup.hive').copy(boxPath!);
  box = await Hive.openBox('user');
}
