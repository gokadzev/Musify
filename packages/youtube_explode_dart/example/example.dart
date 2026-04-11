import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  final yt = YoutubeExplode();

  // Get the video metadata.
  final video = await yt.videos.get('fRh_vgS2dFE');
  print(video.title); // ^ You can pass both video URLs or video IDs.

  final manifest = await yt.videos.streams.getManifest('fRh_vgS2dFE',
      // You can also pass a list of preferred clients, otherwise the library will handle it:
      ytClients: [
        YoutubeApiClient.ios,
        YoutubeApiClient.androidVr,
      ]);

  // Print all the available streams.
  print(manifest);

  // Get the audio streams.
  final audio = manifest.audioOnly;

  // Download it
  final stream = yt.videos.streams.get(audio.first);
  // then pipe the stream to a file...

  // Or you can use the url to stream it directly.
  audio.first.url; // This is the audio stream url.

  // Make sure to handle the file extension properly. Especially m3u8 streams might require further processing.

  // Close the YoutubeExplode's http client.
  yt.close();
}
