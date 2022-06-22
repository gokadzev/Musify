import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';

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

Future backupData() async {
  final List boxNames = ["user", "settings"];
  final String? dlPath =
      await ExtStorageProvider.getExtStorage(dirName: 'Musify');

  for (int i = 0; i < boxNames.length; i++) {
    await Hive.openBox(boxNames[i].toString());
    try {
      await File(Hive.box(boxNames[i].toString()).path!)
          .copy('$dlPath/${boxNames[i]}Data.hive');
      return "Backuped Succesfully!";
    } catch (e) {
      await [
        Permission.manageExternalStorage,
      ].request();
      await File(Hive.box(boxNames[i].toString()).path!)
          .copy('$dlPath/${boxNames[i]}Data.hive');
      return "Permissions problem, if you already gave requested permission, Backup data again!";
    }
  }
}

Future restoreData() async {
  final List boxNames = ["user", "settings"];
  final String? uplPath =
      await ExtStorageProvider.getExtStorage(dirName: 'Musify');

  for (int i = 0; i < boxNames.length; i++) {
    await Hive.openBox(boxNames[i].toString());
    try {
      final Box box = await Hive.openBox(boxNames[i]);
      final boxPath = box.path;
      File('${uplPath!}/${boxNames[i]}Data.hive').copy(boxPath!);
      return "Restored Succesfully!";
    } catch (e) {
      await [
        Permission.manageExternalStorage,
      ].request();
      return "Permissions problem, if you already gave requested permission, Restore data again!";
    }
  }
}
