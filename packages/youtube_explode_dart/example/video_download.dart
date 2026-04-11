//TODO: Fixing the console printing.

import 'dart:async';
import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Initialize the YoutubeExplode instance.
final yt = YoutubeExplode();

Future<void> main() async {
  stdout.writeln('Type the video id or url: ');

  final url = stdin.readLineSync()!.trim();

  // Save the video to the download directory.
  Directory('downloads').createSync();

  // Download the video.
  await download(url);

  yt.close();
  exit(0);
}

Future<void> download(String id) async {
  // Get video metadata.
  final video = await yt.videos.get(id);

  // Get the video manifest.
  final manifest = await yt.videos.streamsClient.getManifest(id);
  final streams = manifest.audioOnly;

  // Get the audio track with the highest bitrate.
  final audio = streams.withHighestBitrate();
  final audioStream = yt.videos.streamsClient.get(audio);

  // Compose the file name removing the unallowed characters in windows.
  final fileName = '${video.title}.${audio.container.name}'
      .replaceAll(r'\', '')
      .replaceAll('/', '')
      .replaceAll('*', '')
      .replaceAll('?', '')
      .replaceAll('"', '')
      .replaceAll('<', '')
      .replaceAll('>', '')
      .replaceAll(':', '')
      .replaceAll('|', '');
  final file = File('downloads/$fileName');

  // Delete the file if exists.
  if (file.existsSync()) {
    file.deleteSync();
  }

  // Open the file in writeAppend.
  final output = file.openWrite(mode: FileMode.writeOnlyAppend);

  // Track the file download status.
  final len = audio.size.totalBytes;
  var count = 0;

  // Create the message and set the cursor position.
  final msg = 'Downloading ${video.title}.${audio.container.name}';
  stdout.writeln(msg);

  // Listen for data received.
  await for (final data in audioStream) {
    // Keep track of the current downloaded data.
    count += data.length;

    // Calculate the current progress.
    final progress = ((count / len) * 100).ceil();

    print(progress.toStringAsFixed(2));

    // Write to file.
    output.add(data);
  }
  await output.close();
}
