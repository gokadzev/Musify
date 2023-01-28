import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:musify/helper/flutter_toast.dart';
import 'package:permission_handler/permission_handler.dart';

void addOrUpdateData(
  String category,
  dynamic key,
  dynamic value,
) {
  if (!Hive.isBoxOpen(category)) {
    Hive.openBox(category);
  }
  Hive.box(category).put(key, value);
}

Future getData(String category, dynamic key) async {
  if (!Hive.isBoxOpen(category)) {
    await Hive.openBox(category);
  }
  return Hive.box(category).get(key);
}

void deleteData(String category, dynamic key) {
  if (!Hive.isBoxOpen(category)) {
    Hive.openBox(category);
  }
  Hive.box(category).delete(key);
}

void clearCache() async {
  if (!Hive.isBoxOpen('cache')) {
    await Hive.openBox('cache');
  }
  await Hive.box('cache').clear();
}

Future backupData() async {
  final boxNames = ['user', 'settings'];
  final dlPath = await FilePicker.platform.getDirectoryPath();

  if (dlPath == null) {
    showToast('Choose Backup Directory!');
    return false;
  }

  for (var i = 0; i < boxNames.length; i++) {
    await Hive.openBox(boxNames[i]);
    try {
      await File(Hive.box(boxNames[i]).path!)
          .copy('$dlPath/${boxNames[i]}Data.hive');
    } catch (e) {
      await [
        Permission.manageExternalStorage,
      ].request();
      await File(Hive.box(boxNames[i]).path!)
          .copy('$dlPath/${boxNames[i]}Data.hive');
      return 'Permissions problem, if you already gave requested permission, Backup data again!';
    }
  }
  return 'Backuped Successfully!';
}

Future restoreData() async {
  final boxNames = ['user', 'settings'];
  final uplPath = await FilePicker.platform.getDirectoryPath();

  if (uplPath == null) {
    showToast('Choose Restore File Directory!');
    return false;
  }

  for (var i = 0; i < boxNames.length; i++) {
    await Hive.openBox(boxNames[i]);
    try {
      final box = await Hive.openBox(boxNames[i]);
      final boxPath = box.path;
      await File('$uplPath/${boxNames[i]}Data.hive').copy(boxPath!);
    } catch (e) {
      await [
        Permission.manageExternalStorage,
      ].request();
      return 'Permissions problem, if you already gave requested permission, Restore data again!';
    }
  }

  return 'Restored Successfully!';
}
