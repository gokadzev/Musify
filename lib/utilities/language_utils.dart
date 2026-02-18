import 'package:flutter/widgets.dart';
import 'package:musify/localization/app_localizations.dart';

// Supported app language codes.
const appLanguages = <String>{
  'en',
  'zh',
  'zh-Hant',
  'et',
  'fr',
  'de',
  'el',
  'hi',
  'he',
  'hu',
  'id',
  'it',
  'ja',
  'ko',
  'ru',
  'pl',
  'pt',
  'es',
  'sv',
  'ta',
  'tr',
  'uk',
};

final List<Locale> appSupportedLocales = appLanguages.map((languageCode) {
  final parts = languageCode.split('-');
  if (parts.length > 1) {
    return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
  }
  return Locale(languageCode);
}).toList();

String getLanguageDisplayName(BuildContext context, String languageCode) {
  final l10n = AppLocalizations.of(context)!;

  switch (languageCode) {
    case 'en':
      return l10n.languageEn;
    case 'zh':
      return l10n.languageZh;
    case 'zh-Hant':
      return l10n.languageZhHant;
    case 'et':
      return l10n.languageEt;
    case 'fr':
      return l10n.languageFr;
    case 'de':
      return l10n.languageDe;
    case 'el':
      return l10n.languageEl;
    case 'hi':
      return l10n.languageHi;
    case 'he':
      return l10n.languageHe;
    case 'hu':
      return l10n.languageHu;
    case 'id':
      return l10n.languageId;
    case 'it':
      return l10n.languageIt;
    case 'ja':
      return l10n.languageJa;
    case 'ko':
      return l10n.languageKo;
    case 'ru':
      return l10n.languageRu;
    case 'pl':
      return l10n.languagePl;
    case 'pt':
      return l10n.languagePt;
    case 'es':
      return l10n.languageEs;
    case 'sv':
      return l10n.languageSv;
    case 'ta':
      return l10n.languageTa;
    case 'tr':
      return l10n.languageTr;
    case 'uk':
      return l10n.languageUk;
    default:
      return l10n
          .languageEn; // Fallback to English if the language code is not recognized
  }
}

Locale getLocaleFromLanguageCode(String? languageCode) {
  // Early return for null case
  if (languageCode == null) {
    return const Locale('en');
  }

  // Handle codes with script parts
  if (languageCode.contains('-')) {
    final parts = languageCode.split('-');
    final baseLanguage = parts[0];
    final script = parts[1];

    // Try to find exact match with script
    for (final locale in appSupportedLocales) {
      if (locale.languageCode == baseLanguage && locale.scriptCode == script) {
        return locale;
      }
    }

    // Fall back to base language only
    return Locale(baseLanguage);
  }

  // Handle simple language codes
  for (final locale in appSupportedLocales) {
    if (locale.languageCode == languageCode) {
      return locale;
    }
  }

  // Default fallback
  return const Locale('en');
}
