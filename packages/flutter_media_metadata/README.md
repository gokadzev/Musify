# [flutter_media_metadata](https://github.com/alexmercerind/flutter_media_metadata)
#### A Flutter plugin to read 🔖 metadata of 🎵 media files.

## Install

Add in your `pubspec.yaml`.

```yaml
dependencies:
  ...
  flutter_media_metadata: ^1.0.0
```

<img width="649" src="https://user-images.githubusercontent.com/28951144/151707391-a59bd40a-5303-4dd8-af35-ff8918894dbb.png">

_Example app running on Windows._

## Support

[![Support via PayPal](https://cdn.rawgit.com/twolfson/paypal-github-button/1.0.0/dist/button.svg)](https://www.paypal.me/alexmercerind)

<a href="https://www.buymeacoffee.com/alexmercerind" target="_blank"><img width="217" height="60" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" ></a>

Please consider buying me a coffee if you like the plugin.

## Documentation

#### Windows, Linux, macOS, Android & iOS

```dart
final metadata = await MetadataRetriever.fromFile(File(filePath));

String? trackName = metadata.trackName;
List<String>? trackArtistNames = metadata.trackArtistNames;
String? albumName = metadata.albumName;
String? albumArtistName = metadata.albumArtistName;
int? trackNumber = metadata.trackNumber;
int? albumLength = metadata.albumLength;
int? year = metadata.year;
String? genre = metadata.genre;
String? authorName = metadata.authorName;
String? writerName = metadata.writerName;
int? discNumber = metadata.discNumber;
String? mimeType = metadata.mimeType;
int? trackDuration = metadata.trackDuration;
int? bitrate = metadata.bitrate;
Uint8List? albumArt = metadata.albumArt;
```

#### Web

For using the plugin on web, add following line to your `index.html`.

```diff
   <link rel="manifest" href="manifest.json">
 </head>
 <body>
+  <script type="text/javascript" src="https://unpkg.com/mediainfo.js/dist/mediainfo.min.js"></script>
   <!-- This script installs service_worker.js to provide PWA functionality to
        application. For more information, see:
        https://developers.google.com/web/fundamentals/primers/service-workers -->
   <script>
     var serviceWorkerVersion = null;
     var scriptLoaded = false;
```

And use `MetadataRetriever.fromBytes` instead of `MetadataRetriever.fromFile`.


## Platforms

|Platform|Status   |Author/Maintainer                                             |                                                  
|--------|---------|--------------------------------------------------------------|
|Windows |✔️        |[Hitesh Kumar Saini](https://github.com/alexmercerind)        |
|Linux   |✔️        |[Hitesh Kumar Saini](https://github.com/alexmercerind)        |
|Android |✔️        |[Hitesh Kumar Saini](https://github.com/alexmercerind)        |
|Web     |✔️        |[Hitesh Kumar Saini](https://github.com/alexmercerind)        |
|MacOS   |✔️        |[@DiscombobulatedDrag](https://github.com/DiscombobulatedDrag)|
|iOS     |✔️        |[@DiscombobulatedDrag](https://github.com/DiscombobulatedDrag)|


<img width="555" src="https://user-images.githubusercontent.com/28951144/151707427-76d75f04-9efe-4b1d-80fb-fdeea73dad26.png">

_Example app running on Web._

<img width="200" src="https://user-images.githubusercontent.com/28951144/151707533-198ba2ca-d646-4bc4-811b-928f65ee03ea.png">

_Example app running on Android._

<img width="555" src="https://user-images.githubusercontent.com/28951144/151707526-319ca3f5-9849-4d57-8ea4-9595ee67e99c.png">

_Example app running on Linux._


## License 

This library & work under this repository is MIT licensed.

Copyright (c) 2021-2022 Hitesh Kumar Saini <saini123hitesh@gmail.com>
