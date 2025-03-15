/*
 *     Copyright (C) 2025 Valeri Gokadze
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
import 'package:musify/utilities/utils.dart';

// Preferences

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

final predictiveBack = ValueNotifier<bool>(
  Hive.box('settings').get('predictiveBack', defaultValue: false),
);

final sponsorBlockSupport = ValueNotifier<bool>(
  Hive.box('settings').get('sponsorBlockSupport', defaultValue: false),
);

final defaultRecommendations = ValueNotifier<bool>(
  Hive.box('settings').get('defaultRecommendations', defaultValue: false),
);

final audioQualitySetting = ValueNotifier<String>(
  Hive.box('settings').get('audioQuality', defaultValue: 'high'),
);

Locale languageSetting = getLocaleFromLanguageCode(
  Hive.box('settings').get('language', defaultValue: 'English') as String,
);

final themeModeSetting =
    Hive.box('settings').get('themeMode', defaultValue: 'dark') as String;

Color primaryColorSetting = Color(
  Hive.box('settings').get('accentColor', defaultValue: 0xff91cef4),
);

// Non-Storage Notifiers

final shuffleNotifier = ValueNotifier<bool>(false);
final repeatNotifier = ValueNotifier<AudioServiceRepeatMode>(
  AudioServiceRepeatMode.none,
);

var sleepTimerNotifier = ValueNotifier<Duration?>(null);

// Server-Notifiers

final announcementURL = ValueNotifier<String?>(null);
