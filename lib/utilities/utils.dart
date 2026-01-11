/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/common_variables.dart';

BorderRadius getItemBorderRadius(int index, int totalLength) {
  if (totalLength == 1) {
    return commonCustomBarRadius; // Only one item
  } else if (index == 0) {
    return commonCustomBarRadiusFirst; // First item
  } else if (index == totalLength - 1) {
    return commonCustomBarRadiusLast; // Last item
  }
  return BorderRadius.zero; // Default for middle items
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

/// Validates if a URL is a YouTube playlist URL
bool isYoutubePlaylistUrl(String url) {
  final playlistRegExp = RegExp(
    r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.*(list=([a-zA-Z0-9_-]+)).*$',
  );
  return playlistRegExp.hasMatch(url);
}

/// Extracts the playlist ID from a YouTube playlist URL
String? extractYoutubePlaylistId(String url) {
  if (!isYoutubePlaylistUrl(url)) {
    return null;
  }

  final playlistIdRegExp = RegExp('[&?]list=([a-zA-Z0-9_-]+)');
  final match = playlistIdRegExp.firstMatch(url);

  return match?.group(1);
}

double getResponsiveTitleFontSize(Size size) {
  final isDesktop = size.width > 800;
  final isLandscape = size.width > size.height;
  if (isDesktop || isLandscape) return 20;
  if (size.width < 360) return 20;
  if (size.width < 400) return 22;
  return size.height * 0.028;
}

double getResponsiveArtistFontSize(Size size) {
  final isDesktop = size.width > 800;
  final isLandscape = size.width > size.height;
  if (isDesktop || isLandscape) return 14;
  if (size.width < 360) return 14;
  if (size.width < 400) return 15;
  return size.height * 0.018;
}
