// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Playlist {
  /// Playlist ID.
  PlaylistId get id;

  /// Playlist title.
  String get title;

  /// Playlist author.
  /// Can be null if it's a system playlist (e.g. Video Mix, Topics, etc.).
  String get author;

  /// Playlist description.
  String get description;

  /// Available thumbnails for this playlist.
  /// Can be null if the playlist is empty.
  ThumbnailSet get thumbnails;

  /// Engagement statistics.
  Engagement get engagement;

  /// Total videos in this playlist.
  int? get videoCount;

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlaylistCopyWith<Playlist> get copyWith =>
      _$PlaylistCopyWithImpl<Playlist>(this as Playlist, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Playlist &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.thumbnails, thumbnails) ||
                other.thumbnails == thumbnails) &&
            (identical(other.engagement, engagement) ||
                other.engagement == engagement) &&
            (identical(other.videoCount, videoCount) ||
                other.videoCount == videoCount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, title, author, description,
      thumbnails, engagement, videoCount);

  @override
  String toString() {
    return 'Playlist(id: $id, title: $title, author: $author, description: $description, thumbnails: $thumbnails, engagement: $engagement, videoCount: $videoCount)';
  }
}

/// @nodoc
abstract mixin class $PlaylistCopyWith<$Res> {
  factory $PlaylistCopyWith(Playlist value, $Res Function(Playlist) _then) =
      _$PlaylistCopyWithImpl;
  @useResult
  $Res call(
      {PlaylistId id,
      String title,
      String author,
      String description,
      ThumbnailSet thumbnails,
      Engagement engagement,
      int? videoCount});

  $PlaylistIdCopyWith<$Res> get id;
  $ThumbnailSetCopyWith<$Res> get thumbnails;
  $EngagementCopyWith<$Res> get engagement;
}

/// @nodoc
class _$PlaylistCopyWithImpl<$Res> implements $PlaylistCopyWith<$Res> {
  _$PlaylistCopyWithImpl(this._self, this._then);

  final Playlist _self;
  final $Res Function(Playlist) _then;

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? description = null,
    Object? thumbnails = null,
    Object? engagement = null,
    Object? videoCount = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as PlaylistId,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnails: null == thumbnails
          ? _self.thumbnails
          : thumbnails // ignore: cast_nullable_to_non_nullable
              as ThumbnailSet,
      engagement: null == engagement
          ? _self.engagement
          : engagement // ignore: cast_nullable_to_non_nullable
              as Engagement,
      videoCount: freezed == videoCount
          ? _self.videoCount
          : videoCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistIdCopyWith<$Res> get id {
    return $PlaylistIdCopyWith<$Res>(_self.id, (value) {
      return _then(_self.copyWith(id: value));
    });
  }

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ThumbnailSetCopyWith<$Res> get thumbnails {
    return $ThumbnailSetCopyWith<$Res>(_self.thumbnails, (value) {
      return _then(_self.copyWith(thumbnails: value));
    });
  }

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EngagementCopyWith<$Res> get engagement {
    return $EngagementCopyWith<$Res>(_self.engagement, (value) {
      return _then(_self.copyWith(engagement: value));
    });
  }
}

/// @nodoc

class _Playlist extends Playlist {
  const _Playlist(this.id, this.title, this.author, this.description,
      this.thumbnails, this.engagement, this.videoCount)
      : super._();

  /// Playlist ID.
  @override
  final PlaylistId id;

  /// Playlist title.
  @override
  final String title;

  /// Playlist author.
  /// Can be null if it's a system playlist (e.g. Video Mix, Topics, etc.).
  @override
  final String author;

  /// Playlist description.
  @override
  final String description;

  /// Available thumbnails for this playlist.
  /// Can be null if the playlist is empty.
  @override
  final ThumbnailSet thumbnails;

  /// Engagement statistics.
  @override
  final Engagement engagement;

  /// Total videos in this playlist.
  @override
  final int? videoCount;

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlaylistCopyWith<_Playlist> get copyWith =>
      __$PlaylistCopyWithImpl<_Playlist>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Playlist &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.thumbnails, thumbnails) ||
                other.thumbnails == thumbnails) &&
            (identical(other.engagement, engagement) ||
                other.engagement == engagement) &&
            (identical(other.videoCount, videoCount) ||
                other.videoCount == videoCount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, title, author, description,
      thumbnails, engagement, videoCount);

  @override
  String toString() {
    return 'Playlist(id: $id, title: $title, author: $author, description: $description, thumbnails: $thumbnails, engagement: $engagement, videoCount: $videoCount)';
  }
}

/// @nodoc
abstract mixin class _$PlaylistCopyWith<$Res>
    implements $PlaylistCopyWith<$Res> {
  factory _$PlaylistCopyWith(_Playlist value, $Res Function(_Playlist) _then) =
      __$PlaylistCopyWithImpl;
  @override
  @useResult
  $Res call(
      {PlaylistId id,
      String title,
      String author,
      String description,
      ThumbnailSet thumbnails,
      Engagement engagement,
      int? videoCount});

  @override
  $PlaylistIdCopyWith<$Res> get id;
  @override
  $ThumbnailSetCopyWith<$Res> get thumbnails;
  @override
  $EngagementCopyWith<$Res> get engagement;
}

/// @nodoc
class __$PlaylistCopyWithImpl<$Res> implements _$PlaylistCopyWith<$Res> {
  __$PlaylistCopyWithImpl(this._self, this._then);

  final _Playlist _self;
  final $Res Function(_Playlist) _then;

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? description = null,
    Object? thumbnails = null,
    Object? engagement = null,
    Object? videoCount = freezed,
  }) {
    return _then(_Playlist(
      null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as PlaylistId,
      null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      null == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      null == thumbnails
          ? _self.thumbnails
          : thumbnails // ignore: cast_nullable_to_non_nullable
              as ThumbnailSet,
      null == engagement
          ? _self.engagement
          : engagement // ignore: cast_nullable_to_non_nullable
              as Engagement,
      freezed == videoCount
          ? _self.videoCount
          : videoCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistIdCopyWith<$Res> get id {
    return $PlaylistIdCopyWith<$Res>(_self.id, (value) {
      return _then(_self.copyWith(id: value));
    });
  }

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ThumbnailSetCopyWith<$Res> get thumbnails {
    return $ThumbnailSetCopyWith<$Res>(_self.thumbnails, (value) {
      return _then(_self.copyWith(thumbnails: value));
    });
  }

  /// Create a copy of Playlist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EngagementCopyWith<$Res> get engagement {
    return $EngagementCopyWith<$Res>(_self.engagement, (value) {
      return _then(_self.copyWith(engagement: value));
    });
  }
}

// dart format on
