import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

final outputFile =
    File('./lib/src/reverse_engineering/challenges/ejs/ejs_modules.g.dart');
final releaseUrl =
    Uri.parse('https://api.github.com/repos/yt-dlp/ejs/releases/latest');

final assets = [
  'yt.solver.core.min.js',
  'yt.solver.lib.min.js',
];

bool checkUpdate(String lastVer) {
  if (!outputFile.existsSync()) {
    return true;
  }
  try {
    final current = outputFile.readAsStringSync().split('\n')[1].split('=')[1];
    return current != lastVer;
  } on Object {
    return true;
  }
}

Future<void> main() async {
  final releaseData = await http.get(releaseUrl);
  final releaseJson = json.decode(releaseData.body);
  final newVer = releaseJson['tag_name'];

  if (!checkUpdate(newVer)) {
    print('No update needed. Current version is up to date: $newVer');
    return;
  }

  print('Updating to version: ${releaseJson['tag_name']}');

  final coreModule =
      releaseJson['assets'].firstWhere((asset) => asset['name'] == assets[0]);
  final libModule =
      releaseJson['assets'].firstWhere((asset) => asset['name'] == assets[1]);

  final coreModuleUrl = coreModule['browser_download_url'];
  final libModuleUrl = libModule['browser_download_url'];

  final coreModuleReq = await http.get(Uri.parse(coreModuleUrl));
  final libModuleReq = await http.get(Uri.parse(libModuleUrl));

  final coreModuleHash = sha256.convert(coreModuleReq.bodyBytes).toString();
  final libModuleHash = sha256.convert(libModuleReq.bodyBytes).toString();

  final outContent = '''
// GENERATED FILE FROM 'bin/ejs_updater.dart' DO NOT EDIT MANUALLY
// VERSION=$newVer

const modules = {
  'lib': {
    'url': '$libModuleUrl',
    'hash': '$libModuleHash'
  },
  'core': {
    'url': '$coreModuleUrl',
    'hash': '$coreModuleHash'
  }
};
''';

  outputFile.writeAsStringSync(outContent);
  print('Done! Running formatter');
  Process.run('dart', ['format', outputFile.path]);
}
