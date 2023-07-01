import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:musify/extensions/l10n.dart';

void addOrUpdateData(String category, dynamic key, dynamic value) async {
  final _box = await _openBox(category);
  await _box.put(key, value);
  if (category == 'cache') {
    await _box.put(key + '_date', DateTime.now());
  }
}

Future getData(String category, dynamic key) async {
  final _box = await _openBox(category);
  if (category == 'cache') {
    final cacheIsValid = await isCacheValid(_box, key);
    if (!cacheIsValid) {
      deleteData(category, key);
      deleteData(category, '${key}_date');
      return null;
    }
  }
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

Future<bool> isCacheValid(Box box, String key) async {
  final maxAge = const Duration(days: 30);
  final date = box.get('${key}_date', defaultValue: DateTime.now());
  final age = DateTime.now().difference(date);
  return age < maxAge;
}

Future<Box> _openBox(String category) async {
  if (Hive.isBoxOpen(category)) {
    return Hive.box(category);
  } else {
    return Hive.openBox(category);
  }
}

Future<String> backupData(BuildContext context) async {
  final boxNames = ['user', 'settings'];
  final dlPath = await FilePicker.platform.getDirectoryPath();

  if (dlPath == null) {
    return '${context.l10n()!.chooseBackupDir}!';
  }

  for (var i = 0; i < boxNames.length; i++) {
    try {
      final _box = await _openBox(boxNames[i]);
      await File(_box.path!).copy('$dlPath/${boxNames[i]}Data.hive');
    } catch (e) {
      return '${context.l10n()!.backupError}: $e';
    }
  }
  return '${context.l10n()!.backedupSuccess}!';
}

Future<String> restoreData(BuildContext context) async {
  final boxNames = ['user', 'settings'];
  final uplPath = await FilePicker.platform.getDirectoryPath();

  if (uplPath == null) {
    return '${context.l10n()!.chooseRestoreDir}!';
  }

  for (var i = 0; i < boxNames.length; i++) {
    try {
      final _box = await _openBox(boxNames[i]);
      final boxPath = _box.path;
      await File('$uplPath/${boxNames[i]}Data.hive').copy(boxPath!);
    } catch (e) {
      return '${context.l10n()!.restoreError}: $e';
    }
  }

  return '${context.l10n()!.restoredSuccess}!';
}
