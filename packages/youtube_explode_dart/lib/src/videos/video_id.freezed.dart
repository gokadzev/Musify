// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_id.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoId {
  /// ID as string.
  String get value;

  /// Create a copy of VideoId
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VideoIdCopyWith<VideoId> get copyWith =>
      _$VideoIdCopyWithImpl<VideoId>(this as VideoId, _$identity);

  /// Serializes this VideoId to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VideoId &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);
}

/// @nodoc
abstract mixin class $VideoIdCopyWith<$Res> {
  factory $VideoIdCopyWith(VideoId value, $Res Function(VideoId) _then) =
      _$VideoIdCopyWithImpl;
  @useResult
  $Res call({String value});
}

/// @nodoc
class _$VideoIdCopyWithImpl<$Res> implements $VideoIdCopyWith<$Res> {
  _$VideoIdCopyWithImpl(this._self, this._then);

  final VideoId _self;
  final $Res Function(VideoId) _then;

  /// Create a copy of VideoId
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_self.copyWith(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _VideoId extends VideoId {
  const _VideoId(this.value) : super._();
  factory _VideoId.fromJson(Map<String, dynamic> json) =>
      _$VideoIdFromJson(json);

  /// ID as string.
  @override
  final String value;

  /// Create a copy of VideoId
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VideoIdCopyWith<_VideoId> get copyWith =>
      __$VideoIdCopyWithImpl<_VideoId>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$VideoIdToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VideoId &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);
}

/// @nodoc
abstract mixin class _$VideoIdCopyWith<$Res> implements $VideoIdCopyWith<$Res> {
  factory _$VideoIdCopyWith(_VideoId value, $Res Function(_VideoId) _then) =
      __$VideoIdCopyWithImpl;
  @override
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$VideoIdCopyWithImpl<$Res> implements _$VideoIdCopyWith<$Res> {
  __$VideoIdCopyWithImpl(this._self, this._then);

  final _VideoId _self;
  final $Res Function(_VideoId) _then;

  /// Create a copy of VideoId
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
  }) {
    return _then(_VideoId(
      null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
