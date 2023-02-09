import 'package:hive_flutter/hive_flutter.dart';

String? downloadDirectory = Hive.box('settings').get('downloadPath');
List<String> localSongsFolders = Hive.box('settings').get(
  'localSongsFolders',
  defaultValue: <String>[
    '/storage/emulated/0/Music',
  ],
);
