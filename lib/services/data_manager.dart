import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:musify/extensions/l10n.dart';

void addOrUpdateData(String category, String key, dynamic value) async {
  final _box = await _openBox(category);
  await _box.put(key, value);
  if (category == 'cache') {
    await _box.put('${key}_date', DateTime.now());
  }
}

Future getData(
  String category,
  String key, {
  dynamic defaultValue,
  Duration cachingDuration = const Duration(days: 30),
}) async {
  final _box = await _openBox(category);
  if (category == 'cache') {
    final cacheIsValid = await isCacheValid(_box, key, cachingDuration);
    if (!cacheIsValid) {
      deleteData(category, key);
      deleteData(category, '${key}_date');
      return null;
    }
  }
  return await _box.get(key, defaultValue: defaultValue);
}

void deleteData(String category, String key) async {
  final _box = await _openBox(category);
  await _box.delete(key);
}

void clearCache() async {
  final _cacheBox = await _openBox('cache');
  await _cacheBox.clear();
}

Future<bool> isCacheValid(
  Box box,
  String key,
  Duration cachingDuration,
) async {
  final date = box.get('${key}_date', defaultValue: DateTime.now());
  final age = DateTime.now().difference(date);
  return age < cachingDuration;
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
    return '${context.l10n!.chooseBackupDir}!';
  }

  try {
    for (final boxName in boxNames) {
      final sourceFile = File('$dlPath/$boxName.hive');
      final box = await _openBox(boxName);

      if (await sourceFile.exists()) {
        await sourceFile.delete();
      }

      await box.compact();
      await File(box.path!).copy(sourceFile.path);
    }
    return '${context.l10n!.backedupSuccess}!';
  } catch (e) {
    return '${context.l10n!.backupError}: $e';
  }
}

Future<String> restoreData(BuildContext context) async {
  final boxNames = ['user', 'settings'];
  final uplPath = await FilePicker.platform.getDirectoryPath();

  if (uplPath == null) {
    return '${context.l10n!.chooseRestoreDir}!';
  }

  try {
    for (final boxName in boxNames) {
      final sourceFile = File('$uplPath/$boxName.hive');
      final box = await _openBox(boxName);

      final boxPath = box.path;
      await sourceFile.copy(boxPath!);
    }
    return '${context.l10n!.restoredSuccess}!';
  } catch (e) {
    return '${context.l10n!.restoreError}: $e';
  }
}
