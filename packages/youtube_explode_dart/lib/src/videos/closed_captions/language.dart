import 'package:freezed_annotation/freezed_annotation.dart';

part 'language.g.dart';
part 'language.freezed.dart';

/// Language information.
@freezed
abstract class Language with _$Language {
  /// Initializes an instance of [Language]
  const factory Language(
    /// ISO 639-1 code of this language.
    String code,

    /// Full English name of this language. This could be an empty string.
    String name,
  ) = _Language;

  const Language._();

  ///
  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);
}
