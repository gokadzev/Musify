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

import 'package:flutter/services.dart';

import 'on_audio_query_platform_interface.dart';

const String _channelName = 'com.lucasjosino.on_audio_query';
const MethodChannel _channel = MethodChannel(_channelName);

const EventChannel _audiosObserverChannel = EventChannel(
  '$_channelName/audios_observer',
);
const EventChannel _albumsObserverChannel = EventChannel(
  '$_channelName/albums_observer',
);
const EventChannel _artistsObserverChannel = EventChannel(
  '$_channelName/artists_observer',
);
const EventChannel _playlistsObserverChannel = EventChannel(
  '$_channelName/playlists_observer',
);
const EventChannel _genresObserverChannel = EventChannel(
  '$_channelName/genres_observer',
);

/// An implementation of [OnAudioQueryPlatform] that uses method channels.
class MethodChannelOnAudioQuery extends OnAudioQueryPlatform {
  /// The MethodChannel that is being used by this implementation of the plugin.
  MethodChannel get channel => _channel;

  /// Default filter for all methods.
  static final MediaFilter _defaultFilter = MediaFilter.init();

  // Observers
  Stream<List<AudioModel>>? _onAudiosObserverChanged;
  Stream<List<AlbumModel>>? _onAlbumsObserverChanged;
  Stream<List<ArtistModel>>? _onArtistsObserverChanged;
  Stream<List<PlaylistModel>>? _onPlaylistsObserverChanged;
  Stream<List<GenreModel>>? _onGenresObserverChanged;

  /// Native query
  // AudiosQuery get _audiosQuery => AudiosQuery();

  // @override
  // Future<List<T>> queryBuilder<T>({String? builder}) async {
  //   return [] as List<T>;
  // }

  @override
  Future<bool> clearCachedArtworks() async {
    return await _channel.invokeMethod('clearCachedArtworks');
  }

  @override
  Future<List<AudioModel>> queryAudios({
    MediaFilter? filter,
  }) async {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Check if the request is to [Assets] or [App Directory].
    // if (filter.dirType == MediaDirType.ASSETS ||
    //     filter.dirType == MediaDirType.APP_DIR) {
    //   return _audiosQuery.queryAudios();
    // }

    // Fix the 'type' filter.
    //
    // Convert the 'AudioType' into 'int'.
    // The 'true' and 'false' value into '1' or '2'.
    Map<int, int> fixedMap = {};
    filter.type.forEach((key, value) {
      //
      fixedMap[key.index] = value == true ? 1 : 0;
    });

    // Invoke the channel.
    final List<dynamic> resultSongs = await _channel.invokeMethod(
      "queryAudios",
      {
        "sortType": filter.audioSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "type": fixedMap,
        "limit": filter.limit,
      },
    );

    // Convert the result into a list of [SongModel] and return.
    return resultSongs.map((e) => AudioModel(e)).toList();
  }

  @override
  Stream<List<AudioModel>> observeAudios({
    MediaFilter? filter,
    bool? isAsset,
  }) {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Fix the 'type' filter.
    //
    // Convert the 'AudioType' into 'int'.
    // The 'true' and 'false' value into '1' or '2'.
    Map<int, int> fixedMap = {};
    filter.type.forEach((key, value) {
      //
      fixedMap[key.index] = value == true ? 1 : 0;
    });

    // Invoke the observer and convert the result into a list of [AudioModel].
    _onAudiosObserverChanged ??= _audiosObserverChannel.receiveBroadcastStream(
      {
        "sortType": filter.audioSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "type": fixedMap,
        "limit": filter.limit,
      },
    ).asyncMap<List<AudioModel>>(
      (event) => Future.wait(
        event.map<Future<AudioModel>>((m) async => AudioModel(m)),
      ),
    );

    // Return the list.
    return _onAudiosObserverChanged!;
  }

  @override
  Future<List<AlbumModel>> queryAlbums({
    MediaFilter? filter,
  }) async {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Invoke the channel.
    final List<dynamic> resultAlbums = await _channel.invokeMethod(
      "queryAlbums",
      {
        "sortType": filter.albumSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "limit": filter.limit,
      },
    );

    // Convert the result into a list of [AlbumModel] and return.
    return resultAlbums.map((albumInfo) => AlbumModel(albumInfo)).toList();
  }

  @override
  Stream<List<AlbumModel>> observeAlbums({
    MediaFilter? filter,
  }) {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Invoke the observer and convert the result into a list of [AlbumModel].
    _onAlbumsObserverChanged ??= _albumsObserverChannel.receiveBroadcastStream(
      {
        "sortType": filter.albumSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "limit": filter.limit,
      },
    ).asyncMap<List<AlbumModel>>(
      (event) => Future.wait(
        event.map<Future<AlbumModel>>((m) async => AlbumModel(m)),
      ),
    );

    // Return the list.
    return _onAlbumsObserverChanged!;
  }

  @override
  Future<List<ArtistModel>> queryArtists({
    MediaFilter? filter,
  }) async {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Invoke the channel.
    final List<dynamic> resultArtists = await _channel.invokeMethod(
      "queryArtists",
      {
        "sortType": filter.albumSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "limit": filter.limit,
      },
    );

    // Convert the result into a list of [ArtistModel] and return.
    return resultArtists.map((artistInfo) => ArtistModel(artistInfo)).toList();
  }

  @override
  Stream<List<ArtistModel>> observeArtists({
    MediaFilter? filter,
  }) {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Invoke the observer and convert the result into a list of [ArtistModel].
    _onArtistsObserverChanged ??=
        _artistsObserverChannel.receiveBroadcastStream(
      {
        "sortType": filter.albumSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "limit": filter.limit,
      },
    ).asyncMap<List<ArtistModel>>(
      (event) => Future.wait(
        event.map<Future<ArtistModel>>((m) async => ArtistModel(m)),
      ),
    );

    // Return the list.
    return _onArtistsObserverChanged!;
  }

  @override
  Future<List<PlaylistModel>> queryPlaylists({
    MediaFilter? filter,
  }) async {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Invoke the channel.
    final List<dynamic> resultPlaylists = await _channel.invokeMethod(
      "queryPlaylists",
      {
        "sortType": filter.albumSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "limit": filter.limit,
      },
    );

    // Convert the result into a list of [PlaylistModel] and return.
    return resultPlaylists
        .map((playlistInfo) => PlaylistModel(playlistInfo))
        .toList();
  }

  @override
  Stream<List<PlaylistModel>> observePlaylists({
    MediaFilter? filter,
  }) {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Invoke the observer and convert the result into a list of [PlaylistModel].
    _onPlaylistsObserverChanged ??=
        _playlistsObserverChannel.receiveBroadcastStream(
      {
        "sortType": filter.albumSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "limit": filter.limit,
      },
    ).asyncMap<List<PlaylistModel>>(
      (event) => Future.wait(
        event.map<Future<PlaylistModel>>((m) async => PlaylistModel(m)),
      ),
    );

    // Return the list.
    return _onPlaylistsObserverChanged!;
  }

  @override
  Future<List<GenreModel>> queryGenres({
    MediaFilter? filter,
  }) async {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Invoke the channel.
    final List<dynamic> resultGenres = await _channel.invokeMethod(
      "queryGenres",
      {
        "sortType": filter.albumSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "limit": filter.limit,
      },
    );

    // Convert the result into a list of [GenreModel] and return.
    return resultGenres.map((genreInfo) => GenreModel(genreInfo)).toList();
  }

  @override
  Stream<List<GenreModel>> observeGenres({
    MediaFilter? filter,
  }) {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    // Invoke the observer and convert the result into a list of [GenreModel].
    _onGenresObserverChanged ??= _genresObserverChannel.receiveBroadcastStream(
      {
        "sortType": filter.albumSortType?.index,
        "orderType": filter.orderType.index,
        "uri": filter.uriType.index,
        "ignoreCase": filter.ignoreCase,
        "toQuery": filter.toQuery,
        "toRemove": filter.toRemove,
        "limit": filter.limit,
      },
    ).asyncMap<List<GenreModel>>(
      (event) => Future.wait(
        event.map<Future<GenreModel>>((m) async => GenreModel(m)),
      ),
    );

    // Return the list.
    return _onGenresObserverChanged!;
  }

  @override
  Future<ArtworkModel?> queryArtwork(
    int id,
    ArtworkType type, {
    bool? fromAsset,
    bool? fromAppDir,
    MediaFilter? filter,
  }) async {
    // If the filter is null, use the 'default'.
    filter ??= _defaultFilter;

    //
    return _channel.invokeMethod(
      "queryArtwork",
      {
        "type": type.index,
        "id": id,
        "format": filter.artworkFormat?.index ?? ArtworkFormatType.JPEG.index,
        "size": filter.artworkSize ?? 100,
        "quality":
            (filter.artworkQuality != null && filter.artworkQuality! <= 100)
                ? filter.artworkQuality
                : 50,
        "cacheArtwork": filter.cacheArtwork ?? true,
        "cacheTemporarily": filter.cacheTemporarily ?? true,
        "overrideCache": filter.overrideCache ?? false,
      },
    ).then(
      (resultArtwork) => ArtworkModel(resultArtwork),
    );
  }

  @override
  Future<int?> createPlaylist(
    String name, {
    String? author,
    String? desc,
  }) async {
    return await _channel.invokeMethod(
      "createPlaylist",
      {
        "playlistName": name,
        "playlistAuthor": author,
        "playlistDesc": desc,
      },
    );
  }

  @override
  Future<bool> removePlaylist(int playlistId) async {
    return await _channel.invokeMethod(
      "removePlaylist",
      {
        "playlistId": playlistId,
      },
    );
  }

  @override
  Future<bool> addToPlaylist(int playlistId, int audioId) async {
    return await _channel.invokeMethod(
      "addToPlaylist",
      {
        "playlistId": playlistId,
        "audioId": audioId,
      },
    );
  }

  @override
  Future<bool> removeFromPlaylist(int playlistId, int audioId) async {
    return await _channel.invokeMethod(
      "removeFromPlaylist",
      {
        "playlistId": playlistId,
        "audioId": audioId,
      },
    );
  }

  @override
  Future<bool> moveItemTo(int playlistId, int from, int to) async {
    return await _channel.invokeMethod(
      "moveItemTo",
      {
        "playlistId": playlistId,
        "from": from,
        "to": to,
      },
    );
  }

  @override
  Future<bool> renamePlaylist(int playlistId, String newName) async {
    return await _channel.invokeMethod(
      "renamePlaylist",
      {
        "playlistId": playlistId,
        "newPlName": newName,
      },
    );
  }

  @override
  Future<bool> permissionsStatus() async {
    return await _channel.invokeMethod("permissionsStatus");
  }

  @override
  Future<bool> permissionsRequest() async {
    return await _channel.invokeMethod("permissionsRequest");
  }

  @override
  Future<DeviceModel> queryDeviceInfo() async {
    return _channel
        .invokeMethod("queryDeviceInfo")
        .then((deviceResult) => DeviceModel(deviceResult));
  }

  @override
  Future<bool> scanMedia(String path) async {
    return await _channel.invokeMethod('scan', {"path": path});
  }

  @override
  Future<ObserversModel> observersStatus() async {
    return _channel
        .invokeMethod('observersStatus')
        .then((observersResult) => ObserversModel(observersResult));
  }
}
