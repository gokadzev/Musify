import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/common_variables.dart';

BorderRadius getItemBorderRadius(int index, int totalLength) {
  const defaultRadius = BorderRadius.zero;
  if (totalLength == 1) {
    return commonCustomBarRadius; // Only one item
  } else if (index == 0) {
    return commonCustomBarRadiusFirst; // First item
  } else if (index == totalLength - 1) {
    return commonCustomBarRadiusLast; // Last item
  }
  return defaultRadius; // Default for middle items
}

Locale getLocaleFromLanguageCode(String? languageCode) {
  if (languageCode == null) {
    return const Locale('en');
  }

  return languageCode.contains('-')
      ? appSupportedLocales.firstWhere((locale) {
        final parts = languageCode.split('-');
        return locale.languageCode == parts[0] &&
            (locale.scriptCode == parts[1] || locale.countryCode == parts[1]);
      }, orElse: () => Locale(languageCode.split('-')[0]))
      : appSupportedLocales.firstWhere(
        (locale) => locale.languageCode == languageCode,
        orElse: () => const Locale('en'),
      );
}
