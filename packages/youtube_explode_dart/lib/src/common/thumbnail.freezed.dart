// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'thumbnail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Thumbnail {
  /// Image url.
  Uri get url;

  /// Image height.
  int get height;

  /// Image width.
  int get width;

  /// Create a copy of Thumbnail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ThumbnailCopyWith<Thumbnail> get copyWith =>
      _$ThumbnailCopyWithImpl<Thumbnail>(this as Thumbnail, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Thumbnail &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.width, width) || other.width == width));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url, height, width);

  @override
  String toString() {
    return 'Thumbnail(url: $url, height: $height, width: $width)';
  }
}

/// @nodoc
abstract mixin class $ThumbnailCopyWith<$Res> {
  factory $ThumbnailCopyWith(Thumbnail value, $Res Function(Thumbnail) _then) =
      _$ThumbnailCopyWithImpl;
  @useResult
  $Res call({Uri url, int height, int width});
}

/// @nodoc
class _$ThumbnailCopyWithImpl<$Res> implements $ThumbnailCopyWith<$Res> {
  _$ThumbnailCopyWithImpl(this._self, this._then);

  final Thumbnail _self;
  final $Res Function(Thumbnail) _then;

  /// Create a copy of Thumbnail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? height = null,
    Object? width = null,
  }) {
    return _then(_self.copyWith(
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as Uri,
      height: null == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _Thumbnail implements Thumbnail {
  const _Thumbnail(this.url, this.height, this.width);

  /// Image url.
  @override
  final Uri url;

  /// Image height.
  @override
  final int height;

  /// Image width.
  @override
  final int width;

  /// Create a copy of Thumbnail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ThumbnailCopyWith<_Thumbnail> get copyWith =>
      __$ThumbnailCopyWithImpl<_Thumbnail>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Thumbnail &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.width, width) || other.width == width));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url, height, width);

  @override
  String toString() {
    return 'Thumbnail(url: $url, height: $height, width: $width)';
  }
}

/// @nodoc
abstract mixin class _$ThumbnailCopyWith<$Res>
    implements $ThumbnailCopyWith<$Res> {
  factory _$ThumbnailCopyWith(
          _Thumbnail value, $Res Function(_Thumbnail) _then) =
      __$ThumbnailCopyWithImpl;
  @override
  @useResult
  $Res call({Uri url, int height, int width});
}

/// @nodoc
class __$ThumbnailCopyWithImpl<$Res> implements _$ThumbnailCopyWith<$Res> {
  __$ThumbnailCopyWithImpl(this._self, this._then);

  final _Thumbnail _self;
  final $Res Function(_Thumbnail) _then;

  /// Create a copy of Thumbnail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? url = null,
    Object? height = null,
    Object? width = null,
  }) {
    return _then(_Thumbnail(
      null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as Uri,
      null == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      null == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
