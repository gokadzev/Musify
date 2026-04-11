import 'package:freezed_annotation/freezed_annotation.dart';

import '../extensions/helpers_extension.dart';

part 'username.freezed.dart';

/// Encapsulates a valid YouTube user name.
@freezed
abstract class Username with _$Username {
  /// Initializes an instance of [Username].
  factory Username(String urlOrUsername) {
    final username = parseUsername(urlOrUsername);
    if (username == null) {
      throw ArgumentError.value(
        urlOrUsername,
        'urlOrUsername',
        'Invalid username',
      );
    }
    return Username._(username);
  }

  ///  Converts [obj] to a [Username] by calling .toString on that object.
  /// If it is already a [Username], [obj] is returned
  factory Username.fromString(dynamic obj) {
    if (obj is Username) {
      return obj;
    }
    return Username(obj.toString());
  }

  const factory Username._(
    /// User name as string.
    String value,
  ) = _Username;

  /// Returns true if the given username is a valid username.
  static bool validateUsername(String name) {
    if (name.isNullOrWhiteSpace) {
      return false;
    }

    if (name.length > 20) {
      return false;
    }

    return true;
  }

  /// Parses a username from a url.
  static String? parseUsername(String nameOrUrl) {
    if (nameOrUrl.isEmpty) {
      return null;
    }

    if (validateUsername(nameOrUrl)) {
      return nameOrUrl;
    }

    final regMatch = RegExp(r'youtube\..+?/user/(.*?)(?:\?|&|/|$)')
        .firstMatch(nameOrUrl)
        ?.group(1);
    if (!regMatch.isNullOrWhiteSpace && validateUsername(regMatch!)) {
      return regMatch;
    }
    return null;
  }
}
