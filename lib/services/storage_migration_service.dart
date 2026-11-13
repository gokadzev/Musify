// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/services/io_service.dart';
import 'package:path/path.dart' as p;

/// Names passed to Hive.openBox. Verify with: grep -rn "openBox(" lib
const _boxNames = ['settings', 'user', 'userNoBackup', 'cache'];
const _markerName = '.storage_migrated';

Future<bool> needsStorageMigration(String newDir) async =>
    !await File(p.join(newDir, _markerName)).exists();

/// Step 1: run BEFORE Hive.init. Moves the box files from the old folder.
Future<void> migrateLegacyBoxFiles({
  required String oldDir,
  required String newDir,
}) async {
  if (p.equals(oldDir, newDir)) return;
  await Directory(newDir).create(recursive: true);

  for (final name in _boxNames) {
    // Hive stores box files under the lower-cased name.
    final fileName = '${name.toLowerCase()}.hive';
    final source = File(p.join(oldDir, fileName));
    final target = File(p.join(newDir, fileName));
    try {
      if (!await source.exists()) continue;
      if (await target.exists()) {
        // Never overwrite: the old file stays in place for manual recovery.
        logger.log('Storage migration: $fileName exists in both places');
        continue;
      }
      await _moveFile(source, target);
    } catch (e, stackTrace) {
      logger.log(
        'Storage migration: could not move $fileName',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Step 2: run AFTER the boxes are open. Moves each offline song's files to
/// the new location and rewrites the absolute paths stored in the entry.
/// Only files that Musify recorded are touched, which matters on desktop
/// where the old folder is the user's whole Documents directory.
Future<void> migrateOfflineSongFiles() async {
  final box = Hive.box('userNoBackup');
  final raw = box.get('offlineSongs');
  if (raw is! List || raw.isEmpty) return;

  var changed = false;
  final updated = <dynamic>[];
  for (final item in raw) {
    if (item is! Map) {
      updated.add(item);
      continue;
    }
    final song = Map<String, dynamic>.from(item);
    final ytid = song['ytid']?.toString() ?? '';
    if (ytid.isNotEmpty) {
      changed |= await _relocate(
        song,
        'audioPath',
        FilePaths.getAudioPath(ytid),
      );
      changed |= await _relocate(
        song,
        'artworkPath',
        FilePaths.getArtworkPath(ytid),
      );
    }
    updated.add(song);
  }
  if (changed) await box.put('offlineSongs', updated);
}

Future<void> markStorageMigrated(String newDir) =>
    File(p.join(newDir, _markerName))
        .writeAsString(DateTime.now().toIso8601String());

Future<bool> _relocate(
  Map<String, dynamic> song,
  String key,
  String target,
) async {
  final current = song[key]?.toString();
  if (current == null || current.isEmpty || p.equals(current, target)) {
    return false;
  }
  try {
    final destination = File(target);
    if (await destination.exists()) {
      song[key] = target; // already moved by an earlier, interrupted run
      return true;
    }
    final source = File(current);
    if (!await source.exists()) return false; // nothing to recover
    await destination.parent.create(recursive: true);
    await _moveFile(source, destination);
    song[key] = target;
    return true;
  } catch (e, stackTrace) {
    logger.log(
      'Storage migration: could not move $current',
      error: e,
      stackTrace: stackTrace,
    );
    return false;
  }
}

Future<void> _moveFile(File source, File target) async {
  try {
    await source.rename(target.path);
  } on FileSystemException {
    await source.copy(target.path);
    await source.delete();
  }
}
