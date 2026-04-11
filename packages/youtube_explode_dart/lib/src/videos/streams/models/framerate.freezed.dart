// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'framerate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Framerate {
  /// Framerate as frames per second
  num get framesPerSecond;

  /// Create a copy of Framerate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FramerateCopyWith<Framerate> get copyWith =>
      _$FramerateCopyWithImpl<Framerate>(this as Framerate, _$identity);

  /// Serializes this Framerate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Framerate &&
            (identical(other.framesPerSecond, framesPerSecond) ||
                other.framesPerSecond == framesPerSecond));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, framesPerSecond);
}

/// @nodoc
abstract mixin class $FramerateCopyWith<$Res> {
  factory $FramerateCopyWith(Framerate value, $Res Function(Framerate) _then) =
      _$FramerateCopyWithImpl;
  @useResult
  $Res call({num framesPerSecond});
}

/// @nodoc
class _$FramerateCopyWithImpl<$Res> implements $FramerateCopyWith<$Res> {
  _$FramerateCopyWithImpl(this._self, this._then);

  final Framerate _self;
  final $Res Function(Framerate) _then;

  /// Create a copy of Framerate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? framesPerSecond = null,
  }) {
    return _then(_self.copyWith(
      framesPerSecond: null == framesPerSecond
          ? _self.framesPerSecond
          : framesPerSecond // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _Framerate extends Framerate {
  const _Framerate(this.framesPerSecond) : super._();
  factory _Framerate.fromJson(Map<String, dynamic> json) =>
      _$FramerateFromJson(json);

  /// Framerate as frames per second
  @override
  final num framesPerSecond;

  /// Create a copy of Framerate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FramerateCopyWith<_Framerate> get copyWith =>
      __$FramerateCopyWithImpl<_Framerate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FramerateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Framerate &&
            (identical(other.framesPerSecond, framesPerSecond) ||
                other.framesPerSecond == framesPerSecond));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, framesPerSecond);
}

/// @nodoc
abstract mixin class _$FramerateCopyWith<$Res>
    implements $FramerateCopyWith<$Res> {
  factory _$FramerateCopyWith(
          _Framerate value, $Res Function(_Framerate) _then) =
      __$FramerateCopyWithImpl;
  @override
  @useResult
  $Res call({num framesPerSecond});
}

/// @nodoc
class __$FramerateCopyWithImpl<$Res> implements _$FramerateCopyWith<$Res> {
  __$FramerateCopyWithImpl(this._self, this._then);

  final _Framerate _self;
  final $Res Function(_Framerate) _then;

  /// Create a copy of Framerate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? framesPerSecond = null,
  }) {
    return _then(_Framerate(
      null == framesPerSecond
          ? _self.framesPerSecond
          : framesPerSecond // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

// dart format on
