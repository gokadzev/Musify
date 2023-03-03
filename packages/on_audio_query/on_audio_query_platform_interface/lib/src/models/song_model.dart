part of models_controller;

/// [SongModel] that contains all [Song] Information.
@Deprecated("Deprecated after [3.0.0]. Use [AudioModel] instead")
class SongModel {
  SongModel(this._info);

  //The type dynamic is used for both but, the map is always based in [String, dynamic]
  final Map<dynamic, dynamic> _info;

  /// Return song [id]
  int get id => _info["_id"];

  /// Return song [id] from a playlist.
  int? get audioId => _info["audio_id"];

  /// Return song [data]
  String get data => _info["_data"];

  /// Return song [uri]
  String? get uri => _info["_uri"];

  /// Return song [displayName]
  String get displayName => _info["_display_name"];

  /// Return song [displayName] without Extension
  String get displayNameWOExt => _info["_display_name_wo_ext"];

  /// Return song [size]
  int get size => _info["_size"];

  /// Return song [album]
  String? get album => _info["album"];

  /// Return song [albumId]
  int? get albumId => _info["album_id"];

  /// Return song [artist]
  String? get artist => _info["artist"];

  /// Return song [artistId]
  int? get artistId => _info["artist_id"];

  /// Return song [genre]
  ///
  /// Important:
  ///   * Only Api >= 30/Android 11
  String? get genre => _info["genre"];

  /// Return song [genreId]
  ///
  /// Important:
  ///   * Only Api >= 30/Android 11
  int? get genreId => _info["genre_id"];

  /// Return song [bookmark]
  int? get bookmark => _info["bookmark"];

  /// Return song [composer]
  String? get composer => _info["composer"];

  /// Return song [dateAdded]
  int? get dateAdded => _info["date_added"];

  /// Return song [dateModified]
  int? get dateModified => _info["date_modified"];

  /// Return song [duration]
  int? get duration => _info["duration"];

  /// Return song [title]
  String get title => _info["title"];

  /// Return song [track]
  int? get track => _info["track"];

  /// Return song only the [fileExtension]
  String get fileExtension => _info["file_extension"];

  /// Return song type: [isAlarm]
  bool? get isAlarm => _info["is_alarm"];

  /// Return song type: [isAudioBook]
  ///
  /// Important:
  ///   * Only Api >= 29/Android 10
  bool? get isAudioBook => _info["is_audiobook"];

  /// Return song type: [isMusic]
  bool? get isMusic => _info["is_music"];

  /// Return song type: [isNotification]
  bool? get isNotification => _info["is_notification"];

  /// Return song type: [isPodcast]
  bool? get isPodcast => _info["is_podcast"];

  /// Return song type: [isRingtone]
  bool? get isRingtone => _info["is_ringtone"];

  /// Return a map with all [keys] and [values] from specific song.
  Map get getMap => _info;

  ///
  AudioModel toAudioModel() => AudioModel(_info);

  ///
  SongModel copyWith({
    int? id,
    int? audioId,
    String? data,
    String? uri,
    String? displayName,
    String? displayNameWOExt,
    int? size,
    String? album,
    int? albumId,
    String? artist,
    int? artistId,
    String? genre,
    int? genreId,
    int? bookmark,
    String? composer,
    int? dateAdded,
    int? dateModified,
    int? duration,
    String? title,
    int? track,
    String? fileExtension,
    bool? isAlarm,
    bool? isAudioBook,
    bool? isMusic,
    bool? isNotification,
    bool? isPodcast,
    bool? isRingtone,
  }) {
    return SongModel({
      "_id": id ?? this.id,
      "audio_id": audioId ?? this.audioId,
      "_data": data ?? this.data,
      "_uri": uri ?? this.uri,
      "_display_name": displayName ?? this.displayName,
      "_display_name_wo_ext": displayNameWOExt ?? this.displayNameWOExt,
      "_size": size ?? this.size,
      "album": album ?? this.album,
      "album_id": albumId ?? this.albumId,
      "artist": artist ?? this.artist,
      "artist_id": artistId ?? this.artistId,
      "genre": genre ?? this.genre,
      "genre_id": genreId ?? this.genreId,
      "bookmark": bookmark ?? this.bookmark,
      "composer": composer ?? this.composer,
      "date_added": dateAdded ?? this.dateAdded,
      "date_modified": dateModified ?? this.dateModified,
      "duration": duration ?? this.duration,
      "title": title ?? this.title,
      "track": track ?? this.track,
      "file_extension": fileExtension ?? this.fileExtension,
      "is_alarm": isAlarm ?? this.isAlarm,
      "is_audiobook": isAudioBook ?? this.isAudioBook,
      "is_music": isMusic ?? this.isMusic,
      "is_notification": isNotification ?? this.isNotification,
      "is_podcast": isPodcast ?? this.isPodcast,
      "is_ringtone": isRingtone ?? this.isRingtone,
    });
  }

  @override
  String toString() => '$_info';
}
