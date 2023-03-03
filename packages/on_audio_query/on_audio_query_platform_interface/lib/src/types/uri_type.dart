// ignore_for_file: constant_identifier_names

part of types_controller;

/// Defines if query method will be in [EXTERNAL] or [INTERNAL] storage.
enum UriType {
  /// EXTERNAL storage.
  EXTERNAL,

  /// INTERNAL storage.
  INTERNAL,

  /// INTERNAL storage.
  /// Works only in Android >= Q/29.
  ///
  /// Note: This type are't implemented in Android, only in Dart. Probably will return null.
  EXTERNAL_PRIMARY,
}
