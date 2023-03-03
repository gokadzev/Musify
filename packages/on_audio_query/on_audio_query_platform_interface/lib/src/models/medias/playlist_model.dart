part of models_controller;

/// [PlaylistModel] that contains all [Playlist] Information.
class PlaylistModel extends MediaModel {
  PlaylistModel(this._info) : super(_info['_id']);

  //The type dynamic is used for both but, the map is always based in [String, dynamic]
  final Map<dynamic, dynamic> _info;

  ///Return playlist [playlist]
  String get playlist => _info["name"];

  ///Return playlist [data]
  String? get data => _info["_data"];

  ///Return playlist [dateAdded]
  int? get dateAdded => _info["date_added"];

  ///Return playlist [dateModified]
  int? get dateModified => _info["date_modified"];

  ///Return playlist [numOfSongs]
  int get numOfSongs => _info["num_of_songs"];

  /// Return a map with all [keys] and [values] from specific playlist.
  Map get getMap => _info;

  ///
  PlaylistModel copyWith({
    int? id,
    String? playlist,
    String? data,
    int? dateAdded,
    int? dateModified,
    int? numOfSongs,
  }) {
    return PlaylistModel({
      "_id": id ?? this.id,
      "name": playlist ?? this.playlist,
      "_data": data ?? this.data,
      "date_added": dateAdded ?? this.dateAdded,
      "date_modified": dateModified ?? this.dateModified,
      "num_of_songs": numOfSongs ?? this.numOfSongs,
    });
  }

  @override
  String toString() => '$_info';
}
