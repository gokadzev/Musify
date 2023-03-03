// ignore_for_file: constant_identifier_names

part of types_controller;

/// All types of audios that can be 'queried' from plugin.
///
/// Note: Some types are platform specific only. If some platform don't support
/// a type the plugin will ignore the request.
enum AudioType {
  /// Query/Remove audios defined as [IS_MUSIC].
  IS_MUSIC,

  /// Query/Remove audios defined as [IS_ALARM].
  IS_ALARM,

  /// Query/Remove audios defined as [IS_NOTIFICATION].
  IS_NOTIFICATION,

  /// Query/Remove audios defined as [IS_PODCAST].
  IS_PODCAST,

  /// Query/Remove audios defined as [IS_RINGTONE].
  IS_RINGTONE,

  /// Query/Remove audios defined as [IS_AUDIOBOOK].
  IS_AUDIOBOOK,
}
