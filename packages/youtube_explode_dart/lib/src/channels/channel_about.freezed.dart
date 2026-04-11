// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_about.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelAbout {
  /// Full channel description.
  String? get description;

  /// Channel view count.
  int? get viewCount;

  /// Channel join date.
  /// Formatted as: Gen 01, 2000
  String? get joinDate;

  /// Channel title.
  String get title;

  /// Channel thumbnails.
  List<Thumbnail> get thumbnails;

  /// Channel country.
  String? get country;

  /// Channel links.
  List<ChannelLink> get channelLinks;

  /// Create a copy of ChannelAbout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChannelAboutCopyWith<ChannelAbout> get copyWith =>
      _$ChannelAboutCopyWithImpl<ChannelAbout>(
          this as ChannelAbout, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChannelAbout &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.joinDate, joinDate) ||
                other.joinDate == joinDate) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other.thumbnails, thumbnails) &&
            (identical(other.country, country) || other.country == country) &&
            const DeepCollectionEquality()
                .equals(other.channelLinks, channelLinks));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      description,
      viewCount,
      joinDate,
      title,
      const DeepCollectionEquality().hash(thumbnails),
      country,
      const DeepCollectionEquality().hash(channelLinks));

  @override
  String toString() {
    return 'ChannelAbout(description: $description, viewCount: $viewCount, joinDate: $joinDate, title: $title, thumbnails: $thumbnails, country: $country, channelLinks: $channelLinks)';
  }
}

/// @nodoc
abstract mixin class $ChannelAboutCopyWith<$Res> {
  factory $ChannelAboutCopyWith(
          ChannelAbout value, $Res Function(ChannelAbout) _then) =
      _$ChannelAboutCopyWithImpl;
  @useResult
  $Res call(
      {String? description,
      int? viewCount,
      String? joinDate,
      String title,
      List<Thumbnail> thumbnails,
      String? country,
      List<ChannelLink> channelLinks});
}

/// @nodoc
class _$ChannelAboutCopyWithImpl<$Res> implements $ChannelAboutCopyWith<$Res> {
  _$ChannelAboutCopyWithImpl(this._self, this._then);

  final ChannelAbout _self;
  final $Res Function(ChannelAbout) _then;

  /// Create a copy of ChannelAbout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = freezed,
    Object? viewCount = freezed,
    Object? joinDate = freezed,
    Object? title = null,
    Object? thumbnails = null,
    Object? country = freezed,
    Object? channelLinks = null,
  }) {
    return _then(_self.copyWith(
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      viewCount: freezed == viewCount
          ? _self.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int?,
      joinDate: freezed == joinDate
          ? _self.joinDate
          : joinDate // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnails: null == thumbnails
          ? _self.thumbnails
          : thumbnails // ignore: cast_nullable_to_non_nullable
              as List<Thumbnail>,
      country: freezed == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      channelLinks: null == channelLinks
          ? _self.channelLinks
          : channelLinks // ignore: cast_nullable_to_non_nullable
              as List<ChannelLink>,
    ));
  }
}

/// @nodoc

class _ChannelAbout implements ChannelAbout {
  const _ChannelAbout(
      this.description,
      this.viewCount,
      this.joinDate,
      this.title,
      final List<Thumbnail> thumbnails,
      this.country,
      final List<ChannelLink> channelLinks)
      : _thumbnails = thumbnails,
        _channelLinks = channelLinks;

  /// Full channel description.
  @override
  final String? description;

  /// Channel view count.
  @override
  final int? viewCount;

  /// Channel join date.
  /// Formatted as: Gen 01, 2000
  @override
  final String? joinDate;

  /// Channel title.
  @override
  final String title;

  /// Channel thumbnails.
  final List<Thumbnail> _thumbnails;

  /// Channel thumbnails.
  @override
  List<Thumbnail> get thumbnails {
    if (_thumbnails is EqualUnmodifiableListView) return _thumbnails;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_thumbnails);
  }

  /// Channel country.
  @override
  final String? country;

  /// Channel links.
  final List<ChannelLink> _channelLinks;

  /// Channel links.
  @override
  List<ChannelLink> get channelLinks {
    if (_channelLinks is EqualUnmodifiableListView) return _channelLinks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_channelLinks);
  }

  /// Create a copy of ChannelAbout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChannelAboutCopyWith<_ChannelAbout> get copyWith =>
      __$ChannelAboutCopyWithImpl<_ChannelAbout>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChannelAbout &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.joinDate, joinDate) ||
                other.joinDate == joinDate) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other._thumbnails, _thumbnails) &&
            (identical(other.country, country) || other.country == country) &&
            const DeepCollectionEquality()
                .equals(other._channelLinks, _channelLinks));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      description,
      viewCount,
      joinDate,
      title,
      const DeepCollectionEquality().hash(_thumbnails),
      country,
      const DeepCollectionEquality().hash(_channelLinks));

  @override
  String toString() {
    return 'ChannelAbout(description: $description, viewCount: $viewCount, joinDate: $joinDate, title: $title, thumbnails: $thumbnails, country: $country, channelLinks: $channelLinks)';
  }
}

/// @nodoc
abstract mixin class _$ChannelAboutCopyWith<$Res>
    implements $ChannelAboutCopyWith<$Res> {
  factory _$ChannelAboutCopyWith(
          _ChannelAbout value, $Res Function(_ChannelAbout) _then) =
      __$ChannelAboutCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? description,
      int? viewCount,
      String? joinDate,
      String title,
      List<Thumbnail> thumbnails,
      String? country,
      List<ChannelLink> channelLinks});
}

/// @nodoc
class __$ChannelAboutCopyWithImpl<$Res>
    implements _$ChannelAboutCopyWith<$Res> {
  __$ChannelAboutCopyWithImpl(this._self, this._then);

  final _ChannelAbout _self;
  final $Res Function(_ChannelAbout) _then;

  /// Create a copy of ChannelAbout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? description = freezed,
    Object? viewCount = freezed,
    Object? joinDate = freezed,
    Object? title = null,
    Object? thumbnails = null,
    Object? country = freezed,
    Object? channelLinks = null,
  }) {
    return _then(_ChannelAbout(
      freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      freezed == viewCount
          ? _self.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int?,
      freezed == joinDate
          ? _self.joinDate
          : joinDate // ignore: cast_nullable_to_non_nullable
              as String?,
      null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      null == thumbnails
          ? _self._thumbnails
          : thumbnails // ignore: cast_nullable_to_non_nullable
              as List<Thumbnail>,
      freezed == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      null == channelLinks
          ? _self._channelLinks
          : channelLinks // ignore: cast_nullable_to_non_nullable
              as List<ChannelLink>,
    ));
  }
}

// dart format on
