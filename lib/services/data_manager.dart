/*
 *     Copyright (C) 2026 Valeri Gokadze
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
const Duration searchCacheDuration = Duration(days: 4);
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

// Maximum number of entries allowed in the memory cache
const int _maxMemoryCacheSize = 500;
const int _memoryCacheTrimSize = 100;

void _trimMemoryCacheIfNeeded() {
  if (_memoryCache.length > _maxMemoryCacheSize) {
    final keysToRemove = _memoryCache.keys.take(_memoryCacheTrimSize).toList();
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }
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
    _trimMemoryCacheIfNeeded();
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
  _trimMemoryCacheIfNeeded();

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
    final keys = cacheBox.keys
        .where((k) => !k.toString().endsWith('_date'))
        .toList();

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

// Check if the cache is still valid based on the caching duration
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
  } else if (key.startsWith('search_')) {
    return searchCacheDuration;
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

Future<String> backupData(BuildContext context) async {
  final boxNames = ['user', 'settings'];
  final dlPath = await FilePicker.platform.getDirectoryPath();

  if (dlPath == null) {
    return '${context.l10n!.chooseBackupDir}!';
  }

  if (!dlPath.contains('Documents') && !dlPath.contains('Download')) {
    return context.l10n!.folderRestrictions;
  }

  try {
    for (final boxName in boxNames) {
      final box = await _openBox(boxName);

      if (box.path == null) {
        logger.log('Box path is null for $boxName', null, null);
        continue;
      }

      final sourceFile = File(box.path!);
      final targetFile = File('$dlPath/$boxName.hive');

      // Ensure the target directory exists
      await targetFile.parent.create(recursive: true);

      // Safely handle existing backup file
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (e) {
          // If delete fails, try with a timestamp suffix
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final newTargetFile = File('$dlPath/${boxName}_$timestamp.hive');
          await sourceFile.copy(newTargetFile.path);
          continue;
        }
      }

      // Compact the box before copying
      try {
        await box.compact();
      } catch (e) {
        logger.log('Failed to compact box $boxName: $e', null, null);
      }

      // Copy the box file to backup location
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetFile.path);
      } else {
        logger.log(
          'Source file does not exist for $boxName at ${sourceFile.path}',
          null,
          null,
        );
      }
    }

    return '${context.l10n!.backedupSuccess}!';
  } catch (e, stackTrace) {
    logger.log('Backup error', e, stackTrace);
    return '${context.l10n!.backupError}: $e';
  }
}

Future<String> restoreData(BuildContext context) async {
  final boxNames = ['user', 'settings'];
  final result = await FilePicker.platform.pickFiles(allowMultiple: true);

  if (result == null || result.files.isEmpty) {
    return '${context.l10n!.chooseBackupFiles}!';
  }

  try {
    // Close all boxes before restoring to avoid conflicts
    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        try {
          await Hive.box(boxName).close();
        } catch (e) {
          logger.log('Failed to close box $boxName: $e', null, null);
        }
      }
    }

    // Small delay to ensure boxes are properly closed
    await Future.delayed(const Duration(milliseconds: 100));

    for (final boxName in boxNames) {
      final backupFile = result.files
          .where(
            (file) =>
                file.name == '$boxName.hive' ||
                file.name.startsWith('${boxName}_'),
          )
          .firstOrNull;

      if (backupFile?.path != null) {
        final sourceFile = File(backupFile!.path!);

        if (await sourceFile.exists()) {
          try {
            // Get the original box path by temporarily opening the box
            final tempBox = await Hive.openBox(boxName);
            final boxPath = tempBox.path;
            await tempBox.close();

            if (boxPath != null) {
              final targetFile = File(boxPath);

              // Ensure target directory exists
              await targetFile.parent.create(recursive: true);

              // Delete existing file if it exists
              if (await targetFile.exists()) {
                try {
                  await targetFile.delete();
                } catch (e) {
                  logger.log('Failed to delete existing file: $e', null, null);
                }
              }

              // Copy backup file to original location
              await sourceFile.copy(targetFile.path);
              logger.log(
                'Restored $boxName from ${sourceFile.path} to ${targetFile.path}',
                null,
                null,
              );
            }
          } catch (e) {
            logger.log('Failed to restore $boxName: $e', null, null);
          }
        } else {
          logger.log(
            'Backup file does not exist: ${sourceFile.path}',
            null,
            null,
          );
        }
      } else {
        logger.log(
          'Backup file for $boxName not found in selection',
          null,
          null,
        );
      }
    }

    // Small delay before reopening boxes
    await Future.delayed(const Duration(milliseconds: 100));

    // Reopen boxes after restore
    for (final boxName in boxNames) {
      try {
        await _openBox(boxName);
      } catch (e) {
        logger.log('Failed to reopen box $boxName: $e', null, null);
      }
    }

    return '${context.l10n!.restoredSuccess}!';
  } catch (e, stackTrace) {
    logger.log('Restore error', e, stackTrace);
    return '${context.l10n!.restoreError}: $e';
  }
}
