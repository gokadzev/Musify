/*
=============
Author: Lucas Josino
Github: https://github.com/LucJosin
Website: https://www.lucasjosino.com/
=============
Plugin/Id: on_audio_query#0
Homepage: https://github.com/LucJosin/on_audio_query
Homepage(Platform): https://github.com/LucJosin/on_audio_query/tree/main/on_audio_query_platform_interface
Pub: https://pub.dev/packages/on_audio_query
License: https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/LICENSE
Copyright: © 2021, Lucas Josino. All rights reserved.
=============
*/

import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_on_audio_query.dart';
import 'src/controllers/models_controller.dart';
import 'src/controllers/sorts_controller.dart';
import 'src/controllers/types_controller.dart';
import 'src/filter/media_filter.dart';

// Constants
export 'src/constants.dart';

// Interfaces
export 'src/interfaces/observer_interface.dart';
export 'src/interfaces/query_helper_interface.dart';

// Internal methods/classes
export 'src/filter/media_filter.dart';
export 'src/filter/columns/media_columns.dart';
export 'src/controllers/models_controller.dart';
export 'src/controllers/sorts_controller.dart';
export 'src/controllers/types_controller.dart';

// External packages
export 'package:id3/id3.dart';
export 'package:path/path.dart';
export 'package:path_provider/path_provider.dart';

/// The interface that implementations of on_audio_query must implement.
///
/// Platform implementations should extend this class rather than implement it as `on_audio_query`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [OnAudioQueryPlatform] methods.
abstract class OnAudioQueryPlatform extends PlatformInterface {
  /// Constructs a OnAudioQueryPlatform.
  OnAudioQueryPlatform() : super(token: _token);

  static final Object _token = Object();

  static OnAudioQueryPlatform _instance = MethodChannelOnAudioQuery();

  /// The default instance of [OnAudioQueryPlatform] to use.
  ///
  /// Defaults to [MethodChannelOnAudioQuery].
  static OnAudioQueryPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [OnAudioQueryPlatform] when they register themselves.
  static set instance(OnAudioQueryPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  // Future<List<T>> queryBuilder<T>({String? builder}) {
  //   throw UnimplementedError('queryBuilder() has not been implemented.');
  // }

  /// Used to delete all artworks cached after using [queryArtwork].
  Future<bool> clearCachedArtworks() {
    throw UnimplementedError('clearCachedArtworks() has not been implemented.');
  }

  /// Used to return Audios Info based in [AudioModel].
  Future<List<AudioModel>> queryAudios({MediaFilter? filter}) {
    throw UnimplementedError('queryAudios() has not been implemented.');
  }

  /// Used to observer(listen) the songs.
  Stream<List<AudioModel>> observeAudios({MediaFilter? filter}) {
    throw UnimplementedError('observeAudios() has not been implemented.');
  }

  /// Used to return Albums Info based in [AlbumModel].
  Future<List<AlbumModel>> queryAlbums({MediaFilter? filter}) {
    throw UnimplementedError('queryAlbums() has not been implemented.');
  }

  /// Used to observer(listen) the albums.
  Stream<List<AlbumModel>> observeAlbums({MediaFilter? filter}) {
    throw UnimplementedError('observeAlbums() has not been implemented.');
  }

  /// Used to return Artists Info based in [ArtistModel].
  Future<List<ArtistModel>> queryArtists({MediaFilter? filter}) {
    throw UnimplementedError('queryArtists() has not been implemented.');
  }

  /// Used to observer(listen) the artists.
  Stream<List<ArtistModel>> observeArtists({MediaFilter? filter}) {
    throw UnimplementedError('observeArtists() has not been implemented.');
  }

  /// Used to return Playlists Info based in [PlaylistModel].
  Future<List<PlaylistModel>> queryPlaylists({MediaFilter? filter}) {
    throw UnimplementedError('queryPlaylists() has not been implemented.');
  }

  /// Used to observer(listen) the playlists.
  Stream<List<PlaylistModel>> observePlaylists({MediaFilter? filter}) {
    throw UnimplementedError('observePlaylists() has not been implemented.');
  }

  /// Used to return Genres Info based in [GenreModel].
  Future<List<GenreModel>> queryGenres({MediaFilter? filter}) {
    throw UnimplementedError('queryGenres() has not been implemented.');
  }

  /// Used to observer(listen) the genres.
  Stream<List<GenreModel>> observeGenres({MediaFilter? filter}) {
    throw UnimplementedError('observeGenres() has not been implemented.');
  }

  /// Used to return Songs Artwork.
  Future<ArtworkModel?> queryArtwork(
    int id,
    ArtworkType type, {
    bool? fromAsset,
    bool? fromAppDir,
    MediaFilter? filter,
  }) {
    throw UnimplementedError('queryArtwork() has not been implemented.');
  }

  //Playlist methods

  /// Used to create a Playlist.
  Future<int?> createPlaylist(
    String name, {
    String? author,
    String? desc,
  }) {
    throw UnimplementedError('createPlaylist() has not been implemented.');
  }

  /// Used to remove/delete a Playlist.
  Future<bool> removePlaylist(int playlistId) {
    throw UnimplementedError('removePlaylist() has not been implemented.');
  }

  /// Used to add a specific song/audio to a specific Playlist.
  Future<bool> addToPlaylist(int playlistId, int audioId) {
    throw UnimplementedError('addToPlaylist() has not been implemented.');
  }

  /// Used to remove a specific song/audio from a specific Playlist.
  Future<bool> removeFromPlaylist(int playlistId, int audioId) {
    throw UnimplementedError('removeFromPlaylist() has not been implemented.');
  }

  /// Used to change song/audio position from a specific Playlist.
  Future<bool> moveItemTo(int playlistId, int from, int to) {
    throw UnimplementedError('moveItemTo() has not been implemented.');
  }

  /// Used to rename a specific Playlist.
  Future<bool> renamePlaylist(int playlistId, String newName) {
    throw UnimplementedError('renamePlaylist() has not been implemented.');
  }

  // Permissions methods

  /// Used to check Android permissions status.
  Future<bool> permissionsStatus() {
    throw UnimplementedError('permissionsStatus() has not been implemented.');
  }

  /// Used to request Android permissions.
  Future<bool> permissionsRequest() {
    throw UnimplementedError('permissionsRequest() has not been implemented.');
  }

  // Device Information

  /// Used to return Device Info.
  Future<DeviceModel> queryDeviceInfo() {
    throw UnimplementedError('queryDeviceInfo() has not been implemented.');
  }

  // Others

  /// Used to scan the given [path].
  Future<bool> scanMedia(String path) {
    throw UnimplementedError('scanMedia() has not been implemented.');
  }

  /// Used to check the observers(listeners) status.
  Future<ObserversModel> observersStatus() {
    throw UnimplementedError('observersStatus() has not been implemented.');
  }

  // Deprecated methods

  /// Deprecated after [3.0.0]. Use one of the [query] methods instead
  @Deprecated(
    "Deprecated after [3.0.0]. Use one of the [query] methods instead",
  )
  Future<List<AudioModel>> queryAudiosFrom(
    AudiosFromType type,
    Object where, {
    SongSortType? sortType,
    OrderType? orderType,
    bool? ignoreCase,
  }) {
    throw UnimplementedError('queryAudiosFrom() has not been implemented.');
  }

  /// Deprecated after [3.0.0]. Use one of the [query] methods instead
  @Deprecated(
    "Deprecated after [3.0.0]. Use one of the [query] methods instead",
  )
  Future<List<dynamic>> queryWithFilters(
    String argsVal,
    WithFiltersType withType,
    dynamic args,
  ) {
    throw UnimplementedError('queryWithFilters() has not been implemented.');
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
    throw UnimplementedError('queryFromFolder() has not been implemented.');
  }

  /// Deprecated after [3.0.0]
  @Deprecated("Deprecated after [3.0.0]")
  Future<List<String>> queryAllPath() {
    throw UnimplementedError('queryAllPath() has not been implemented.');
  }
}
