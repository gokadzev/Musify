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

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/screens/user_songs_page.dart';
import 'package:musify/utilities/language_utils.dart';

// Preferences

final shouldWeCheckUpdates = ValueNotifier<bool?>(
  Hive.box('settings').get('shouldWeCheckUpdates', defaultValue: null),
);

final playNextSongAutomatically = ValueNotifier<bool>(
  Hive.box('settings').get('playNextSongAutomatically', defaultValue: false),
);

final useSystemColor = ValueNotifier<bool>(
  Hive.box('settings').get('useSystemColor', defaultValue: true),
);

final usePureBlackColor = ValueNotifier<bool>(
  Hive.box('settings').get('usePureBlackColor', defaultValue: false),
);

final offlineMode = ValueNotifier<bool>(
  Hive.box('settings').get('offlineMode', defaultValue: false),
);

final wrappedEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('wrappedEnabled', defaultValue: true),
);

final predictiveBack = ValueNotifier<bool>(
  Hive.box('settings').get('predictiveBack', defaultValue: true),
);

final sponsorBlockSupport = ValueNotifier<bool>(
  Hive.box('settings').get('sponsorBlockSupport', defaultValue: false),
);

final externalRecommendations = ValueNotifier<bool>(
  Hive.box('settings').get('externalRecommendations', defaultValue: false),
);

final useProxy = ValueNotifier<bool>(
  Hive.box('settings').get('useProxy', defaultValue: false),
);

final audioQualitySetting = ValueNotifier<String>(
  Hive.box('settings').get('audioQuality', defaultValue: 'high'),
);

final showAudioQualityBadge = ValueNotifier<bool>(
  Hive.box('settings').get('showAudioQualityBadge', defaultValue: false),
);

List<double> _readEqualizerGains() {
  final raw = Hive.box(
    'settings',
  ).get('equalizerBandGains', defaultValue: const <dynamic>[]);

  if (raw is List) {
    return raw.map((value) => value is num ? value.toDouble() : 0.0).toList();
  }

  return <double>[];
}

final equalizerEnabled = ValueNotifier<bool>(
  Hive.box('settings').get('equalizerEnabled', defaultValue: false),
);

final equalizerBandGains = ValueNotifier<List<double>>(_readEqualizerGains());

Locale languageSetting = getLocaleFromLanguageCode(
  Hive.box('settings').get('languageCode', defaultValue: 'en') as String,
);

int themeModeSetting =
    Hive.box('settings').get('themeIndex', defaultValue: 0) as int;

String playlistSortSetting = Hive.box(
  'settings',
).get('playlistSortType', defaultValue: PlaylistSortType.default_.name);

String offlineSortSetting = Hive.box(
  'settings',
).get('offlineSortType', defaultValue: OfflineSortType.default_.name);

Color primaryColorSetting = Color(
  Hive.box('settings').get('accentColor', defaultValue: 0xff91cef4),
);

final shuffleNotifier = ValueNotifier<bool>(
  Hive.box('settings').get('shuffleEnabled', defaultValue: false),
);

final repeatNotifier = ValueNotifier<AudioServiceRepeatMode>(
  AudioServiceRepeatMode.values[Hive.box(
    'settings',
  ).get('repeatMode', defaultValue: 0)],
);

// Non-storage notifiers

var sleepTimerNotifier = ValueNotifier<Duration?>(null);

// Server-Notifiers

final announcementURL = ValueNotifier<String?>(null);

void reloadSettingsFromStorage() {
  final settings = Hive.box('settings');

  shouldWeCheckUpdates.value = settings.get(
    'shouldWeCheckUpdates',
    defaultValue: null,
  );
  playNextSongAutomatically.value = settings.get(
    'playNextSongAutomatically',
    defaultValue: false,
  );
  useSystemColor.value = settings.get('useSystemColor', defaultValue: true);
  usePureBlackColor.value = settings.get(
    'usePureBlackColor',
    defaultValue: false,
  );
  offlineMode.value = settings.get('offlineMode', defaultValue: false);
  wrappedEnabled.value = settings.get('wrappedEnabled', defaultValue: true);
  predictiveBack.value = settings.get('predictiveBack', defaultValue: true);
  sponsorBlockSupport.value = settings.get(
    'sponsorBlockSupport',
    defaultValue: false,
  );
  externalRecommendations.value = settings.get(
    'externalRecommendations',
    defaultValue: false,
  );
  useProxy.value = settings.get('useProxy', defaultValue: false);
  audioQualitySetting.value = settings.get(
    'audioQuality',
    defaultValue: 'high',
  );
  showAudioQualityBadge.value = settings.get(
    'showAudioQualityBadge',
    defaultValue: false,
  );
  equalizerEnabled.value = settings.get(
    'equalizerEnabled',
    defaultValue: false,
  );
  equalizerBandGains.value = _readEqualizerGains();

  final restoredThemeIndex = settings.get('themeIndex', defaultValue: 0);
  if (restoredThemeIndex is int) themeModeSetting = restoredThemeIndex;

  final restoredLanguageCode = settings.get('languageCode', defaultValue: 'en');
  if (restoredLanguageCode is String) {
    languageSetting = getLocaleFromLanguageCode(restoredLanguageCode);
  }

  final restoredPlaylistSort = settings.get(
    'playlistSortType',
    defaultValue: PlaylistSortType.default_.name,
  );
  if (restoredPlaylistSort is String) {
    playlistSortSetting = restoredPlaylistSort;
  }

  final restoredOfflineSort = settings.get(
    'offlineSortType',
    defaultValue: OfflineSortType.default_.name,
  );
  if (restoredOfflineSort is String) {
    offlineSortSetting = restoredOfflineSort;
  }

  final restoredAccentColor = settings.get(
    'accentColor',
    defaultValue: 0xff91cef4,
  );
  if (restoredAccentColor is int) {
    primaryColorSetting = Color(restoredAccentColor);
  }

  shuffleNotifier.value = settings.get('shuffleEnabled', defaultValue: false);
  final restoredRepeatIndex = settings.get('repeatMode', defaultValue: 0);
  if (restoredRepeatIndex is int &&
      restoredRepeatIndex >= 0 &&
      restoredRepeatIndex < AudioServiceRepeatMode.values.length) {
    repeatNotifier.value = AudioServiceRepeatMode.values[restoredRepeatIndex];
  }
}
