part of models_controller;

/// [GenreModel] that contains all [Genre] Information.
class GenreModel extends MediaModel {
  GenreModel(this._info) : super(_info['_id']);

  //The type dynamic is used for both but, the map is always based in [String, dynamic]
  final Map<dynamic, dynamic> _info;

  /// Return [genre] name
  String get genre => _info["name"];

  ///Return genre [numOfSongs]
  int get numOfSongs => _info["num_of_songs"];

  /// Return a map with all [keys] and [values] from specific genre.
  Map get getMap => _info;

  ///
  GenreModel copyWith({
    int? id,
    String? genre,
    int? numOfSongs,
  }) {
    return GenreModel({
      "_id": id ?? this.id,
      "name": genre ?? this.genre,
      "num_of_songs": numOfSongs ?? this.numOfSongs,
    });
  }

  @override
  String toString() => '$_info';
}
