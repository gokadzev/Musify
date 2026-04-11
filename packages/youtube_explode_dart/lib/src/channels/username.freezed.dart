// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'username.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Username {
  /// User name as string.
  String get value;

  /// Create a copy of Username
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UsernameCopyWith<Username> get copyWith =>
      _$UsernameCopyWithImpl<Username>(this as Username, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Username &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    return 'Username(value: $value)';
  }
}

/// @nodoc
abstract mixin class $UsernameCopyWith<$Res> {
  factory $UsernameCopyWith(Username value, $Res Function(Username) _then) =
      _$UsernameCopyWithImpl;
  @useResult
  $Res call({String value});
}

/// @nodoc
class _$UsernameCopyWithImpl<$Res> implements $UsernameCopyWith<$Res> {
  _$UsernameCopyWithImpl(this._self, this._then);

  final Username _self;
  final $Res Function(Username) _then;

  /// Create a copy of Username
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

class _Username implements Username {
  const _Username(this.value);

  /// User name as string.
  @override
  final String value;

  /// Create a copy of Username
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UsernameCopyWith<_Username> get copyWith =>
      __$UsernameCopyWithImpl<_Username>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Username &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    return 'Username._(value: $value)';
  }
}

/// @nodoc
abstract mixin class _$UsernameCopyWith<$Res>
    implements $UsernameCopyWith<$Res> {
  factory _$UsernameCopyWith(_Username value, $Res Function(_Username) _then) =
      __$UsernameCopyWithImpl;
  @override
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$UsernameCopyWithImpl<$Res> implements _$UsernameCopyWith<$Res> {
  __$UsernameCopyWithImpl(this._self, this._then);

  final _Username _self;
  final $Res Function(_Username) _then;

  /// Create a copy of Username
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
  }) {
    return _then(_Username(
      null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
