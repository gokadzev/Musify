# on_audio_query

[![Pub.dev](https://img.shields.io/pub/v/on_audio_query?color=9cf&label=Pub.dev&style=flat-square)](https://pub.dev/packages/on_audio_query)
[![Languages](https://img.shields.io/badge/Languages-Dart%20%7C%20Kotlin%20%7C%20Swift-9cf?&style=flat-square)]()
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20IOS%20%7C%20Web%20%7C%20Windows-9cf?&style=flat-square)](https://pub.dev/packages/on_audio_query/install)

`on_audio_query` is a [Flutter](https://flutter.dev/) Plugin used to query audios/songs 🎶 infos [title, artist, album, etc..] from device storage. <br>

## Help:

- **Docs: [Pub.dev](https://pub.dev/documentation/on_audio_query/latest/on_audio_query/OnAudioQuery-class.html)**
- **Any problem? [Issues](https://github.com/LucJosin/on_audio_query/issues)**
- **Any suggestion? [Pull request](https://github.com/LucJosin/on_audio_query/pulls)**

### Topics:

- [How to Install](#how-to-install)
- [Platforms](#platforms)
- [Overview](#overview)
- [Examples](#examples)
- [Gif Examples](#gif-examples)
- [License](#license)

## Platforms:

<!-- ✔️ | ❌ -->

### Query methods

| Methods           | Android | IOS  |
| ----------------- | :-----: | :--: |
| `queryAudios`     |  `✔️`   | `✔️` |
| `queryAlbums`     |  `✔️`   | `✔️` |
| `queryArtists`    |  `✔️`   | `✔️` |
| `queryPlaylists`  |  `✔️`   | `✔️` |
| `queryGenres`     |  `✔️`   | `✔️` |
| `queryArtwork`    |  `✔️`   | `✔️` |
| `queryDeviceInfo` |  `✔️`   | `✔️` |

### Observer methods

| Methods            | Android | IOS  |
| ------------------ | :-----: | :--: |
| `observeAudios`    |  `✔️`   | `✔️` |
| `observeAlbums`    |  `✔️`   | `✔️` |
| `observeArtists`   |  `✔️`   | `✔️` |
| `observePlaylists` |  `✔️`   | `✔️` |
| `observeGenres`    |  `✔️`   | `✔️` |

<!-- ### Query methods

| Methods           | Android | IOS  | Web  | Windows |
| ----------------- | :-----: | :--: | :--: | :-----: |
| `queryAudios`     |  `✔️`   | `✔️` | `✔️` |  `✔️`   |
| `queryAlbums`     |  `✔️`   | `✔️` | `✔️` |  `✔️`   |
| `queryArtists`    |  `✔️`   | `✔️` | `✔️` |  `✔️`   |
| `queryPlaylists`  |  `✔️`   | `✔️` | `❌` |  `❌`   |
| `queryGenres`     |  `✔️`   | `✔️` | `✔️` |  `✔️`   |
| `queryArtwork`    |  `✔️`   | `✔️` | `❌` |  `❌`   |
| `queryDeviceInfo` |  `✔️`   | `✔️` | `❌` |  `❌`   |

### Observer methods

| Methods            | Android | IOS  | Web  | Windows |
| ------------------ | :-----: | :--: | :--: | :-----: |
| `observeAudios`    |  `✔️`   | `✔️` | `❌` |  `✔️`   |
| `observeAlbums`    |  `✔️`   | `✔️` | `❌` |  `✔️`   |
| `observeArtists`   |  `✔️`   | `✔️` | `❌` |  `✔️`   |
| `observePlaylists` |  `✔️`   | `✔️` | `❌` |  `❌`   |
| `observeGenres`    |  `✔️`   | `✔️` | `❌` |  `✔️`   | -->

✔️ -> Supported <br>
❌ -> Not Supported <br>

**[See all platforms methods support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)**

## How to Install:

Add the following code to your `pubspec.yaml`:

```yaml
dependencies:
  on_audio_query: 3.0.0-beta.0
```

### Request Permission:

#### Android:

To use this plugin add the following code to your `AndroidManifest.xml`

```xml
<manifest> ...

  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

</manifest>
```

#### IOS:

To use this plugin add the following code to your `Info.plist`

```
	<key>NSAppleMusicUsageDescription</key>
	<string>..Add a reason..</string>
```

<!-- #### Web/Assets:

Since Web Browsers **don't** offer direct access to their user's `file system`, this plugin will use the `assets` folder to "query" the audios files. So, will totally depend of the `developer`.

```yaml
# You don't need add every audio file path, just define the folder.
assets:
  - assets/
  # If your files are in another folder inside the `assets`:
  - assets/audios/
  # - assets/audios/animals/
  # - assets/audios/animals/cat/
  # ...
``` -->

## Some Features:

- Optional and Built-in storage `READ` and `WRITE` permission request
- Get all audios/songs.
- Get all albums and album-specific audios.
- Get all artists and artist-specific audios.
- Get all playlists and playlists-specific audios.
- Get all genres and genres-specific audios.
- Get all query methods with specific `keys` [Search].
- Create/Delete/Rename playlists.
- Add/Remove/Move specific audios to playlists.
- Specific sort types for all query methods.

## Overview:

All types of methods on this plugin:

### Query methods

| Methods                            | Parameters                 | Return                |
| ---------------------------------- | -------------------------- | --------------------- |
| [`queryAudios`](#query-methods)    | `(MediaFilter, isAsset)`   | `List<AudioModel>`    |
| [`queryAlbums`](#query-methods)    | `(MediaFilter, isAsset)`   | `List<AlbumModel>`    |
| [`queryArtists`](#query-methods)   | `(MediaFilter, isAsset)`   | `List<ArtistModel>`   |
| [`queryPlaylists`](#query-methods) | `(MediaFilter, isAsset)`   | `List<PlaylistModel>` |
| [`queryGenres`](#query-methods)    | `(MediaFilter, isAsset)`   | `List<GenreModel>`    |
| [`queryArtwork`](#queryartwork)    | `(id, type, format, size)` | `Uint8List?`          |

### Observer methods

| Methods                | Parameters      | Return                |
| ---------------------- | --------------- | --------------------- |
| [`observeAudios`]()    | `(MediaFilter)` | `List<AudioModel>`    |
| [`observeAlbums`]()    | `(MediaFilter)` | `List<AlbumModel>`    |
| [`observeArtists`]()   | `(MediaFilter)` | `List<ArtistModel>`   |
| [`observePlaylists`]() | `(MediaFilter)` | `List<PlaylistModel>` |
| [`observeGenres`]()    | `(MediaFilter)` | `List<GenreModel>`    |

### Playlist methods

| Methods                  | Parameters               | Return |
| ------------------------ | ------------------------ | ------ |
| [`createPlaylist`]()     | `(playlistName)`         | `int`  |
| [`removePlaylist`]()     | `(playlistId)`           | `bool` |
| [`addToPlaylist`]()      | `(playlistId, audioId)`  | `bool` |
| [`removeFromPlaylist`]() | `(playlistId, audioId)`  | `bool` |
| [`renamePlaylist`]()     | `(playlistId, newName)`  | `bool` |
| [`moveItemTo`]()         | `(playlistId, from, to)` | `bool` |

### Permissions/Device methods

| Methods                  | Parameters       | Return        |
| ------------------------ | ---------------- | ------------- |
| [`permissionsRequest`]() | `(retryRequest)` | `bool`        |
| [`permissionsStatus`]()  |                  | `bool`        |
| [`queryDeviceInfo`]()    |                  | `DeviceModel` |

### Others methods

| Methods                   | Parameters | Return           |
| ------------------------- | ---------- | ---------------- |
| [`scanMedia`](#scanmedia) | `(path)`   | `bool`           |
| [`observersStatus`]()     |            | `ObserversModel` |

### Artwork Widget

```dart
  Widget someOtherName() async {
    return QueryArtworkWidget(
      id: <audioId>,
      type: ArtworkType.AUDIO,
    );
  }
```

**See more: [QueryArtworkWidget](https://pub.dev/documentation/on_audio_query/latest/on_audio_query/QueryArtworkWidget-class.html)**

## Examples:

#### OnAudioQuery

```dart
final OnAudioQuery _audioQuery = OnAudioQuery();
```

#### Query methods:

- queryAudios();
- queryAlbums();
- queryArtists();
- queryPlaylists();
- queryGenres().

```dart
  someName() async {
    // Query Audios
    List<AudioModel> audios = await _audioQuery.queryAudios();

    // Query Albums
    List<AlbumModel> albums = await _audioQuery.queryAlbums();
  }
```

#### scanMedia

You'll use this method when updating a media from storage. This method will update the media 'state' and
Android `MediaStore` will be able to know this 'state'.

```dart
  someName() async {
    OnAudioQuery _audioQuery = OnAudioQuery();
    File file = File('path');
    try {
      if (file.existsSync()) {
        file.deleteSync();
        _audioQuery.scanMedia(file.path); // Scan the media 'path'
      }
    } catch (e) {
      debugPrint('$e');
    }
  }
```

#### queryArtwork

```dart
  someName() async {
    // DEFAULT: ArtworkFormat.JPEG, 200 and false
    Uint8List something = await _audioQuery.queryArtwork(
        <audioId>,
        ArtworkType.AUDIO,
        ...,
      );
  }
```

Or you can use a basic and custom Widget.
**See example [QueryArtworkWidget](#artwork-widget)**

## Gif Examples:

| <img src="https://user-images.githubusercontent.com/76869974/129740857-33f38b27-06a3-4959-bb31-2ae97d6b66ff.gif"/> | <img src="https://user-images.githubusercontent.com/76869974/129741012-1215b292-d700-466f-9c41-552df0ad5e89.gif"/> | <img src="https://user-images.githubusercontent.com/76869974/129741188-e6803432-24d7-4e39-bfde-cc6765e13663.gif"/> | <img src="https://user-images.githubusercontent.com/76869974/129741151-b820edc9-ddbf-4446-b67a-6e254cb5a46d.gif"/> |
| :----------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------------: |
| <img src="https://user-images.githubusercontent.com/76869974/129763885-c0cb3871-39af-45fa-aebf-ebf4113effa2.gif"/> | <img src="https://user-images.githubusercontent.com/76869974/129763519-497cab72-6a95-42fd-8237-3f83e954ea50.gif"/> | <img src="https://user-images.githubusercontent.com/76869974/129763577-9037d16f-f940-4bcb-ba37-879a0eecf2ac.gif"/> | <img src="https://user-images.githubusercontent.com/76869974/129763551-726512a9-bc10-4c75-a167-8928f0c0c212.gif"/> |
|                                                       Audios                                                       |                                                       Albums                                                       |                                                     Playlists                                                      |                                                      Artists                                                       |

## LICENSE:

- [LICENSE](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/LICENSE)

> - [Back to top](#on_audio_query)
