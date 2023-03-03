// ignore_for_file: constant_identifier_names

part of types_controller;

/// Defines the type of image.
///
/// Read [JPEG] and [PNG] for know the difference between performance.
enum ArtworkFormatType {
  /// Note: [JPEG] images give a better performance when call the method and
  /// give a "bad" image quality.
  JPEG,

  /// Note: [PNG] images give a slow performance when call the method and give a
  /// "good" image quality.
  PNG,
}
