import 'package:freezed_annotation/freezed_annotation.dart';

import '../extensions/helpers_extension.dart';

part 'channel_handle.freezed.dart';

/// Encapsulates a valid YouTube channel handle,
/// including the starting @ (at).
@freezed
abstract class ChannelHandle with _$ChannelHandle {
  /// Initializes an instance of [ChannelHandle].
  factory ChannelHandle(String urlOrChannelHandle) {
    final channelHandle = parseChannelHandle(urlOrChannelHandle);
    if (channelHandle == null) {
      throw ArgumentError.value(
        urlOrChannelHandle,
        'urlOrChannelHandle',
        'Invalid ChannelHandle',
      );
    }
    return ChannelHandle._(channelHandle);
  }

  ///  Converts [obj] to a [ChannelHandle] by calling .toString on that object.
  /// If it is already a [ChannelHandle], [obj] is returned
  factory ChannelHandle.fromString(dynamic obj) {
    if (obj is ChannelHandle) {
      return obj;
    }
    return ChannelHandle(obj.toString());
  }

  const factory ChannelHandle._(
    /// Handle as string.
    String value,
  ) = _ChannelHandle;

  /// Channel handles must start with @ can contain only letters, numbers, periods, dashes and underscores.
  static final _handleExp = RegExp(r'^@[a-zA-Z0-9\\-_.]+$');

  /// Returns true if the given ChannelHandle is a valid ChannelHandle.
  static bool validateChannelHandle(String name) {
    if (name.isNullOrWhiteSpace) {
      return false;
    }

    return _handleExp.hasMatch(name);
  }

  /// Parses a ChannelHandle from a url.
  static String? parseChannelHandle(String handleOrUrl) {
    if (handleOrUrl.isEmpty) {
      return null;
    }

    if (validateChannelHandle(handleOrUrl)) {
      return handleOrUrl;
    }

    final regMatch = RegExp(r'youtube\..+?/(@.*?)(?:\?|&|/|$)')
        .firstMatch(handleOrUrl)
        ?.group(1);
    if (!regMatch.isNullOrWhiteSpace && validateChannelHandle(regMatch!)) {
      return regMatch;
    }
    return null;
  }
}
