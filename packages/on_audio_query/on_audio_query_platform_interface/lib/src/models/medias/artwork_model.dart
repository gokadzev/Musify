part of models_controller;

/// [ArtworkModel] that contains all [Image] information.
class ArtworkModel extends MediaModel {
  ArtworkModel(this._info) : super(_info['_id']);

  //The type dynamic is used for both but, the map is always based in [String, dynamic]
  final Map<dynamic, dynamic> _info;

  /// Return the [artwork]
  Uint8List? get artwork => _info["artwork"];

  /// Return artwork [path].
  String? get path => _info["path"];

  /// Return artwork [extension]
  Stream? get type => _info["type"];

  /// Return a map with all [keys] and [values] from specific artwork.
  Map get getMap => _info;

  ///
  ArtworkModel copyWith({
    int? id,
    Uint8List? artwork,
    String? path,
    String? type,
  }) {
    return ArtworkModel({
      "_id": id ?? this.id,
      "artwork": artwork ?? this.artwork,
      "path": path ?? this.path,
      "ext": type ?? this.type,
    });
  }

  @override
  String toString() => '$_info';
}
