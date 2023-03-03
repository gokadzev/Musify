// ignore_for_file: constant_identifier_names

part of types_controller;

/// Defines the sort type used for all query methods.
enum OrderType {
  /// [ASC_OR_SMALLER] will return list in alphabetical order or smaller number.
  ///
  /// [ASC] = Ascending Order
  ASC_OR_SMALLER,

  /// [DESC_OR_GREATER] will return list in "alphabetical-inverted" order or greater number.
  ///
  /// [DESC] = Descending Order
  DESC_OR_GREATER,
}
