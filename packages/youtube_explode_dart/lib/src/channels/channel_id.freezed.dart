// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_id.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelId {
  /// ID as a string.
  String get value;

  /// Create a copy of ChannelId
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChannelIdCopyWith<ChannelId> get copyWith =>
      _$ChannelIdCopyWithImpl<ChannelId>(this as ChannelId, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChannelId &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

/// @nodoc
abstract mixin class $ChannelIdCopyWith<$Res> {
  factory $ChannelIdCopyWith(ChannelId value, $Res Function(ChannelId) _then) =
      _$ChannelIdCopyWithImpl;
  @useResult
  $Res call({String value});
}

/// @nodoc
class _$ChannelIdCopyWithImpl<$Res> implements $ChannelIdCopyWith<$Res> {
  _$ChannelIdCopyWithImpl(this._self, this._then);

  final ChannelId _self;
  final $Res Function(ChannelId) _then;

  /// Create a copy of ChannelId
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

class _ChannelId extends ChannelId {
  const _ChannelId(this.value) : super._();

  /// ID as a string.
  @override
  final String value;

  /// Create a copy of ChannelId
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChannelIdCopyWith<_ChannelId> get copyWith =>
      __$ChannelIdCopyWithImpl<_ChannelId>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChannelId &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

/// @nodoc
abstract mixin class _$ChannelIdCopyWith<$Res>
    implements $ChannelIdCopyWith<$Res> {
  factory _$ChannelIdCopyWith(
          _ChannelId value, $Res Function(_ChannelId) _then) =
      __$ChannelIdCopyWithImpl;
  @override
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$ChannelIdCopyWithImpl<$Res> implements _$ChannelIdCopyWith<$Res> {
  __$ChannelIdCopyWithImpl(this._self, this._then);

  final _ChannelId _self;
  final $Res Function(_ChannelId) _then;

  /// Create a copy of ChannelId
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
  }) {
    return _then(_ChannelId(
      null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
