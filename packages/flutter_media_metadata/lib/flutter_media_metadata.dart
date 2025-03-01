/// ## flutter_media_metadata
///
/// A Flutter plugin to read metadata of media files.
///
/// MIT License.
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
///
/// _Minimal Example_
/// ```dart
/// final metadata = MetadataRetriever.fromBytes(byteData);
/// String? trackName = metadata.trackName;
/// List<String>? trackArtistNames = metadata.trackArtistNames;
/// String? albumName = metadata.albumName;
/// String? albumArtistName = metadata.albumArtistName;
/// int? trackNumber = metadata.trackNumber;
/// int? albumLength = metadata.albumLength;
/// int? year = metadata.year;
/// String? genre = metadata.genre;
/// String? authorName = metadata.authorName;
/// String? writerName = metadata.writerName;
/// int? discNumber = metadata.discNumber;
/// String? mimeType = metadata.mimeType;
/// int? trackDuration = metadata.trackDuration;
/// int? bitrate = metadata.bitrate;
/// Uint8List? albumArt = metadata.albumArt;
/// ```
///
library flutter_media_metadata;

export 'package:flutter_media_metadata/src/flutter_media_metadata_native.dart'
    if (dart.library.html) 'package:flutter_media_metadata/src/flutter_media_metadata_web.dart';
export 'package:flutter_media_metadata/src/models/metadata.dart';
