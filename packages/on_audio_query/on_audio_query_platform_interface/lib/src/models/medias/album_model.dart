part of models_controller;

/// [AlbumModel] that contains all [Album] Information.
class AlbumModel extends MediaModel {
  AlbumModel(this._info) : super(_info['_id']);

  //The type dynamic is used for both but, the map is always based in [String, dynamic]
  final Map<dynamic, dynamic> _info;

  /// Return album [album]
  String get album => _info["album"];

  /// Return album [artist]
  String? get artist => _info["artist"];

  /// Return album [artistId]
  int? get artistId => _info["artist_id"];

  /// Return album [numOfSongs]
  int get numOfSongs => _info["numsongs"];

  /// Return a map with all [keys] and [values] from specific album.
  Map get getMap => _info;

  ///
  AlbumModel copyWith({
    int? id,
    String? album,
    String? artist,
    int? artistId,
    int? numOfSongs,
  }) {
    return AlbumModel({
      "_id": id ?? this.id,
      "album": album ?? this.album,
      "artist": artist ?? this.artist,
      "artist_id": artistId ?? this.artistId,
      "numsongs": numOfSongs ?? this.numOfSongs,
    });
  }

  @override
  String toString() => '$_info';
}
