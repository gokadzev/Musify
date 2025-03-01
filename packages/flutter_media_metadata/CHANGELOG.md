## 1.0.0

- Now supporting all platforms Windows, Linux, macOS, Android, iOS & Web.
- Add web support (@alexmercerind).
- Add iOS support (@DiscombobulatedDrag).
- Revert to using `CompletableFuture` on Android (@alexmercerind).

## 0.1.3

- Add macOS support (@DiscombobulatedDrag).
- Add optional `createNewInstance` argument to `MetadataRetriever.fromFile` (@alexmercerind).
  - Works only on Android.
  - Creates new `MediaMetadataRetriever` instance.
  - Forces `CompletableFuture`.

## 0.1.2

- Add iOS support (@DiscombobulatedDrag)
- Linux: Use `wcstombs` for `std::wstring` conversion (@alexmercerind).
- Linux: Fix segmentation fault with no album art files (@alexmercerind).
- Windows: Fix media having no tags & embedded album art container causing crash (@alexmercerind).
- Windows: Fix UTF16 tags not being parsed properly (@alexmercerind).
- Windows: Add `file_path` to metadata (@alexmercerind).
- Windows & Linux: Fix FLAC album arts (@alexmercerind).
- Windows & Linux: Use Format `Stream_General` for METADATA_BLOCK_PICTURE detection (@alexmercerind).

## 0.1.1

- Added Windows support.
- Moved `MediaMetadataRetriever.setDataSource` & `MediaMetadataRetriever.extractMetadata` calls to another non-UI thread on Android.
- Improved Linux support.
- Added support for embedded album arts on Windows & Linux.
- Changed API to single call, `MetadataRetriever.fromFile`.

## 0.1.0

- Migrated to null-safety
- `trackArtistNames` is now `List<String>` instead of `List<dynamic>`

## 0.0.3+2

- Update documentation.

## 0.0.3

- [media_metadata_retriever](https://github.com/alexmercerind/flutter_media_metadata) is now [flutter_media_metadata](https://github.com/alexmercerind/media_metadata_retriever).
- Added Linux support with album arts.
- Uses [MediaInfoLib](https://github.com/MediaArea/MediaInfoLib) on Linux.

## 0.0.1+4

- Updated Metadata class structure.
- Now bitrate & duration in stored in Metadata itself.

## 0.0.1+3

- More minor changes.

## 0.0.1+2

- Minor updates to documentation.

## 0.0.1

- Support for retriving metadata of a media file in Android.
- Uses [MediaMetadataRetriever](https://developer.android.com/reference/android/media/MediaMetadataRetriever).
