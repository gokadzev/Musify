/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';

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

Future<bool> isCacheValid(Box box, String key, Duration cachingDuration) async {
  final date = box.get('${key}_date');
  if (date == null) {
    return false;
  }
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
  } catch (e, stackTrace) {
    return '${context.l10n!.backupError}: $e\n$stackTrace';
  }
}

Future<String> restoreData(BuildContext context) async {
  final boxNames = ['user', 'settings'];
  final backupFiles = await FilePicker.platform.pickFiles(allowMultiple: true);

  if (backupFiles == null || backupFiles.files.isEmpty) {
    return '${context.l10n!.chooseBackupFiles}!';
  }

  try {
    for (final boxName in boxNames) {
      final _file = backupFiles.files.firstWhere(
        (file) => file.name == '$boxName.hive',
        orElse:
            () => PlatformFile(
              name: '',
              size: 0,
            ), // Create a PlatformFile with null path if not found
      );

      if (_file.path != null && _file.path!.isNotEmpty && _file.size != 0) {
        final sourceFilePath = _file.path!;
        final sourceFile = File(sourceFilePath);

        final box = await _openBox(boxName);
        final boxPath = box.path;
        await box.close();

        if (boxPath != null) {
          await sourceFile.copy(boxPath);
        }
      } else {
        logger.log(
          'Source file for $boxName not found while restoring data.',
          null,
          null,
        );
      }
    }

    return '${context.l10n!.restoredSuccess}!';
  } catch (e, stackTrace) {
    logger.log('${context.l10n!.restoreError}:', e, stackTrace);
    return '${context.l10n!.restoreError}: $e\n$stackTrace';
  }
}
