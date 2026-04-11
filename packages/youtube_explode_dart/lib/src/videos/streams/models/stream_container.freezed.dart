// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_container.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StreamContainer {
  /// Container name.
  /// Can be used as file extension
  String get name;

  /// Create a copy of StreamContainer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StreamContainerCopyWith<StreamContainer> get copyWith =>
      _$StreamContainerCopyWithImpl<StreamContainer>(
          this as StreamContainer, _$identity);

  /// Serializes this StreamContainer to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StreamContainer &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name);
}

/// @nodoc
abstract mixin class $StreamContainerCopyWith<$Res> {
  factory $StreamContainerCopyWith(
          StreamContainer value, $Res Function(StreamContainer) _then) =
      _$StreamContainerCopyWithImpl;
  @useResult
  $Res call({String name});
}

/// @nodoc
class _$StreamContainerCopyWithImpl<$Res>
    implements $StreamContainerCopyWith<$Res> {
  _$StreamContainerCopyWithImpl(this._self, this._then);

  final StreamContainer _self;
  final $Res Function(StreamContainer) _then;

  /// Create a copy of StreamContainer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _StreamContainer extends StreamContainer {
  const _StreamContainer(this.name) : super._();
  factory _StreamContainer.fromJson(Map<String, dynamic> json) =>
      _$StreamContainerFromJson(json);

  /// Container name.
  /// Can be used as file extension
  @override
  final String name;

  /// Create a copy of StreamContainer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StreamContainerCopyWith<_StreamContainer> get copyWith =>
      __$StreamContainerCopyWithImpl<_StreamContainer>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StreamContainerToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StreamContainer &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name);
}

/// @nodoc
abstract mixin class _$StreamContainerCopyWith<$Res>
    implements $StreamContainerCopyWith<$Res> {
  factory _$StreamContainerCopyWith(
          _StreamContainer value, $Res Function(_StreamContainer) _then) =
      __$StreamContainerCopyWithImpl;
  @override
  @useResult
  $Res call({String name});
}

/// @nodoc
class __$StreamContainerCopyWithImpl<$Res>
    implements _$StreamContainerCopyWith<$Res> {
  __$StreamContainerCopyWithImpl(this._self, this._then);

  final _StreamContainer _self;
  final $Res Function(_StreamContainer) _then;

  /// Create a copy of StreamContainer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
  }) {
    return _then(_StreamContainer(
      null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
