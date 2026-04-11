// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelLink {
  /// Link title.
  String get title;

  /// Link URL.
  /// Already decoded with the YouTube shortener already taken out.
  Uri get url;

  /// Link Icon URL.
  @Deprecated(
      'As of at least 26-08-2023 YT no longer provides icons for links, so this URI is always empty')
  Uri get icon;

  /// Create a copy of ChannelLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChannelLinkCopyWith<ChannelLink> get copyWith =>
      _$ChannelLinkCopyWithImpl<ChannelLink>(this as ChannelLink, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChannelLink &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @override
  int get hashCode => Object.hash(runtimeType, title, url, icon);

  @override
  String toString() {
    return 'ChannelLink(title: $title, url: $url, icon: $icon)';
  }
}

/// @nodoc
abstract mixin class $ChannelLinkCopyWith<$Res> {
  factory $ChannelLinkCopyWith(
          ChannelLink value, $Res Function(ChannelLink) _then) =
      _$ChannelLinkCopyWithImpl;
  @useResult
  $Res call(
      {String title,
      Uri url,
      @Deprecated(
          'As of at least 26-08-2023 YT no longer provides icons for links, so this URI is always empty')
      Uri icon});
}

/// @nodoc
class _$ChannelLinkCopyWithImpl<$Res> implements $ChannelLinkCopyWith<$Res> {
  _$ChannelLinkCopyWithImpl(this._self, this._then);

  final ChannelLink _self;
  final $Res Function(ChannelLink) _then;

  /// Create a copy of ChannelLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? url = null,
    Object? icon = null,
  }) {
    return _then(_self.copyWith(
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as Uri,
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Uri,
    ));
  }
}

/// @nodoc

class _ChannelLink implements ChannelLink {
  const _ChannelLink(
      this.title,
      this.url,
      @Deprecated(
          'As of at least 26-08-2023 YT no longer provides icons for links, so this URI is always empty')
      this.icon);

  /// Link title.
  @override
  final String title;

  /// Link URL.
  /// Already decoded with the YouTube shortener already taken out.
  @override
  final Uri url;

  /// Link Icon URL.
  @override
  @Deprecated(
      'As of at least 26-08-2023 YT no longer provides icons for links, so this URI is always empty')
  final Uri icon;

  /// Create a copy of ChannelLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChannelLinkCopyWith<_ChannelLink> get copyWith =>
      __$ChannelLinkCopyWithImpl<_ChannelLink>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChannelLink &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @override
  int get hashCode => Object.hash(runtimeType, title, url, icon);

  @override
  String toString() {
    return 'ChannelLink(title: $title, url: $url, icon: $icon)';
  }
}

/// @nodoc
abstract mixin class _$ChannelLinkCopyWith<$Res>
    implements $ChannelLinkCopyWith<$Res> {
  factory _$ChannelLinkCopyWith(
          _ChannelLink value, $Res Function(_ChannelLink) _then) =
      __$ChannelLinkCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String title,
      Uri url,
      @Deprecated(
          'As of at least 26-08-2023 YT no longer provides icons for links, so this URI is always empty')
      Uri icon});
}

/// @nodoc
class __$ChannelLinkCopyWithImpl<$Res> implements _$ChannelLinkCopyWith<$Res> {
  __$ChannelLinkCopyWithImpl(this._self, this._then);

  final _ChannelLink _self;
  final $Res Function(_ChannelLink) _then;

  /// Create a copy of ChannelLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = null,
    Object? url = null,
    Object? icon = null,
  }) {
    return _then(_ChannelLink(
      null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as Uri,
      null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Uri,
    ));
  }
}

// dart format on
