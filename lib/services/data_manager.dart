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

// Cache durations for different types of data
const Duration songCacheDuration = Duration(hours: 1, minutes: 30);
const Duration playlistCacheDuration = Duration(hours: 5);
const Duration defaultCacheDuration = Duration(days: 7);

// In-memory cache for frequently accessed items
final _memoryCache = <String, _CacheEntry>{};

class _CacheEntry {
  _CacheEntry(this.data, this.timestamp);
  final dynamic data;
  final DateTime timestamp;

  bool isValid(Duration cacheDuration) {
    return DateTime.now().difference(timestamp) < cacheDuration;
  }
}

Future<void> addOrUpdateData(String category, String key, dynamic value) async {
  final _box = await _openBox(category);
  await _box.put(key, value);

  if (category == 'cache') {
    await _box.put('${key}_date', DateTime.now());

    // Update memory cache too
    final cacheKey = '${category}_$key';
    _memoryCache[cacheKey] = _CacheEntry(value, DateTime.now());
  }
}

Future<dynamic> getData(
  String category,
  String key, {
  dynamic defaultValue,
  Duration? cachingDuration,
}) async {
  // Set appropriate cache duration based on key
  cachingDuration ??= _getCacheDurationForKey(key);

  // Check memory cache first
  final cacheKey = '${category}_$key';
  final memCacheEntry = _memoryCache[cacheKey];
  if (memCacheEntry != null && memCacheEntry.isValid(cachingDuration)) {
    return memCacheEntry.data;
  }

  final _box = await _openBox(category);
  if (category == 'cache') {
    final cacheIsValid = await isCacheValid(_box, key, cachingDuration);
    if (!cacheIsValid) {
      await deleteData(category, key);
      await deleteData(category, '${key}_date');
      return defaultValue;
    }
  }

  final data = await _box.get(key, defaultValue: defaultValue);

  // Store in memory cache for faster access next time
  if (data != null && category == 'cache') {
    final timestamp = await _box.get('${key}_date') ?? DateTime.now();
    _memoryCache[cacheKey] = _CacheEntry(data, timestamp);
  }

  return data;
}

Future<void> deleteData(String category, String key) async {
  // Remove from memory cache
  _memoryCache
    ..remove('${category}_$key')
    ..remove('${category}_${key}_date');

  final _box = await _openBox(category);
  await _box.delete(key);
}

Future<bool> clearCache() async {
  try {
    // Clear memory cache
    _memoryCache.clear();

    final cacheBox = await _openBox('cache');
    await cacheBox.clear();
    return true;
  } catch (e, stackTrace) {
    logger.log('Failed to clear cache', e, stackTrace);
    return false;
  }
}

// Clean up old cache entries to prevent excessive storage usage
Future<void> cleanupOldCacheEntries() async {
  try {
    final cacheBox = await _openBox('cache');
    final now = DateTime.now();

    // Get all keys except the ones with _date suffix
    final keys =
        cacheBox.keys.where((k) => !k.toString().endsWith('_date')).toList();

    for (final key in keys) {
      final dateKey = '${key}_date';
      final date = cacheBox.get(dateKey);

      if (date == null) {
        await cacheBox.delete(key);
        continue;
      }

      final age = now.difference(date);
      // Very old cache entries (older than 30 days) should be removed
      if (age > const Duration(days: 30)) {
        await cacheBox.delete(key);
        await cacheBox.delete(dateKey);
      }
    }
  } catch (e, stackTrace) {
    logger.log('Error cleaning up old cache entries', e, stackTrace);
  }
}

Future<bool> isCacheValid(Box box, String key, Duration cachingDuration) async {
  final date = box.get('${key}_date');
  if (date == null) {
    return false;
  }
  final age = DateTime.now().difference(date);
  return age < cachingDuration;
}

Duration _getCacheDurationForKey(String key) {
  if (key.startsWith('song_') || key.contains('manifest_')) {
    return songCacheDuration;
  } else if (key.startsWith('playlist_') || key.contains('playlistSongs')) {
    return playlistCacheDuration;
  }
  return defaultCacheDuration;
}

Future<Box> _openBox(String category) async {
  if (Hive.isBoxOpen(category)) {
    return Hive.box(category);
  } else {
    return Hive.openBox(category);
  }
}

// Existing backup/restore code remains unchanged
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
        orElse: () => PlatformFile(name: '', size: 0),
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
