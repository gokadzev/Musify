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

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Builds the message shown when the desktop audio engine cannot start.
///
/// libmpv is a runtime dependency that is deliberately not bundled with the
/// Linux tarball, so make the fix explicit instead of surfacing a raw error.
String desktopAudioErrorMessage(Object error) {
  final details = error.toString();
  if (details.toLowerCase().contains('libmpv')) {
    return 'Musify could not start playback because libmpv is not installed.\n\n'
        'Install the libmpv runtime library and restart Musify:\n'
        '  Fedora:         sudo dnf install mpv-libs\n'
        '  Debian/Ubuntu:  sudo apt install libmpv2 (libmpv1 on older releases)\n'
        '  Arch:           sudo pacman -S mpv\n\n'
        'Details: $details';
  }
  return 'Musify could not start the audio engine.\n\n$details';
}

/// Shown instead of the app when initialization fails before the router and
/// localization are available. Intentionally self-contained and English-only.
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  static const Color _seedColor = Color(0xFF4F6BED);

  Future<void> _copyDetails(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error details copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _seedColor),
      darkTheme: ThemeData(
        colorSchemeSeed: _seedColor,
        brightness: Brightness.dark,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Musify could not start',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        widget.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _copyDetails(context),
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy details'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => exit(0),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Quit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hive boxes written by previous desktop builds.
const List<String> legacyDesktopBoxNames = [
  'settings',
  'user',
  'userNoBackup',
  'cache',
];

/// Download directories written by previous desktop builds.
const List<String> legacyDesktopDataDirs = ['tracks', 'artworks'];

/// Whether [directory] contains a Hive box written by an older desktop build.
///
/// Downloads are only migrated when this is true, so an unrelated documents
/// folder is left untouched.
Future<bool> hasLegacyDesktopHiveBoxes(Directory directory) async {
  for (final box in legacyDesktopBoxNames) {
    final file = File('${directory.path}${Platform.pathSeparator}$box.hive');
    if (await file.exists()) return true;
  }
  return false;
}

/// Outcome of [migrateLegacyDesktopData].
class DesktopDataMigration {
  const DesktopDataMigration({
    this.moved = const [],
    this.skipped = const [],
    this.failed = const [],
  });

  final List<String> moved;
  final List<String> skipped;
  final List<String> failed;

  bool get hasWork =>
      moved.isNotEmpty || skipped.isNotEmpty || failed.isNotEmpty;

  String describe() {
    final parts = <String>[];
    if (moved.isNotEmpty) parts.add('moved ${moved.join(', ')}');
    if (skipped.isNotEmpty) parts.add('kept existing ${skipped.join(', ')}');
    if (failed.isNotEmpty) parts.add('failed ${failed.join(', ')}');
    return parts.isEmpty ? 'nothing to migrate' : parts.join('; ');
  }
}

/// Moves Hive boxes and downloaded media from the legacy document directory
/// into [to]. Existing files in [to] win, so this is safe to run on every
/// start and never overwrites newer data.
Future<DesktopDataMigration> migrateLegacyDesktopData({
  required Directory from,
  required Directory to,
  void Function(String message, {Object? error, StackTrace? stackTrace})? log,
}) async {
  final moved = <String>[];
  final skipped = <String>[];
  final failed = <String>[];

  if (from.absolute.path == to.absolute.path || !await from.exists()) {
    return DesktopDataMigration(moved: moved, skipped: skipped, failed: failed);
  }

  await to.create(recursive: true);
  final canMigrateDownloads = await hasLegacyDesktopHiveBoxes(from);

  for (final box in legacyDesktopBoxNames) {
    for (final extension in const ['.hive', '.lock']) {
      final name = '$box$extension';
      final source = File('${from.path}${Platform.pathSeparator}$name');
      if (!await source.exists()) continue;

      final target = File('${to.path}${Platform.pathSeparator}$name');
      if (await target.exists()) {
        skipped.add(name);
        continue;
      }

      try {
        await _moveFile(source, target);
        moved.add(name);
      } catch (e, stackTrace) {
        failed.add(name);
        log?.call('Failed to migrate $name', error: e, stackTrace: stackTrace);
      }
    }
  }

  for (final name in legacyDesktopDataDirs) {
    final source = Directory('${from.path}${Platform.pathSeparator}$name');
    if (!await source.exists()) continue;

    if (!canMigrateDownloads) {
      log?.call(
        'Leaving $name in the documents directory: no legacy Hive box found',
      );
      continue;
    }

    final target = Directory('${to.path}${Platform.pathSeparator}$name');
    try {
      final result = await _moveDirectoryContents(
        source: source,
        target: target,
      );
      if (result.moved > 0) moved.add('$name/ (${result.moved} files)');
      if (result.skipped > 0) skipped.add('$name/ (${result.skipped} files)');
    } catch (e, stackTrace) {
      failed.add('$name/');
      log?.call(
        'Failed to migrate $name directory',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  return DesktopDataMigration(moved: moved, skipped: skipped, failed: failed);
}

Future<void> _moveFile(File source, File target) async {
  try {
    await source.rename(target.path);
  } on FileSystemException {
    // Fall back to copy + delete when source and target live on different
    // filesystems (rename cannot cross device boundaries).
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    await source.delete();
  }
}

Future<({int moved, int skipped})> _moveDirectoryContents({
  required Directory source,
  required Directory target,
}) async {
  await target.create(recursive: true);
  var moved = 0;
  var skipped = 0;

  await for (final entity in source.list(followLinks: false)) {
    final name = entity.path.substring(
      entity.path.lastIndexOf(Platform.pathSeparator) + 1,
    );
    final destination = '${target.path}${Platform.pathSeparator}$name';

    if (entity is File) {
      final targetFile = File(destination);
      if (await targetFile.exists()) {
        skipped++;
        continue;
      }
      await _moveFile(entity, targetFile);
      moved++;
    } else if (entity is Directory) {
      final result = await _moveDirectoryContents(
        source: entity,
        target: Directory(destination),
      );
      moved += result.moved;
      skipped += result.skipped;
      await _deleteIfEmpty(entity);
    }
  }

  await _deleteIfEmpty(source);
  return (moved: moved, skipped: skipped);
}

Future<void> _deleteIfEmpty(Directory directory) async {
  try {
    if (await directory.list().isEmpty) {
      await directory.delete();
    }
  } on FileSystemException {
    // Not empty or already gone; leave it in place.
  }
}
