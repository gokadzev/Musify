## [[2.9.0](https://github.com/LucJosin/on_audio_query/releases/tag/2.9.0)]

### Features

- **Added** support to Dart 3.

## [[2.8.1](https://github.com/LucJosin/on_audio_query/releases/tag/2.8.1)]

### Fixes

- **Fixed** broken pubspec links. - [#115](https://github.com/LucJosin/on_audio_query/issues/115)

#### iOS

- **Fixed** wrong name of podspec in iOS. - [#116](https://github.com/LucJosin/on_audio_query/issues/116)

### Changes

- **Updated** dart-analyzer to support cache
- **Updated** README

## [[2.8.0](https://github.com/LucJosin/on_audio_query/releases/tag/2.8.0)]

### Features

- **Added** `showDetailedLog`.

### Changes

- **Moved** `android` and `ios` into separated folders.
- **Replaced** `/details` with `/src`.

### ⚠ Important Changes

#### Android

- **Updated** kotlin version from `1.4.32` to `1.6.10`. - [#110](https://github.com/LucJosin/on_audio_query/issues/110)
- **Updated** kotlin coroutines version from `1.5.2-native-mt` to `1.6.4`.

## [[2.7.0](https://github.com/LucJosin/on_audio_query/releases/tag/2.7.0)] - [03.29.2023]

### Features

- **Added** `[LogType]`.
- **Added** `[LogConfig]`.
- **Added** `[PermissionController]` **(Native)**
- **Added** `[PluginProvider]` **(Native)**
- **Added** `[setLogConfig]` method.
- **Added** `[checkAndRequest]` method.
- **Added** `[controller]` to `[QueryArtworkWidget]`.
- **Added** `[retryRequest]` param to `[checkAndRequest]` and `[permissionsRequest]`.

### Fixes

#### Android

- **Fixed** crash after request permission. - [#68](https://github.com/LucJosin/on_audio_query/issues/68)
- **Fixed** quality always being sent as `200` using `[queryArtwork]`.

### Changes

- **Updated** example.
- **Renamed** natives files/folders.
- **Reduced** the default `artwork` resolution (from 100 to 50).
- **Updated** `[QueryArtworkWidget]` params.
- **Updated** quality assert on `[QueryArtworkWidget]`.

### ⚠ Important Changes

- **Updated** application permission check.
  - If application doesn't have permission to access the library, will throw a PlatformException.
- **Updated** `quality` param from `[QueryArtworkWidget]`.
  - This param cannot be defined as null anymore and, by default, will be set to `50`.
- **Updated** minimum supported **Dart** version.
  - Increase minimum version from `2.12` to `2.17`.

## [2.6.2] - [03.03.2023]

### Fixes

#### Android

- **Fixed** incompatibility with `Android 13`. - [#91](https://github.com/LucJosin/on_audio_query/issues/91) - Thanks [@ruchit-7span](https://github.com/ruchit-7span)

## [2.6.1] - [05.17.2022]

### Fixes

#### Android

- **Fixed** incompatibility with `Flutter 3`. - [#78](https://github.com/LucJosin/on_audio_query/issues/78)

## [2.6.0] - [02.01.2022]

### Features

- **Added** `[scanMedia]` method that will scan the given path and update the `[Android]` MediaStore.

### Fixes

- **Fixed** media showing when calling `[querySongs]` even after deleting with `[dart:io]`. - [#67](https://github.com/LucJosin/on_audio_query/issues/67)

### Changes

- **Updated** some required packages.

### Documentation

- Updated `README` documentation.
- Updated `DEPRECATED` documentation.
- Updated `PLATFORMS` documentation.
- Updated some `broken` links.

## [2.5.3+1] - [01.20.2022]

### Changes

- **Updated** all Github links.

## [2.5.3] - [11.10.2021]

### Fixes

#### IOS

- **Fixed** song/artist/album from `Apple Music` returning when 'querying' - [#61](https://github.com/LucJosin/on_audio_query/issues/61)
- **Fixed** wrong `artistId` returning from `[AlbumModel]` - [#60](https://github.com/LucJosin/on_audio_query/issues/60)

### Documentation

- Updated `README` documentation.

## [2.5.2] - [10.25.2021]

### Fixes

#### Android

- **Fixed** wrong value returning from: - [#56](https://github.com/LucJosin/on_audio_query/issues/56)
  - `[is_music]`.
  - `[is_alarm]`.
  - `[is_notification]`.
  - `[is_ringtone]`.
  - `[is_podcast]`.
  - `[is_audiobook]`.

### Documentation

- Updated `README` documentation.

## [2.5.1] - [10.19.2021]

### Fixes

#### Dart

- **Fixed** wrong value returning from `[artistId]` when using `[AlbumModel]`. - [#54](https://github.com/LucJosin/on_audio_query/issues/54)

#### Android

- **Fixed** missing songs from `[queryAudiosFrom]` when using `GENRE`. - [#46](https://github.com/LucJosin/on_audio_query/issues/46)

### Documentation

- Updated `README` documentation.

### ⚠ Important Changes

#### Dart

- Now `[artistId]` from `[AlbumModel]` return a `[int]`.

## [2.5.0] - [10.15.2021]

### Release

- `[2.5.0]` release.

### Features

#### Dart

- **Added** `errorBuilder` and `frameBuilder` to `[QueryArtworkWidget]`.

### Fixes

#### Web

- **Fixed** empty result when using `[querySongs]`.
- **Fixed** error when decoding some images.

See all development [changes](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/CHANGELOG.md):

- [2.5.0-alpha.0](#250-alpha0---10152021)

## [2.5.0-alpha.0] - [10.15.2021]

### Features

#### All platforms

- **Added** `artwork` to genres. - [#41](https://github.com/LucJosin/on_audio_query/issues/41)
- **Added** `sortType`, `orderType` and `ignoreCase` to `[queryAudiosFrom]`.

#### Android

- Re-**Added** `path` parameter to `[querySongs]`. - [#48](https://github.com/LucJosin/on_audio_query/issues/48)

#### Web

- **Added** `path` parameter to `[querySongs]`.

### Fixes

#### Android

- **Fixed** empty `Uint8List` when using `[queryArtwork]` on Android 7. - [#47](https://github.com/LucJosin/on_audio_query/issues/47)
- **Fixed** null `albumId` when using Android 9 or below. - [#53](https://github.com/LucJosin/on_audio_query/issues/53)

### Documentation

- Updated `README` documentation. New `[queryAudiosFrom]` section.
- Updated `DEPRECATED` documentation.

### Changes

- Downgraded `Kotlin` and `Gradle` version. - [#51](https://github.com/LucJosin/on_audio_query/issues/51)

### ⚠ Important Changes

#### @Deprecated

- `[albumId]` from `[AlbumModel]`.
  - Use `[id]` instead.

## [2.4.2] - [10.01.2021]

### Fixes

#### IOS

- **Fixed** no artwork returning from `[queryArtwork]` when using `ArtworkType.ALBUM`. - [#45](https://github.com/LucJosin/on_audio_query/issues/45)

### Documentation

- Updated `README` documentation.

## [2.4.1] - [09.29.2021]

### Fixes

#### Dart

- **Fixed** wrong type of `numOfSongs` from `[SongModel]`. - [#39](https://github.com/LucJosin/on_audio_query/issues/39)

#### IOS

- **Fixed** wrong filter configuration when using `[queryWithFilters]`.
- **Fixed** crash when using any `'query'` method with a null `sortType`. - [#43](https://github.com/LucJosin/on_audio_query/issues/43)
- **Fixed** error with wrong `[MPMediaQuery]` filter. - [#38](https://github.com/LucJosin/on_audio_query/issues/38)

### Documentation

- Updated `README` documentation.

## [2.4.0] - [09.28.2021]

### Features

#### Android

- **Added** a better 'search' method to `[queryWithFilters]`, now the query uses 'contains' when 'querying'. - [#35](https://github.com/LucJosin/on_audio_query/issues/35)

### Fixes

#### IOS

- **Fixed** error with wrong `[MPMediaQuery]` type and wrong value from `[jpegData]`. - [#37](https://github.com/LucJosin/on_audio_query/issues/37)

#### Documentation

- Updated broken `README` links. - [#36](https://github.com/LucJosin/on_audio_query/issues/36)

### Documentation

- Updated `README` documentation.

## [2.3.1] - [09.27.2021]

### Features

#### Android/Web

- **Added** `[ignoreCase]` to:
  - `[querySongs]`.
  - `[queryAlbums]`.
  - `[queryArtists]`.
  - `[queryPlaylists]`.
  - `[queryGenres]`.

### Fixes

#### Android

- **Fixed** `error` when trying to build using `Android`. - [#32](https://github.com/LucJosin/on_audio_query/issues/32) & [#33](https://github.com/LucJosin/on_audio_query/issues/33)
- **Fixed** `error` related to android song projection. - [#31](https://github.com/LucJosin/on_audio_query/issues/31)
- **Fixed** `'bug'` when using `SongSortType.TITLE`. This is now a `'feature'` and can be controlled using `[ignoreCase]`. - [#29](https://github.com/LucJosin/on_audio_query/issues/29)

### Documentation

- Updated `README` documentation.

### Changes

#### Android

- Updated `[Kotlin]` and `[Dependencies]` versions.
- Moved from `[JCenter]` to `[MavenCentral]`.

## [2.3.0] - [09.25.2021]

### Features

#### Android/IOS/Web

- **Added** `[numOfSongs]` to `[PlaylistModel]` and `[GenreModel]`.
- **Added** `Playlist` and `Artist` to `ArtworkType`.

#### Android/IOS

- **Added** `quality` to `queryArtwork`.

#### Android

- **Added** `[isAudioBook]`, `[Genre]` and `[GenreId]` to `[SongModel]`.
- Re-**Added** to `[SongModel]`:
  - `[isAlarm]`.
  - `[isMusic]`.
  - `[isNotification]`.
  - `[isPodcast]`.
  - `[isRingtone]`.

### Fixes

#### Android

- **Fixed** wrong value returning from `[id]` when using `[ArtistModel]`.
- **Fixed** wrong value returning from `[id]` when using `[GenreModel]`.
- **Fixed** no value returning from `[queryAudiosFrom]` when using `ARTIST_ID`.

### Documentation

- Updated `README` documentation.
- Updated `OnAudioQuery` and `OnAudioQueryExample` documentation to support new `[Flutter 2.5]`.

### Changes

- **[Changed]** wrong name `DATA_ADDED` to `DATE_ADDED` for both `[SongSortType]` and `[PlaylistSortType]`. - [#27](https://github.com/LucJosin/on_audio_query/issues/27)

### ⚠ Important Changes

#### Dart

- The parameter `args` from `[queryWithFilters]` is no longer required.

#### @Deprecated

- `[DEFAULT]` from `[SongSortType]`.
- `[DEFAULT]` from `[PlaylistSortType]`.
- `[DEFAULT]` from `[ArtistSortType]`.
- `[DEFAULT]` from `[AlbumSortType]`.
- `[DEFAULT]` from `[GenreSortType]`.
- `[ARTIST_KEY]` from `[ArtistSortType]`.
- `[ARTIST_NAME]` from `[ArtistSortType]`.
- `[ALBUM_NAME]` from `[AlbumSortType]`.
- `[GENRE_NAME]` from `[GenreSortType]`.
- `[DATA_ADDED]` from `[SongSortType]`.
- `[DATA_ADDED]` from `[PlaylistSortType]`.

<!-- Deleted files: [audios_only_type.dart] and [songs_by_type.dart] -->
<!-- Changed files: [queryArtworkWidget.dart] to [query_artwork_widget.dart] -->

## [2.2.0] - [08.25.2021]

### Features

#### IOS

- Added a `filter` to avoid cloud audios/songs.

### Fixes

#### IOS

- **Fixed** wrong value returning from `[permissionsStatus]`. - [#24](https://github.com/LucJosin/on_audio_query/issues/24)

### Documentation

- Updated `README` documentation.

## [2.1.2] - [08.24.2021]

### Fixes

#### Android

- **Fixed** duplicate `media` from `[queryWithFilters]`.
- **Fixed** `crash` when calling `[queryWithFilters]`. - [#23](https://github.com/LucJosin/on_audio_query/issues/23)
- **Fixed** `null` artwork returning from `[queryArtwork]` on Android 11/R. - [#21](https://github.com/LucJosin/on_audio_query/issues/21)

### Documentation

- Updated `README` documentation.
- Updated `pubspec` documentation.

## [2.1.1] - [08.23.2021]

### Fixes

#### Android

- **Fixed** error when using `[removeFromPlaylist]`. - [#22](https://github.com/LucJosin/on_audio_query/issues/22)

### Documentation

- Updated `README` documentation.
- Updated `[OnAudioQueryExample]` to support `[Web]` platform.

## [2.1.0] - [08.23.2021]

### Features

#### on_audio_query

- The plugin now supports `[Web]`.
- The plugin now utilize `[Platform interface]` package.

#### Web

- Added:
  - `[querySongs]`.
  - `[queryAlbums]`.
  - `[queryArtists]`.
  - `[queryGenres]`.
  - `[queryAudiosFrom]`.
  - `[queryWithFilters]`.
  - `[queryArtwork]`.
  - `[queryDeviceInfo]`.

### Documentation

- Updated `on_audio_query` documentation.
- Updated `README` documentation.
- Updated `PLATFORMS` documentation.
- Added documentation to `Web` platform.

## [2.0.0] - [08.17.2021]

### Release

- `[2.0.0]` release.

See all development [changes](https://github.com/LucJosin/on_audio_query/blob/main/CHANGELOG.md):

- [2.0.0-beta.3](#200-beta3---08172021---github-only)
- [2.0.0-beta.2](#200-beta2---08152021)
- [2.0.0-beta.1](#200-beta1---08142021)
- [2.0.0-beta.0](#200-beta0---08132021)
- [2.0.0-alpha.1](#200-alpha1---08082021---github-only)
- [2.0.0-alpha.0](#200-alpha0---08052021---github-only)
- [2.0.0-dev.1](#200-dev1---08052021---internal)
- [2.0.0-dev.0](#200-dev0---08022021---internal)

## [2.0.0-beta.3] - [08.17.2021] - [GitHub Only]

### Features

#### Android

- Now **ALL** methods will only `"query"` if has permission to `READ`.

### Fixes

#### Android

- **Fixed** no value returning when using `[permissionsRequest]`.

### Documentation

- Updated `README` documentation.
- Added more documentation to `Android` platform.

## [2.0.0-beta.2] - [08.15.2021]

### Features

#### IOS

- Now **ALL** methods will only `"query"` if has permission to `Library`.
- Added `[addToPlaylist]`.

#### Dart

- Added `[author]` and `[desc]` arguments to `[createPlaylist]`. **(IOS only)**

### Fixes

#### IOS

- **Fixed** crash when using `[queryArtwork]`.
- **Fixed** wrong `[id]` value returning from `[PlaylistModel]`.

### Documentation

- Updated `README` documentation.

## [2.0.0-beta.1] - [08.14.2021]

### Features

#### IOS

- Added `[queryArtwork]`.

### Fixes

#### Android

- **Fixed** `error` when building to `[Android]`.

#### IOS

- **Fixed** wrong `[duration]`, `[dateAdded]` and `[bookmark]` values returning from `[SongModel]`.

### Documentation

- Updated `on_audio_query` documentation.
- Updated `README` documentation.
- Updated `DEPRECATED` documentation.
- Added documentation to `IOS` platform.

### ⚠ Important Changes

#### @Deprecated

- `[artwork]` from `[QueryArtworkWidget]`.
- `[deviceSDK]` from `[QueryArtworkWidget]`.
- `[requestPermission]` from `[QueryArtworkWidget]`.

## [2.0.0-beta.0] - [08.13.2021]

### Features

#### on_audio_query

- Added a [`DART ANALYZER`](https://github.com/axel-op/dart-package-analyzer/) to `PULL_REQUEST` and `PUSH`.

### Documentation

- Updated `on_audio_query` documentation.
- Updated `README` documentation.
- Updated `DEPRECATED` documentation.
- Created [`PLATFORMS`](https://github.com/LucJosin/on_audio_query/blob/2.0.0-dev/PLATFORMS.md) file.

### ⚠ Important Changes

#### Dart

- Now **ALL** methods has `Named Optional` arguments.
- Changed `[queryArtworks]` to `[queryArtwork]`.

#### @Deprecated

- `[requestPermission]` argument from **ALL** methods.
- `[queryAudios]`.
- `[artwork]` from `[SongModel]`.
- `[path]` from `[querySongs]`.

## [2.0.0-alpha.1] - [08.08.2021] - [GitHub Only]

### Features

#### Dart

- Added `[artwork]` to `[PlaylistModel]` as `[Uint8List]`
- Added `[numOfTracks]` to `[PlaylistModel]`
- Added `[playlistAuthor]` and `[playlistDesc]` parameter to `[createPlaylist]` (IOS only)
- Added `[OnModelFormatter]` extension.
  - Added `[toSongModel]`.
  - Added `[toAlbumModel]`.
  - Added `[toPlaylistModel]`.
  - Added `[toArtistModel]`.
  - Added `[toGenreModel]`.

#### IOS

- Added `[queryWithFilters]` method.
- Added `[createPlaylist]` method.
- Added `[queryPlaylists]` method.
- Added `[queryAudiosFrom]` method.

### ⚠ Important Changes

#### Dart

- Now `[dateAdded]` from `[PlaylistModel]` return a `[int]`.
- Now `[dateModified]` from `[PlaylistModel]` return a `[int]`.

#### @Deprecated

- `[queryAudiosOnly]`
- `[AudiosOnlyType]`
- `[queryAudiosBy]`
- `[AudiosByType]`

### Dev Changes

#### Dart

- ~~Added checker to all `[int]` from `[PlaylistModel]`.~~
  - Temporary

## [2.0.0-alpha.0] - [08.05.2021] - [GitHub Only]

### Release

- `[2.0.0-alpha.0]` release.

## [2.0.0-dev.1] - [08.05.2021] - [Internal]

### Features

#### IOS

- Added `[queryArtists]` and `[queryGenres]`.

### ⚠ Important Changes

#### @Deprecated

- Removed `[artwork]` from `[ArtistModel]`.
- Removed `[artwork]` from `[GenreModel]`.

### Dev Changes

#### Dart

- ~~Added a checker to all int items from `[ArtistModel]`.~~
  - Temporary
- ~~Added a checker to all int items from `[GenreModel]`.~~
  - Temporary

## [2.0.0-dev.0] - [08.02.2021] - [Internal]

### Features

#### on_audio_query

- The plugin now supports `[IOS]`. **(Not 100%)**

#### IOS

- Added `[querySongs]` and `[queryAlbums]`.

#### Dart

- Added `[model]` to `[DeviceModel]`.

### Changes

#### Dart

- Now `[sdk]` are `[version]`.
- Now `[deviceType]` are `[type]`.

### ⚠ Important Changes

#### Dart

- Now `[artwork]` from `[SongModel]` return a `[Uint8list]`.
- ~~Now all `[int]` from `[SongModel]` can be `[null]`.~~
- Now `[artwork]` from `[AlbumModel]` return a `[Uint8list]`.

#### @**Deprecated**

- `[numOfSongsArtists]` from `[AlbumModel]`.
- `[maxyear]` from `[AlbumModel]`.
- `[minyear]` from `[AlbumModel]`.
- `[release]` from `[DeviceModel]`.
- `[code]` from `[DeviceModel]`.
- `[year]` from `[SongModel]`.
- `[is_alarm]` from `[SongModel]`.
- `[is_music]` from `[SongModel]`.
- `[is_notification]` from `[SongModel]`.
- `[is_ringtone]` from `[SongModel]`.
- `[is_podcast]` from `[SongModel]`.
- `[file_parent]` from `[SongModel]`.
- `[firstYear]` from `[AlbumModel]`.
- `[lastYear]` from `[AlbumModel]`.

### Dev Changes

#### Dart

- Now `[queryDeviceInfo]` will return Map instead of List.
- ~~Added a checker to all int items from `[SongModel]`.~~
  - Temporary.
- ~~Added a checker to all int items from `[AlbumModel]`.~~
  - Temporary.

## [1.2.0] - [07.30.2021]

### Features

- Added `[path]` parameter to `[querySongs]` and `[queryAudio]`.
- Added `[getMap]` to:
  - `[SongModel]`.
  - `[AlbumModel]`.
  - `[ArtistModel]`.
  - `[GenreModel]`.
  - `[PlaylistModel]`.
  - `[DeviceModel]`.

### Documentation

- Updated `README` documentation.

## [1.1.3+1] - [07.19.2021]

### Fixes

#### Android

- **Fixed** `[Kotlin]` issue when installing the plugin.

### Documentation

- Updated `README` documentation.

### Changes

#### Android

- Downgraded some `[Kotlin]` dependencies.

## [1.1.3] - [07.18.2021]

### Fixes

#### Android

- **Fixed** `[cursor]` problem when using `[AudiosFromType.GENRE_NAME]` or `[AudiosFromType.GENRE_ID]` on `[queryAudiosFrom]`. - [#16](https://github.com/LucJosin/on_audio_query/issues/16) and [#12](https://github.com/LucJosin/on_audio_query/issues/12)

### Documentation

- Updated `README` documentation.

### Changes

#### Android

- Updated some `[Kotlin]` dependencies.

## [1.1.2] - [07.07.2021]

### Fixes

#### Android

- ~~**Fixed** `[cursor]` problem when using `[AudiosFromType.GENRE_NAME]` or `[AudiosFromType.GENRE_ID]` on `[queryAudiosFrom]`.~~

### Documentation

- Updated `README` documentation.

## [1.1.1] - [06.23.2021]

### Features

#### Dart/Android

- Added `[uri]` to `[SongModel]`. - [Added #10](https://github.com/LucJosin/on_audio_query/issues/10)

### Fixes

#### Android

- **Fixed** `java.lang.Integer cannot be cast to java.lang.Long` from `[queryArtworks]`. - [#11](https://github.com/LucJosin/on_audio_query/issues/11)

### Documentation

- Updated `README` documentation.
- Created `DEPRECATED` file/history.

### Changes

#### Dart

- Changed from `[deviceInfo]` to `[deviceSDK]` on `[QueryArtworkWidget]`.

### ⚠ Important Changes

#### Dart

- Deprecated `[deviceInfo]` from `[QueryArtworkWidget]`.

## [1.1.0] - [06.03.2021]

### Features

#### Dart/Android

- Added `[queryDeviceInfo]`.
- Added `[dateModified]` to `[SongModel]`.
- Added `[querySongsBy]` and `[SongsByType]`.

### Fixes

#### Android

- **Fixed** incompatibility with `[permission_handler]`. - [#3](https://github.com/LucJosin/on_audio_query/issues/3) - Thanks [@mvanbeusekom](https://github.com/mvanbeusekom)

#### Dart

- **Fixed** wrong name. From `[dataAdded]` to `[dateAdded]`.

### Documentation

- Updated `README` documentation.
- Updated `[OnAudioQueryExample]` to add new `[queryDeviceInfo]` and `[QueryArtworkWidget]` methods.

### Changes

#### Android

- Updated some `[Kotlin]` dependencies.
- Changed some `[Kotlin]` methods.

### ⚠ Important Changes

#### Dart

- Now `[getDeviceSDK]`, `[getDeviceRelease]` and `[getDeviceCode]` are part of `[queryDeviceInfo]`.
- Now `[QueryArtworkWidget]` support Android above and below 29/Q/10.
- Now `[size]`, `[albumId]`, `[artistId]`, `[dataAdded]`, `[dataModified]`, `[duration]`, `[track]` and `[year]` from `[SongModel]` will return `[int]`.

## [1.0.8] - [05.19.2021]

### Features

#### Dart

- Added `[artworkClipBehavior]`, `[keepOldArtwork]`, `[repeat]` and `[scale]` to `[QueryArtworkWidget]`.
- Added comments to `[QueryArtworkWidget]`.

### Fixes

#### Android

- **Fixed** Now `[queryArtworks]` will return null. - [#6](https://github.com/LucJosin/on_audio_query/issues/6)

### Documentation

- Updated `README` documentation.

### ⚠ Important Changes

#### Dart

- Now `[queryArtworks]` return `[Uint8List?]`.

## [1.0.7] - [05.18.2021]

### Features

#### Dart/Android

- Added `[queryFromFolder]`.
- Added `[queryAllPath]`.
- Added `[_display_name_wo_ext]` (`[displayName]` without extension) to `[SongModel]`. - [Added #5](https://github.com/LucJosin/on_audio_query/issues/5)
- Added `[file_extension]` (Only file extension) to `[SongModel]`.
- Added `[file_parent]` (All the path before file) to `[SongModel]`.
- Added `[Genre]` to `[queryAudiosFrom]`.
- Added `[ALBUM_ID]`, `[ARTIST_ID]` and `[PLAYLIST_ID]` to `[AudiosFromType]`. - [Added #2](https://github.com/LucJosin/on_audio_query/issues/2)

### Documentation

- Updated `README` documentation.

### Changes

#### Dart/Android

- Now `[queryAudiosFrom]` supports `[name]` and `[id]`.
- Now `[albumId]` from `[AlbumModel]` return a `[int]`.

#### Android

- Now all `[Kotlin]` checks will throw a `[Exception]` if value don't exist.
- Updated some `[Kotlin]` dependencies.

### ⚠ Important Changes

#### Dart/Android

- Changed `[ALBUM]`, `[ARTIST]` and `[PLAYLIST]` to `[ALBUM_NAME]`, `[ARTIST_NAME]` and `[PLAYLIST_NAME]` in `[AudiosFromType]`.

## [1.0.6] - [04.08.2021]

### Fixes

#### Android

- **Fixed** `[queryArtwork]` returning null album image in Android 11. - [#1](https://github.com/LucJosin/on_audio_query/issues/1)

### Documentation

- Updated `README` documentation.

### Changes

#### Android

- Removed unnecessary code from `[WithFiltersType]`.
- Updated some `[Kotlin]` dependencies.

## [1.0.5] - [03.31.2021]

### Features

#### Dart/Android

- Added `[queryAudiosOnly]`.
- Added `[queryWithFilters]`.
- Added `[AudiosOnlyType]` and `[WithFiltersType]`.
- Added `[SongsArgs]`, `[AlbumsArgs]`, `[PlaylistsArgs]`, `[ArtistsArgs]`, `[GenresArgs]`.
- Added `[EXTERNAL]` and `[INTERNAL]` parameters for some query methods.

### Documentation

- Updated `README` documentation.

### Changes

#### Dart/Android

- Now `[querySongs]`, `[queryAlbums]`, `[queryArtists]`, `[queryPlaylists]` and `[queryGenres]` have `[UriType]` as parameter.

#### Android

- Updated some `[Kotlin]` dependencies.

## [1.0.3] - [03.28.2021]

### ⚠ Important Changes

#### Dart

- Migrate to null safety.

## [1.0.2] - [03.27.2021]

### Fixes

#### Dart

- **Fixed** flutter example.

#### Android

- **Fixed** `[audiosFromPlaylist]` [**Now this method is part of queryAudiosFrom**]
- **Fixed** `"count(*)"` error from `[addToPlaylist]`. [**Permission bug on Android 10 still happening**]

### Documentation

- Updated `README` documentation.

### Changes

#### Dart

- Now `[Id]` in models return `[int]` instead `[String]`.

### ⚠ Important Changes

#### Dart/Android

- Removed `[ALBUM_KEY]`, `[ARTIST_KEY]` from all query audio methods.

#### Android

- Moved `[audiosFromPlaylist]` to `[queryAudiosFrom]`.

## [1.0.0] - [03.24.2021]

### Release

- `[on_audio_query]` release.

## [0.5.0] - [03.23.2021]

### Features

#### Dart/Android

- Changed some methods structure.
- Added `[moveItemTo]` method to Playlist.
- Added `[Size]` and `[Format]` parameters to `[queryArtwork]`.
- Added `[getDeviceSDK]`, `[getDeviceRelease]` and `[getDeviceCode]`.
- Added `[retryRequest]` parameter to `[permissionsRequest]`.

#### Dart

- Added `[QueryArtworkWidget]`.

### Fixes

- Added parameter `[AudioId]` to `[addToPlaylist]` and `[removeFromPlaylist]`.

### Documentation

- Updated `README` documentation.
- Added more comments to `[Kotlin]` and `[Dart]` code.

### Changes

- Now Playlist methods parameters request `[id]` instead Name.
- Now `[renamePlaylist]` add more information -> `[Date_Modified]`.
- Now when `[requestPermission]` parameter is set to true or `[permissionsRequest]` method is called, both `[READ]` and `[WRITE]` is requested.

## [0.4.0] - [03.18.2021]

### Features

#### Dart/Android

- Changed some methods structure.
- Added `[renamePlaylist]`.
- Added separate option for sortType order `[ASC_OR_SMALLER]` and `[DESC_OR_GREATER]`.
- Added `[permissionsStatus]` and `[permissionsRequest]`.

### Documentation

- Updated `README` documentation.
- Added some comments to `[Kotlin]` and `[Dart]` code.

### Changes

- Now `[createPlaylist]`, `[removePlaylist]`, `[addToPlaylist]` and `[removeFromPlaylist]` return bool.

## [0.3.0] - [03.16.2021]

### Features

#### Dart/Android

- Added `[createPlaylist]`, `[removePlaylist]`, `[addToPlaylist]` and `[removeFromPlaylist]`.

#### Dart

- Updated the `[Example]` application.

### Documentation

- Updated `README` documentation.

## [0.2.5] - [03.11.2021]

### Features

#### Dart/Android

- Added `[queryArtworks]` and `[queryAudiosFrom]`.

### Fixes

- Added a better performance for query images.

### Documentation

- Updated `README` documentation.

## [0.2.0] - [03.10.2021]

### Features

#### Dart/Android

- Added `[queryArtists]`, `[queryPlaylists]` and `[queryGenres]`.
- Added `[ArtistSortType]`, `[PlaylistsSortType]` and `[GenreSortType]`.

#### Android

- Now all methods use `Kotlin Coroutines` for query in background, adding a better performance.

### Documentation

- Updated `README` documentation.
- Updated `pubspec.yaml`.
- Created `README` translation section.
- Created `README` translation for `pt-BR` [Portuguese].

## [0.1.5] - [03.08.2021]

### Features

#### Dart/Android

- Added `[querySongs]`, `[queryAudio]` and `[queryAlbums]`.
- Added `[AudioSortType]` and `[AlbumSortType]`.

#### Android

- Added `[Optional]` and `[Built-in]` Write and Read Storage Permission.

### Documentation

- Created a `README` documentation.

## [0.0.1] - [02.16.2021]

### Features

#### Dart/Android

- Created the base for the plugin.

<!--
## [Version] - [Date]
### Features
- TODO

### Fixes
- TODO

### Documentation
- TODO

### Changes
- TODO

### Refactor
- TODO

### ⚠ Important Changes
#### @**Deprecated**
- TODO
 -->

<!--
 https://github.com/LucJosin/on_audio_query/issues/
 - **Added** (Text)- [#Issue](Link)
 - **Fixed** (Text)- [#Issue](Link)
 - **[Changed]** (Text)- [#Issue](Link)
-->
