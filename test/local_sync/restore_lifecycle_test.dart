import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/services/data_manager.dart';

final class MemoryFile extends PlatformFile {
  MemoryFile(this.name, this.data);
  @override
  final String name;
  final Uint8List data;
  @override
  Uri get uri => Uri.parse('memory:///$name');
  @override
  Never get xFile => throw UnimplementedError();
  @override
  int? lengthSync() => data.length;
  @override
  Future<int?> length() async => data.length;
  @override
  Future<Uint8List> readAsBytes() async => data;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(data);
}

class FakePicker extends FilePickerPlatform {
  FakePicker(this.files);
  final List<PlatformFile> files;
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => files;
}

void main() {
  late Directory dir;
  late FilePickerPlatform originalPicker;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('restore_changed_test');
    Hive.init(dir.path);
    await Hive.openBox('user');
    await Hive.openBox('settings');
    await Hive.box('user').put('likedSongs', ['original']);
    originalPicker = FilePickerPlatform.instance;
  });
  tearDown(() async {
    restoreFault = null;
    FilePickerPlatform.instance = originalPicker;
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<BuildContext> contextFor(WidgetTester tester) async {
    late BuildContext result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            result = context;
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('a cancelled picker leaves the storage-change flag untouched', (
    tester,
  ) async {
    FilePickerPlatform.instance = FakePicker([]);
    final context = await contextFor(tester);
    var changed = false;
    final result = await restoreData(
      context,
      onStorageChanged: (value) => changed = value,
    );
    expect(result.success, isFalse);
    expect(changed, isFalse);
    expect(Hive.box('user').get('likedSongs'), ['original']);
  });

  testWidgets('a successful restore reports changed storage', (tester) async {
    await tester.runAsync(() async {
      final sourceUser = await Hive.openBox('sourceuser');
      await sourceUser.put('likedSongs', ['restored']);
      await sourceUser.flush();
      final userBytes = await File(sourceUser.path!).readAsBytes();
      final sourceSettings = await Hive.openBox('sourcesettings');
      await sourceSettings.put('theme', 'dark');
      await sourceSettings.flush();
      final settingsBytes = await File(sourceSettings.path!).readAsBytes();
      FilePickerPlatform.instance = FakePicker([
        MemoryFile('user.hive', userBytes),
        MemoryFile('settings.hive', settingsBytes),
      ]);
    });
    final context = await contextFor(tester);
    var changed = false;
    final result = await tester.runAsync(
      () => restoreData(context, onStorageChanged: (value) => changed = value),
    );
    expect(result!.success, isTrue);
    expect(changed, isTrue);
    expect(Hive.box('user').get('likedSongs'), ['restored']);
  });
  for (final failRollback in [false, true]) {
    testWidgets(
      'a failed restore reports whether rollback failed: $failRollback',
      (tester) async {
        await tester.runAsync(() async {
          final sourceUser = await Hive.openBox('sourceuser');
          await sourceUser.put('likedSongs', ['restored']);
          await sourceUser.flush();
          final sourceSettings = await Hive.openBox('sourcesettings');
          await sourceSettings.put('theme', 'dark');
          await sourceSettings.flush();
          FilePickerPlatform.instance = FakePicker([
            MemoryFile('user.hive', await File(sourceUser.path!).readAsBytes()),
            MemoryFile(
              'settings.hive',
              await File(sourceSettings.path!).readAsBytes(),
            ),
          ]);
        });
        final context = await contextFor(tester);
        var changed = false;
        restoreFault = (stage) async {
          if (stage == 'restored:user' ||
              (failRollback && stage == 'rollback:user')) {
            throw StateError(stage);
          }
        };
        final result = await tester.runAsync(
          () => restoreData(
            context,
            onStorageChanged: (value) => changed = value,
          ),
        );
        expect(result!.success, isFalse);
        expect(changed, failRollback);
        expect(Hive.box('user').get('likedSongs'), [
          if (failRollback) 'restored' else 'original',
        ]);
      },
    );
  }
}
