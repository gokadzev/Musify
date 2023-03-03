/*
=============
Author: Lucas Josino
Github: https://github.com/LucJosin
Website: https://www.lucasjosino.com/
=============
Plugin/Id: on_audio_query#0
Homepage: https://github.com/LucJosin/on_audio_query
Homepage(Web): https://github.com/LucJosin/on_audio_query/tree/main/on_audio_query_web
Pub: https://pub.dev/packages/on_audio_query
License: https://github.com/LucJosin/on_audio_query/blob/main/on_audio_query/LICENSE
Copyright: © 2021, Lucas Josino. All rights reserved.
=============
*/

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:on_audio_query_platform_interface/on_audio_query_platform_interface.dart';

/// A web implementation of the OnAudioQueryWeb plugin.
class OnAudioQueryPlugin extends OnAudioQueryPlatform {
  /// Registers this class as the default instance of [OnAudioQueryPlatform].
  static void registerWith(Registrar registrar) {
    OnAudioQueryPlatform.instance = OnAudioQueryPlugin();
  }

  @override
  Future<List<AudioModel>> queryAudios({MediaFilter? filter}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<AlbumModel>> queryAlbums({MediaFilter? filter}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ArtistModel>> queryArtists({MediaFilter? filter}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<GenreModel>> queryGenres({MediaFilter? filter}) async {
    throw UnimplementedError();
  }

  @override
  Future<ArtworkModel> queryArtwork(
    int id,
    ArtworkType type, {
    bool? fromAsset,
    bool? fromAppDir,
    MediaFilter? filter,
  }) async {
    throw UnimplementedError();
  }
}
