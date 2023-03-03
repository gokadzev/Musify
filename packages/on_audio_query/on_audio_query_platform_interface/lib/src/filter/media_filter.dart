import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

/// A filter that will be used with:
///
/// * [queryAudios]\(querySongs);
/// * [queryAlbums];
/// * [queryArtists];
/// * [queryPlaylists];
/// * [queryGenres].
/// * [queryArtwork].
class MediaFilter {
  /// The audio sort type.
  AudioSortType? audioSortType;

  /// The album sort type.
  AlbumSortType? albumSortType;

  /// The artist sort type.
  ArtistSortType? artistSortType;

  /// The playlist sort type.
  PlaylistSortType? playlistSortType;

  /// The genre sort type.
  GenreSortType? genreSortType;

  /// The list order type.
  ///
  /// Types:
  ///   * ASC_OR_SMALLER;
  ///   * DESC_OR_GREATER.
  ///
  /// Note: If null, will be defined as [OrderType.ASC_OR_SMALLER].
  OrderType orderType;

  /// The 'query' url type.
  ///
  /// Types:
  ///   * EXTERNAL;
  ///   * INTERNAL (Android only);
  ///   * EXTERNAL_PRIMARY (Android only && API level 29).
  ///
  /// Note: If null, will be defined as [UriType.EXTERNAL].
  UriType uriType;

  /// Define if we should ignore the 'Case-sensitive'.
  ///
  /// Note: If null, will be defined as [true].
  bool ignoreCase;

  /// Define if we should limit the 'query'.
  ///
  /// Note: By default, the limit it's [null].
  int? limit;

  /// The 'type' of the audios.
  ///
  /// Types:
  ///   * IS_MUSIC;
  ///   * IS_ALARM;
  ///   * IS_NOTIFICATION;
  ///   * IS_PODCAST;
  ///   * IS_RINGTONE;
  ///   * IS_AUDIOBOOK.
  ///
  /// Note: By default, the type is [empty]\(Will 'query' all types of audios).
  Map<AudioType, bool> type;

  /// Define where the plugin will query the medias:
  ///   * [DEFAULT]
  ///     * Android: MediaStore
  ///     * iOS: MPMediaLibrary(MPMediaQuery)
  ///     * Web: The app assets folder.
  ///     * Windows: The user '/Music' directory.
  ///   * [ASSETS] The app assets folder.
  ///   * [APP_DIR] The app 'private' directory.
  MediaDirType? dirType;

  /// The 'objects'(titles, albums, artists, etc...) to be 'queried'.
  ///
  /// E.g:
  ///
  /// ```dart
  /// MediaFilter filter = MediaFilter.forAudios(
  ///   toQuery: {
  ///     MediaColumns.Audio.TITLE: [
  ///       "Hericane",
  ///       "13",
  ///       "ILYSB",
  ///       "Parents",
  ///     ],
  ///     MediaColumns.Audio.ARTIST: ["Lany"],
  ///     MediaColumns.Audio.ALBUM: ["LANY"],
  ///   }
  /// );
  /// ```
  ///
  /// Note: By default, the toQuery is [empty]\(Will 'query' all audios).
  Map<int, List<String>> toQuery;

  /// The 'objects'(titles, albums, artists, etc...) to be removed from 'query'.
  ///
  /// E.g:
  ///
  /// ```dart
  /// MediaFilter filter = MediaFilter.forAudios(
  ///   toRemove: {
  ///     MediaColumns.Audio.TITLE: [
  ///       "It's Not The End",
  ///       "Are You All Good?",
  ///       "Haze",
  ///     ],
  ///     MediaColumns.Audio.ARTIST: ["breathe"],
  ///   }
  /// );
  /// ```
  ///
  /// Note: By default, the toRemove is [empty]\(Will 'query' all audios).
  Map<int, List<String>> toRemove;

  // Artwork specific 'query'.

  /// The artwork [format].
  ///
  /// Formats:
  ///   * JPEG (JPG);
  ///   * PNG.
  ///
  /// Note: If null, will be defined as [ArtworkFormatType.JPEG].
  ArtworkFormatType? artworkFormat;

  /// The artwork [size].
  ///
  /// Note: If null, will be defined as [100].
  int? artworkSize;

  /// The artwork [quality].
  ///
  /// Note: If null, will be defined as [50].
  int? artworkQuality;

  // Artwork cache.

  /// Define if the artwork will be [cached]\(saved) inside the app directory.
  ///
  /// Caching the artwork will avoid read the image bytes everytime a new 'query'
  /// happens.
  ///
  /// Note: If null, will be defined as [true].
  ///
  /// Note²: You can use [clearCachedArtworks] to delete all cached/saved images.
  ///
  /// Note³: You can define [cacheTemporarily] and this cached/saved images will be
  /// deleted automatically.
  bool? cacheArtwork;

  /// Define if the artwork will be [deleted] will be deleted automatically
  ///
  /// Caching the artwork will avoid read the image bytes everytime a new 'query'
  /// happens.
  ///
  /// Note: If null, will be defined as [true].
  ///
  /// Note²: This method will only be avalible if [cacheArtwork] is [true].
  bool? cacheTemporarily;

  /// Define if the artwork will be [overriden] if already exists.
  ///
  /// E.g: If [cacheArtwork] and [overrideCache] are true, everytime [queryArtwork]
  /// is called and the image is already cached/saved, we will rewrite this image.
  ///
  /// Note: If null, will be defined as [false].
  ///
  /// Note²: This method will only be avalible if [cacheArtwork] is [true].
  bool? overrideCache;

  /// A 'default' filter that can be used to all filters.
  ///
  /// Note: Don't use this method as a default. Use the specific filter to the
  /// query.
  ///
  /// E.g: For audio use [MediaFilter.forAudios], for albums use
  /// [MediaFilter.forAlbums], etc..
  MediaFilter.init({
    this.audioSortType,
    this.albumSortType,
    this.artistSortType,
    this.playlistSortType,
    this.genreSortType,
    this.limit,
    this.orderType = OrderType.ASC_OR_SMALLER,
    this.uriType = UriType.EXTERNAL,
    this.ignoreCase = true,
    this.toQuery = const {},
    this.toRemove = const {},
    this.type = const {},
    this.dirType,
    this.artworkFormat,
    this.artworkSize,
    this.artworkQuality,
    this.cacheArtwork,
    this.cacheTemporarily,
    this.overrideCache,
  });

  // TODO: Add more specific 'query'.
  // E.g: ComparisonType.LIKE, ComparisonType.NOT_LIKE, ComparisonType.EQUAL_OR_SMALLER
  //
  /// A 'default' filter that can be used for audios.
  ///
  /// Parameters:
  ///
  /// * [audioSortType] is used to define the list sort.
  /// * [limit] is used to define the count of audios that will be returned.
  /// * [orderType] is used to define if order will be Ascending or Descending.
  /// * [uriType] is used to define if songs will be catch in [EXTERNAL] or [INTERNAL] storage.
  /// * [ignoreCase] is used to define if sort will ignore the lowercase or not.
  /// * [toQuery] is used to define all 'objects'(titles, albums, etc...) to be 'queried'.
  /// * [toRemove] is used to define all 'objects'(titles, albums, etc...) to be removed from 'query'.
  /// * [type] is used to define the 'type' of the audios.
  MediaFilter.forAudios({
    this.audioSortType,
    this.limit,
    this.orderType = OrderType.ASC_OR_SMALLER,
    this.uriType = UriType.EXTERNAL,
    this.ignoreCase = true,
    this.toQuery = const {},
    this.toRemove = const {},
    this.type = const {},
    this.dirType,
  });

  /// A 'default' filter that can be used for audios(songs).
  ///
  /// Parameters:
  ///
  /// * [audioSortType] is used to define the list sort.
  /// * [limit] is used to define the count of audios that will be returned.
  /// * [orderType] is used to define if order will be Ascending or Descending.
  /// * [uriType] is used to define if songs will be catch in [EXTERNAL] or [INTERNAL] storage.
  /// * [ignoreCase] is used to define if sort will ignore the lowercase or not.
  /// * [toQuery] is used to define all 'objects'(titles, albums, etc...) to be 'queried'.
  /// * [toRemove] is used to define all 'objects'(titles, albums, etc...) to be removed from 'query'.
  /// * [type] is used to define the 'type' of the audios.
  MediaFilter.forSongs({
    this.audioSortType,
    this.limit,
    this.orderType = OrderType.ASC_OR_SMALLER,
    this.uriType = UriType.EXTERNAL,
    this.ignoreCase = true,
    this.toQuery = const {},
    this.toRemove = const {},
    this.type = const {
      AudioType.IS_MUSIC: true,
    },
    this.dirType,
  });

  /// A 'default' filter that can be used for albums.
  ///
  /// Parameters:
  ///
  /// * [albumSortType] is used to define the list sort.
  /// * [limit] is used to define the count of medias that will be returned.
  /// * [orderType] is used to define if order will be Ascending or Descending.
  /// * [uriType] is used to define if songs will be catch in [EXTERNAL] or [INTERNAL] storage.
  /// * [ignoreCase] is used to define if sort will ignore the lowercase or not.
  /// * [toQuery] is used to define all 'objects'(titles, albums, etc...) to be 'queried'.
  /// * [toRemove] is used to define all 'objects'(titles, albums, etc...) to be removed from 'query'.
  MediaFilter.forAlbums({
    this.albumSortType,
    this.limit,
    this.orderType = OrderType.ASC_OR_SMALLER,
    this.uriType = UriType.EXTERNAL,
    this.ignoreCase = true,
    this.toQuery = const {},
    this.toRemove = const {},
    this.dirType,
  }) : type = const {};

  /// A 'default' filter that can be used for artists.
  ///
  /// Parameters:
  ///
  /// * [albumSortType] is used to define the list sort.
  /// * [limit] is used to define the count of medias that will be returned.
  /// * [orderType] is used to define if order will be Ascending or Descending.
  /// * [uriType] is used to define if songs will be catch in [EXTERNAL] or [INTERNAL] storage.
  /// * [ignoreCase] is used to define if sort will ignore the lowercase or not.
  /// * [toQuery] is used to define all 'objects'(titles, albums, etc...) to be 'queried'.
  /// * [toRemove] is used to define all 'objects'(titles, albums, etc...) to be removed from 'query'.
  MediaFilter.forArtists({
    this.artistSortType,
    this.limit,
    this.orderType = OrderType.ASC_OR_SMALLER,
    this.uriType = UriType.EXTERNAL,
    this.ignoreCase = true,
    this.toQuery = const {},
    this.toRemove = const {},
    this.dirType,
  }) : type = const {};

  /// A 'default' filter that can be used for playlists.
  ///
  /// Parameters:
  ///
  /// * [albumSortType] is used to define the list sort.
  /// * [limit] is used to define the count of medias that will be returned.
  /// * [orderType] is used to define if order will be Ascending or Descending.
  /// * [uriType] is used to define if songs will be catch in [EXTERNAL] or [INTERNAL] storage.
  /// * [ignoreCase] is used to define if sort will ignore the lowercase or not.
  /// * [toQuery] is used to define all 'objects'(titles, albums, etc...) to be 'queried'.
  /// * [toRemove] is used to define all 'objects'(titles, albums, etc...) to be removed from 'query'.
  MediaFilter.forPlaylists({
    this.playlistSortType,
    this.limit,
    this.orderType = OrderType.ASC_OR_SMALLER,
    this.uriType = UriType.EXTERNAL,
    this.ignoreCase = true,
    this.toQuery = const {},
    this.toRemove = const {},
    this.dirType,
  }) : type = const {};

  /// A 'default' filter that can be used for genres.
  ///
  /// Parameters:
  ///
  /// * [albumSortType] is used to define the list sort.
  /// * [limit] is used to define the count of medias that will be returned.
  /// * [orderType] is used to define if order will be Ascending or Descending.
  /// * [uriType] is used to define if songs will be catch in [EXTERNAL] or [INTERNAL] storage.
  /// * [ignoreCase] is used to define if sort will ignore the lowercase or not.
  /// * [toQuery] is used to define all 'objects'(titles, albums, etc...) to be 'queried'.
  /// * [toRemove] is used to define all 'objects'(titles, albums, etc...) to be removed from 'query'.
  MediaFilter.forGenres({
    this.genreSortType,
    this.limit,
    this.orderType = OrderType.ASC_OR_SMALLER,
    this.uriType = UriType.EXTERNAL,
    this.ignoreCase = true,
    this.toQuery = const {},
    this.toRemove = const {},
    this.dirType,
  }) : type = const {};

  /// A 'default' filter that can be used for artwork.
  ///
  /// Parameters:
  ///
  /// * [artworkFormat] is used to define the [ArtworkFormatType].
  /// * [artworkSize] is used to define the artwork size.
  /// * [artworkQuality] is used to define the artwork quality.
  /// * [cacheArtwork] is used to define if the artwork will be [cached].
  /// * [cacheTemporarily] is used to define if the artwork will be [cached]\(temporarily).
  /// * [overrideCache] is used to define if the artwork will be [overriden] if already exists.
  MediaFilter.forArtwork({
    this.artworkFormat = ArtworkFormatType.JPEG,
    this.artworkSize = 100,
    this.artworkQuality = 50,
    this.cacheArtwork = true,
    this.cacheTemporarily = true,
    this.overrideCache = false,
  })  : orderType = OrderType.ASC_OR_SMALLER,
        uriType = UriType.EXTERNAL,
        ignoreCase = true,
        toQuery = const {},
        toRemove = const {},
        type = const {};
}
