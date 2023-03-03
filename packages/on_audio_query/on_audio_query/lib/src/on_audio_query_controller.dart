/*
=============
Author: Lucas Josino
Github: https://github.com/LucJosin
Website: https://www.lucasjosino.com/
=============
Plugin/Id: on_audio_query#0
Homepage: https://github.com/LucJosin/on_audio_query
Pub: https://pub.dev/packages/on_audio_query
License: https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/LICENSE
Copyright: © 2021, Lucas Josino. All rights reserved.
=============
*/

import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

// import 'methods/queries/albums_query.dart';
// import 'methods/queries/artists_query.dart';
// import 'methods/queries/audios_query.dart';
// import 'methods/queries/genres_query.dart';

/// Main method to use the [on_audio_query] plugin.
///
/// Example:
///
/// Init the plugin using:
///
/// ```dart
/// final OnAudioQuery _audioQuery = OnAudioQuery();
/// ```
///
/// Helpful Links:
///   * [Homepage](https://github.com/LucJosin/on_audio_query)
///     * [Examples](https://github.com/LucJosin/on_audio_query#examples)
///   * [Pub](https://pub.dev/packages/on_audio_query)
///     * [Documentation](https://pub.dev/documentation/on_audio_query/latest/)
///
/// Any problem? [Issues](https://github.com/LucJosin/on_audio_query/issues) <br>
///
/// Any suggestion? [Pull request](https://github.com/LucJosin/on_audio_query/pulls)
///
/// Copyright: © 2021, [Lucas Josino](https://www.lucasjosino.com/). All rights reserved.
class OnAudioQuery {
  /// The platform interface that drives this plugin
  static OnAudioQueryPlatform get platform => OnAudioQueryPlatform.instance;

  // Methods used when [fromAsset] is true.
  // static final AudiosQuery _audiosQuery = AudiosQuery();
  // static final AlbumsQuery _albumsQuery = AlbumsQuery();
  // static final ArtistsQuery _artistsQuery = ArtistsQuery();
  // static final GenresQuery _genresQuery = GenresQuery();

  /// The default path used to store or cache the 'queried' images/artworks.
  ///
  /// **Note: All images are stored inside the app directory or device temporariy
  /// directory, you can use the `path_provider` to get this path.**
  ///
  /// Example:
  ///
  /// ```dart
  /// // Using the app directory.
  /// var appDir = await getApplicationSupportDirectory();
  ///
  /// // Using the temporariy directory.
  /// var appDir = await getTemporaryDirectory();
  ///
  /// // The directory with all images.
  /// var artworksDir = appDir + artworksPath;
  /// ```
  static const String artworksPath = defaultArtworksPath;

  /// Used to delete all artworks cached after using [queryArtwork].
  ///
  /// Note: This method will delete **ONLY** files inside the app directory, all
  /// artworks cached inside the temp folder will be delete automatically after
  /// some time.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `❌` | `✔️` | `❌` | `✔️` | <br>
  ///
  /// See more about [platform support](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/PLATFORMS.md)
  static Future<bool> clearCachedArtworks() async {
    return platform.clearCachedArtworks();
  }

  /// Used to return songs info.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forSongs].
  ///   * If [fromAsset] is null, will be set to false.
  ///
  /// Example:
  ///
  /// * Using await/async:
  ///
  /// ```dart
  /// Future<List<AudioModel>> getAllSongs() async {
  ///  // Default filter.
  ///  MediaFilter _filter = MediaFilter.forSongs(
  ///    songSortType: SongSortType.TITLE,
  ///    limit: 30,
  ///    orderType: OrderType.ASC_OR_SMALLER,
  ///    uriType: UriType.EXTERNAL,
  ///    ignoreCase: true,
  ///    toQuery: const {},
  ///    toRemove: const {},
  ///    type: const {AudioType.IS_MUSIC: true},
  ///  );
  ///  return await _audioQuery.querySongs(filter: _filter);
  /// }
  /// ```
  ///
  /// * Using [FutureBuilder]: [Plugin example][1]
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support][2]
  ///
  /// [1]: https://github.com/LucJosin/on_audio_query/tree/development/on_audio_query/example
  /// [2]: https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md
  Future<List<AudioModel>> querySongs({
    MediaFilter? filter,
    bool fromAsset = false,
    bool fromAppDir = false,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        // ignore: deprecated_member_use
        SongSortType? sortType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        OrderType? orderType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        UriType? uriType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        bool? ignoreCase,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        String? path,
  }) async {
    return queryAudios(
      filter: filter,
      fromAsset: fromAsset,
      fromAppDir: fromAppDir,
    );
  }

  /// Used to return audios info based in [AudioModel].
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forAudios].
  ///   * If [fromAsset] is null, will be set to false.
  ///
  /// Example:
  ///
  /// * Using await/async:
  ///
  /// ```dart
  /// Future<List<AudioModel>> getAllAudios() async {
  ///  // Default filter.
  ///  MediaFilter _filter = MediaFilter.forAudios(
  ///    songSortType: SongSortType.TITLE,
  ///    limit: 30,
  ///    orderType: OrderType.ASC_OR_SMALLER,
  ///    uriType: UriType.EXTERNAL,
  ///    ignoreCase: true,
  ///    toQuery: const {},
  ///    toRemove: const {},
  ///    type: const {},
  ///  );
  ///  return await _audioQuery.queryAudios(filter: _filter);
  /// }
  /// ```
  ///
  /// * Using [FutureBuilder]: [Plugin example][1]
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `✔️` | `✔️` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<List<AudioModel>> queryAudios({
    MediaFilter? filter,
    bool fromAsset = false,
    bool fromAppDir = false,
  }) async {
    //
    // if (fromAsset || fromAppDir) {
    //   return _audiosQuery.queryAudios(
    //     filter: filter,
    //     fromAsset: fromAsset,
    //     fromAppDir: fromAppDir,
    //   );
    // }

    //
    return platform.queryAudios(filter: filter);
  }

  /// Used to observe(listen) the audios changes.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forAudios].
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `✔️` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/PLATFORMS.md)
  Stream<List<AudioModel>> observeAudios({MediaFilter? filter}) {
    return platform.observeAudios(filter: filter);
  }

  /// Used to return albums info.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forAlbums].
  ///   * If [fromAsset] is null, will be set to false.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `✔️` | `✔️` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<List<AlbumModel>> queryAlbums({
    MediaFilter? filter,
    bool fromAsset = false,
    bool fromAppDir = false,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        AlbumSortType? sortType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        OrderType? orderType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        UriType? uriType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        bool? ignoreCase,
  }) async {
    //
    // if (fromAsset || fromAppDir) {
    //   return _albumsQuery.queryAlbums(
    //     await _audiosQuery.queryAudios(),
    //     filter: filter,
    //     fromAsset: fromAsset,
    //     fromAppDir: fromAppDir,
    //   );
    // }

    //
    return platform.queryAlbums(filter: filter);
  }

  /// Used to observe(listen) the albums changes.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forAlbums].
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `✔️` | <br>
  ///
  /// See more about [platform support](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/PLATFORMS.md)
  Stream<List<AlbumModel>> observeAlbums({MediaFilter? filter}) {
    return platform.observeAlbums(filter: filter);
  }

  /// Used to return artists info.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forArtists].
  ///   * If [fromAsset] is null, will be set to false.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `✔️` | `✔️` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<List<ArtistModel>> queryArtists({
    MediaFilter? filter,
    bool fromAsset = false,
    bool fromAppDir = false,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        ArtistSortType? sortType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        OrderType? orderType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        UriType? uriType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        bool? ignoreCase,
  }) async {
    //
    // if (fromAsset || fromAppDir) {
    //   return _artistsQuery.queryArtists(
    //     await _audiosQuery.queryAudios(),
    //     filter: filter,
    //     fromAsset: fromAsset,
    //     fromAppDir: fromAppDir,
    //   );
    // }

    //
    return platform.queryArtists(filter: filter);
  }

  /// Used to observe(listen) the artists changes.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forArtists].
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `✔️` | <br>
  ///
  /// See more about [platform support](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/PLATFORMS.md)
  Stream<List<ArtistModel>> observeArtists({MediaFilter? filter}) {
    return platform.observeArtists(filter: filter);
  }

  /// Used to return playlists info.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forPlaylists].
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<List<PlaylistModel>> queryPlaylists({
    MediaFilter? filter,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        PlaylistSortType? sortType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        OrderType? orderType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        UriType? uriType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        bool? ignoreCase,
  }) async {
    return platform.queryPlaylists(filter: filter);
  }

  /// Used to observe(listen) the playlists changes.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forAlbums].
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platform support](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/PLATFORMS.md)
  Stream<List<PlaylistModel>> observePlaylists({MediaFilter? filter}) {
    return platform.observePlaylists(filter: filter);
  }

  /// Used to return genres info.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forGenres].
  ///   * If [fromAsset] is null, will be set to false.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `✔️` | `✔️` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<List<GenreModel>> queryGenres({
    MediaFilter? filter,
    bool fromAsset = false,
    bool fromAppDir = false,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        GenreSortType? sortType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        OrderType? orderType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        UriType? uriType,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        bool? ignoreCase,
  }) async {
    //
    // if (fromAsset || fromAppDir) {
    //   return _genresQuery.queryGenres(
    //     filter: filter,
    //     fromAsset: fromAsset,
    //     fromAppDir: fromAsset,
    //   );
    // }

    //
    return platform.queryGenres(filter: filter);
  }

  /// Used to observe(listen) the genres changes.
  ///
  /// Important:
  ///   * If [filter] is null, will be used the [MediaFilter.forGenres].
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `✔️` | <br>
  ///
  /// See more about [platform support](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/PLATFORMS.md)
  Stream<List<GenreModel>> observeGenres({MediaFilter? filter}) {
    return platform.observeGenres(filter: filter);
  }

  /// Used to return Songs Artwork.
  ///
  /// Parameters:
  ///
  /// * [type] is used to define if artwork is from audios or albums.
  /// * [format] is used to define type [PNG] or [JPEG].
  /// * [size] is used to define image quality.
  ///
  /// Usage and Performance:
  ///
  /// * Using [PNG] will return a better image quality but a slow performance.
  /// * Using [Size] greater than 200 probably won't make difference in quality but will cause a slow performance.
  ///
  /// Important:
  ///
  /// * This method is only necessary for API >= 29 [Android Q/10].
  /// * If [queryArtwork] is called in Android below Q/10, will return null.
  /// * If [format] is null, will be set to [JPEG] for better performance.
  /// * If [size] is null, will be set to [200] for better performance
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<ArtworkModel?> queryArtwork(
    int id,
    ArtworkType type, {
    MediaFilter? filter,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        // ignore: deprecated_member_use
        ArtworkFormat? format,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        int? size,
    @Deprecated("Deprecated after [3.0.0]. Use [filter] instead")
        int? quality,
  }) async {
    return platform.queryArtwork(
      id,
      type,
      filter: filter,
    );
  }

  //Playlist methods

  /// Used to create a Playlist
  ///
  /// Parameters:
  ///
  /// * [name] the playlist name.
  /// * [author] the playlist author. (IOS only)
  /// * [desc] the playlist description. (IOS only)
  ///
  /// Important:
  ///
  /// * This method create a playlist using [External Storage], all apps will be able to see this playlist
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<int?> createPlaylist(
    String name, {
    String? author,
    String? desc,
  }) async {
    return platform.createPlaylist(
      name,
      author: author,
      desc: desc,
    );
  }

  /// Used to remove/delete a Playlist
  ///
  /// Parameters:
  ///
  /// * [playlistId] is used to check if Playlist exist.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<bool> removePlaylist(int playlistId) async {
    return platform.removePlaylist(playlistId);
  }

  /// Used to add a specific song/audio to a specific Playlist
  ///
  /// Parameters:
  ///
  /// * [playlistId] is used to check if Playlist exist.
  /// * [audioId] is used to add specific audio to Playlist.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<bool> addToPlaylist(int playlistId, int audioId) async {
    return platform.addToPlaylist(playlistId, audioId);
  }

  /// Used to remove a specific song/audio from a specific Playlist
  ///
  /// Parameters:
  ///
  /// * [playlistId] is used to check if Playlist exist.
  /// * [audioId] is used to remove specific audio from Playlist.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<bool> removeFromPlaylist(int playlistId, int audioId) async {
    return platform.removeFromPlaylist(playlistId, audioId);
  }

  /// Used to change song/audio position from a specific Playlist
  ///
  /// Parameters:
  ///
  /// * [playlistId] is used to check if Playlist exist.
  /// * [from] is the old position from a audio/song.
  /// * [to] is the new position from a audio/song.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<bool> moveItemTo(int playlistId, int from, int to) async {
    return platform.moveItemTo(playlistId, from, to);
  }

  /// Used to rename a specific Playlist
  ///
  /// Parameters:
  ///
  /// * [playlistId] is used to check if Playlist exist.
  /// * [newName] is used to add a new name to a Playlist.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<bool> renamePlaylist(int playlistId, String newName) async {
    return renamePlaylist(playlistId, newName);
  }

  // Permissions methods

  /// Used to check Android permissions status
  ///
  /// Important:
  ///
  /// * This method will always return a bool.
  /// * If return true `[READ]` and `[WRITE]` permissions is Granted, else `[READ]` and `[WRITE]` is Denied.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<bool> permissionsStatus() async {
    return platform.permissionsStatus();
  }

  /// Used to request Android permissions.
  ///
  /// Important:
  ///
  /// * This method will always return a bool.
  /// * If return true `[READ]` and `[WRITE]` permissions is Granted, else `[READ]` and `[WRITE]` is Denied.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<bool> permissionsRequest() async {
    return platform.permissionsRequest();
  }

  // Device Information

  /// Used to return Device Info
  ///
  /// Will return:
  ///
  /// * Device SDK.
  /// * Device Release.
  /// * Device Code.
  /// * Device Type.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/PLATFORMS.md)
  Future<DeviceModel> queryDeviceInfo() async {
    return platform.queryDeviceInfo();
  }

  // Others

  /// Used to scan the given [path]
  ///
  /// Will return:
  ///
  /// * A boolean indicating if the path was scanned or not.
  ///
  /// Usage:
  ///
  /// * When using the [Android] platform. After deleting a media using the [dart:io],
  /// call this method to update the media. If the media was successfully and the path
  /// not scanned. Will keep showing on [querySongs].
  ///
  /// Example:
  ///
  /// ```dart
  /// OnAudioQuery _audioQuery = OnAudioQuery();
  /// File file = File('path');
  ///
  /// try {
  ///   if (file.existsSync()) {
  ///     file.deleteSync();
  ///     _audioQuery.scanMedia(file.path); // Scan the media 'path'
  ///   }
  /// } catch (e) {
  ///   debugPrint('$e');
  /// }
  /// ```
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `❌` | `❌` | `❌` | <br>
  ///
  /// See more about [platforms support](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/PLATFORMS.md)
  Future<bool> scanMedia(String path) async {
    return platform.scanMedia(path);
  }

  /// Used to check the observers(listeners) status of:
  ///   * [observeAudios]
  ///   * [observeAlbums]
  ///   * [observePlaylists]
  ///   * [observeArtists]
  ///   * [observeGenres]
  ///
  /// Will return:
  ///
  /// * A [ObserversModel], every parameters from this model will return a boolean
  /// indicating if the observers is **running** or not.
  ///
  /// Platforms:
  ///
  /// |`   Android   `|`   IOS   `|`   Web   `|`   Windows   `|
  /// |:----------:|:----------:|:----------:|:----------:|
  /// | `✔️` | `✔️` | `❌` | `✔️` | <br>
  ///
  /// See more about [platform support](https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/PLATFORMS.md)
  Future<ObserversModel> observersStatus() async {
    return platform.observersStatus();
  }

  // Deprecated methods

  /// Deprecated after [3.0.0]. Use one of the [query] methods instead
  @Deprecated(
    "Deprecated after [3.0.0]. Use one of the [query] methods instead",
  )
  Future<List<SongModel>> queryAudiosFrom(
    AudiosFromType type,
    Object where, {
    SongSortType? sortType,
    OrderType? orderType,
    bool? ignoreCase,
  }) async {
    throw const Deprecated('Deprecated after [3.0.0]');
  }

  /// Deprecated after [3.0.0]. Use one of the [query] methods instead
  @Deprecated(
    "Deprecated after [3.0.0]. Use one of the [query] methods instead",
  )
  Future<List<dynamic>> queryWithFilters(
    String argsVal,
    WithFiltersType withType, {
    dynamic args,
  }) {
    throw const Deprecated('Deprecated after [3.0.0]');
  }

  /// Deprecated after [3.0.0]. Use one of the [query] methods instead
  @Deprecated(
    "Deprecated after [3.0.0]. Use one of the [query] methods instead",
  )
  Future<List<SongModel>> queryFromFolder(
    String path, {
    SongSortType? sortType,
    OrderType? orderType,
    UriType? uriType,
  }) {
    throw const Deprecated('Deprecated after [3.0.0]');
  }

  /// Deprecated after [3.0.0]
  @Deprecated("Deprecated after [3.0.0]")
  Future<List<String>> queryAllPath() {
    throw const Deprecated('Deprecated after [3.0.0]');
  }
}
