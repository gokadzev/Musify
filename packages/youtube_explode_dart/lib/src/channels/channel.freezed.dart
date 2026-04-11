// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Channel {
  /// Channel ID.
  ChannelId get id;

  /// Channel title.
  String get title;

  /// URL of the channel's logo image.
  String get logoUrl;

  /// URL of the channel's banner image.
  String get bannerUrl;

  /// The (approximate) channel subscriber's count.
  int? get subscribersCount;

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChannelCopyWith<Channel> get copyWith =>
      _$ChannelCopyWithImpl<Channel>(this as Channel, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Channel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.bannerUrl, bannerUrl) ||
                other.bannerUrl == bannerUrl) &&
            (identical(other.subscribersCount, subscribersCount) ||
                other.subscribersCount == subscribersCount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, logoUrl, bannerUrl, subscribersCount);

  @override
  String toString() {
    return 'Channel(id: $id, title: $title, logoUrl: $logoUrl, bannerUrl: $bannerUrl, subscribersCount: $subscribersCount)';
  }
}

/// @nodoc
abstract mixin class $ChannelCopyWith<$Res> {
  factory $ChannelCopyWith(Channel value, $Res Function(Channel) _then) =
      _$ChannelCopyWithImpl;
  @useResult
  $Res call(
      {ChannelId id,
      String title,
      String logoUrl,
      String bannerUrl,
      int? subscribersCount});

  $ChannelIdCopyWith<$Res> get id;
}

/// @nodoc
class _$ChannelCopyWithImpl<$Res> implements $ChannelCopyWith<$Res> {
  _$ChannelCopyWithImpl(this._self, this._then);

  final Channel _self;
  final $Res Function(Channel) _then;

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? logoUrl = null,
    Object? bannerUrl = null,
    Object? subscribersCount = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as ChannelId,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _self.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      bannerUrl: null == bannerUrl
          ? _self.bannerUrl
          : bannerUrl // ignore: cast_nullable_to_non_nullable
              as String,
      subscribersCount: freezed == subscribersCount
          ? _self.subscribersCount
          : subscribersCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChannelIdCopyWith<$Res> get id {
    return $ChannelIdCopyWith<$Res>(_self.id, (value) {
      return _then(_self.copyWith(id: value));
    });
  }
}

/// @nodoc

class _Channel extends Channel {
  const _Channel(
      this.id, this.title, this.logoUrl, this.bannerUrl, this.subscribersCount)
      : super._();

  /// Channel ID.
  @override
  final ChannelId id;

  /// Channel title.
  @override
  final String title;

  /// URL of the channel's logo image.
  @override
  final String logoUrl;

  /// URL of the channel's banner image.
  @override
  final String bannerUrl;

  /// The (approximate) channel subscriber's count.
  @override
  final int? subscribersCount;

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChannelCopyWith<_Channel> get copyWith =>
      __$ChannelCopyWithImpl<_Channel>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Channel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.bannerUrl, bannerUrl) ||
                other.bannerUrl == bannerUrl) &&
            (identical(other.subscribersCount, subscribersCount) ||
                other.subscribersCount == subscribersCount));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, logoUrl, bannerUrl, subscribersCount);

  @override
  String toString() {
    return 'Channel(id: $id, title: $title, logoUrl: $logoUrl, bannerUrl: $bannerUrl, subscribersCount: $subscribersCount)';
  }
}

/// @nodoc
abstract mixin class _$ChannelCopyWith<$Res> implements $ChannelCopyWith<$Res> {
  factory _$ChannelCopyWith(_Channel value, $Res Function(_Channel) _then) =
      __$ChannelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ChannelId id,
      String title,
      String logoUrl,
      String bannerUrl,
      int? subscribersCount});

  @override
  $ChannelIdCopyWith<$Res> get id;
}

/// @nodoc
class __$ChannelCopyWithImpl<$Res> implements _$ChannelCopyWith<$Res> {
  __$ChannelCopyWithImpl(this._self, this._then);

  final _Channel _self;
  final $Res Function(_Channel) _then;

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? logoUrl = null,
    Object? bannerUrl = null,
    Object? subscribersCount = freezed,
  }) {
    return _then(_Channel(
      null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as ChannelId,
      null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      null == logoUrl
          ? _self.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      null == bannerUrl
          ? _self.bannerUrl
          : bannerUrl // ignore: cast_nullable_to_non_nullable
              as String,
      freezed == subscribersCount
          ? _self.subscribersCount
          : subscribersCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChannelIdCopyWith<$Res> get id {
    return $ChannelIdCopyWith<$Res>(_self.id, (value) {
      return _then(_self.copyWith(id: value));
    });
  }
}

// dart format on
