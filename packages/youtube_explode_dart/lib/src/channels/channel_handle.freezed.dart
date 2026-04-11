// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_handle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelHandle {
  /// Handle as string.
  String get value;

  /// Create a copy of ChannelHandle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChannelHandleCopyWith<ChannelHandle> get copyWith =>
      _$ChannelHandleCopyWithImpl<ChannelHandle>(
          this as ChannelHandle, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChannelHandle &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    return 'ChannelHandle(value: $value)';
  }
}

/// @nodoc
abstract mixin class $ChannelHandleCopyWith<$Res> {
  factory $ChannelHandleCopyWith(
          ChannelHandle value, $Res Function(ChannelHandle) _then) =
      _$ChannelHandleCopyWithImpl;
  @useResult
  $Res call({String value});
}

/// @nodoc
class _$ChannelHandleCopyWithImpl<$Res>
    implements $ChannelHandleCopyWith<$Res> {
  _$ChannelHandleCopyWithImpl(this._self, this._then);

  final ChannelHandle _self;
  final $Res Function(ChannelHandle) _then;

  /// Create a copy of ChannelHandle
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

class _ChannelHandle implements ChannelHandle {
  const _ChannelHandle(this.value);

  /// Handle as string.
  @override
  final String value;

  /// Create a copy of ChannelHandle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChannelHandleCopyWith<_ChannelHandle> get copyWith =>
      __$ChannelHandleCopyWithImpl<_ChannelHandle>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChannelHandle &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    return 'ChannelHandle._(value: $value)';
  }
}

/// @nodoc
abstract mixin class _$ChannelHandleCopyWith<$Res>
    implements $ChannelHandleCopyWith<$Res> {
  factory _$ChannelHandleCopyWith(
          _ChannelHandle value, $Res Function(_ChannelHandle) _then) =
      __$ChannelHandleCopyWithImpl;
  @override
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$ChannelHandleCopyWithImpl<$Res>
    implements _$ChannelHandleCopyWith<$Res> {
  __$ChannelHandleCopyWithImpl(this._self, this._then);

  final _ChannelHandle _self;
  final $Res Function(_ChannelHandle) _then;

  /// Create a copy of ChannelHandle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
  }) {
    return _then(_ChannelHandle(
      null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
