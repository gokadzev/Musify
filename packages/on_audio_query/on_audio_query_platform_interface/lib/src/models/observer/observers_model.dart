part of models_controller;

/// [ObserversModel] which contains information about every [Observer].
class ObserversModel {
  ObserversModel(this._info);

  //
  final Map<dynamic, dynamic> _info;

  /// Will return [true] if [songs] are being observed.
  bool get songsObserver => _info["songs_observer"];

  /// Will return [true] if [albums] are being observed.
  bool get albumsObserver => _info["albums_observer"];

  /// Will return [true] if [playlists] are being observed.
  bool get playlistsObserver => _info["playlists_observer"];

  /// Will return [true] if [artists] are being observed.
  bool get artistsObserver => _info["artists_observer"];

  /// Will return [true] if [genres] are being observed.
  bool get genresObserver => _info["genres_observer"];

  @override
  String toString() => '$_info';
}
