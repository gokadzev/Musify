import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

void addOrUpdateData(
  String category,
  dynamic key,
  dynamic value,
) async {
  final _box = await _openBox(category);
  await _box.put(key, value);
}

Future getData(String category, dynamic key) async {
  final _box = await _openBox(category);
  return await _box.get(key);
}

void deleteData(String category, dynamic key) async {
  final _box = await _openBox(category);
  await _box.delete(key);
}

void clearCache() async {
  final _cacheBox = await _openBox('cache');
  await _cacheBox.clear();
}

Future<Box> _openBox(String category) async {
  if (!Hive.isBoxOpen(category)) {
    await Hive.openBox(category);
  }
  return Hive.box(category);
}

Future backupData(BuildContext context) async {
  final boxNames = ['user', 'settings'];
  final dlPath = await FilePicker.platform.getDirectoryPath();

  if (dlPath == null) {
    return '${AppLocalizations.of(context)!.chooseBackupDir}!';
  }

  for (var i = 0; i < boxNames.length; i++) {
    await Hive.openBox(boxNames[i]);
    try {
      await File(Hive.box(boxNames[i]).path!)
          .copy('$dlPath/${boxNames[i]}Data.hive');
    } catch (e) {
      await File(Hive.box(boxNames[i]).path!)
          .copy('$dlPath/${boxNames[i]}Data.hive');
      return '${AppLocalizations.of(context)!.backupPermsProblem}!';
    }
  }
  return '${AppLocalizations.of(context)!.backupedSuccess}!';
}

Future restoreData(context) async {
  final boxNames = ['user', 'settings'];
  final uplPath = await FilePicker.platform.getDirectoryPath();

  if (uplPath == null) {
    return '${AppLocalizations.of(context)!.chooseRestoreDir}!';
  }

  for (var i = 0; i < boxNames.length; i++) {
    await Hive.openBox(boxNames[i]);
    try {
      final box = await Hive.openBox(boxNames[i]);
      final boxPath = box.path;
      await File('$uplPath/${boxNames[i]}Data.hive').copy(boxPath!);
    } catch (e) {
      return '${AppLocalizations.of(context)!.restorePermsProblem}!';
    }
  }

  return '${AppLocalizations.of(context)!.restoredSuccess}!';
}
