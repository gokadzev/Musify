import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Paths

String? downloadDirectory = Hive.box('settings').get('downloadPath');

// Preferences

final prefferedFileExtension = ValueNotifier<String>(
  Hive.box('settings').get('audioFileType', defaultValue: 'mp3') as String,
);

final playNextSongAutomatically = ValueNotifier<bool>(
  Hive.box('settings').get('playNextSongAutomatically', defaultValue: false),
);

final useSystemColor = ValueNotifier<bool>(
  Hive.box('settings').get('useSystemColor', defaultValue: true),
);

final foregroundService = ValueNotifier<bool>(
  Hive.box('settings').get('foregroundService', defaultValue: false) as bool,
);

// Non-Storage Notifiers

final shuffleNotifier = ValueNotifier<bool>(false);
final repeatNotifier = ValueNotifier<bool>(false);
final muteNotifier = ValueNotifier<bool>(false);
