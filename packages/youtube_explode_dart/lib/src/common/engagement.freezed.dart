// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'engagement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Engagement {
  /// View count.
  int get viewCount;

  /// Like count.
  int? get likeCount;

  /// Dislike count.
  int? get dislikeCount;

  /// Create a copy of Engagement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EngagementCopyWith<Engagement> get copyWith =>
      _$EngagementCopyWithImpl<Engagement>(this as Engagement, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Engagement &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.dislikeCount, dislikeCount) ||
                other.dislikeCount == dislikeCount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, viewCount, likeCount, dislikeCount);

  @override
  String toString() {
    return 'Engagement(viewCount: $viewCount, likeCount: $likeCount, dislikeCount: $dislikeCount)';
  }
}

/// @nodoc
abstract mixin class $EngagementCopyWith<$Res> {
  factory $EngagementCopyWith(
          Engagement value, $Res Function(Engagement) _then) =
      _$EngagementCopyWithImpl;
  @useResult
  $Res call({int viewCount, int? likeCount, int? dislikeCount});
}

/// @nodoc
class _$EngagementCopyWithImpl<$Res> implements $EngagementCopyWith<$Res> {
  _$EngagementCopyWithImpl(this._self, this._then);

  final Engagement _self;
  final $Res Function(Engagement) _then;

  /// Create a copy of Engagement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? viewCount = null,
    Object? likeCount = freezed,
    Object? dislikeCount = freezed,
  }) {
    return _then(_self.copyWith(
      viewCount: null == viewCount
          ? _self.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      likeCount: freezed == likeCount
          ? _self.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int?,
      dislikeCount: freezed == dislikeCount
          ? _self.dislikeCount
          : dislikeCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _Engagement extends Engagement {
  const _Engagement(this.viewCount, this.likeCount, this.dislikeCount)
      : super._();

  /// View count.
  @override
  final int viewCount;

  /// Like count.
  @override
  final int? likeCount;

  /// Dislike count.
  @override
  final int? dislikeCount;

  /// Create a copy of Engagement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EngagementCopyWith<_Engagement> get copyWith =>
      __$EngagementCopyWithImpl<_Engagement>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Engagement &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.dislikeCount, dislikeCount) ||
                other.dislikeCount == dislikeCount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, viewCount, likeCount, dislikeCount);

  @override
  String toString() {
    return 'Engagement(viewCount: $viewCount, likeCount: $likeCount, dislikeCount: $dislikeCount)';
  }
}

/// @nodoc
abstract mixin class _$EngagementCopyWith<$Res>
    implements $EngagementCopyWith<$Res> {
  factory _$EngagementCopyWith(
          _Engagement value, $Res Function(_Engagement) _then) =
      __$EngagementCopyWithImpl;
  @override
  @useResult
  $Res call({int viewCount, int? likeCount, int? dislikeCount});
}

/// @nodoc
class __$EngagementCopyWithImpl<$Res> implements _$EngagementCopyWith<$Res> {
  __$EngagementCopyWithImpl(this._self, this._then);

  final _Engagement _self;
  final $Res Function(_Engagement) _then;

  /// Create a copy of Engagement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? viewCount = null,
    Object? likeCount = freezed,
    Object? dislikeCount = freezed,
  }) {
    return _then(_Engagement(
      null == viewCount
          ? _self.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      freezed == likeCount
          ? _self.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int?,
      freezed == dislikeCount
          ? _self.dislikeCount
          : dislikeCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
