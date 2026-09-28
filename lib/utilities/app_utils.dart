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

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

BorderRadius getItemBorderRadius(
  int index,
  int totalLength, {
  bool hasItemsBefore = false,
  bool hasItemsAfter = false,
}) {
  // Determine if this item is the absolute top or absolute bottom of the visual block
  final isAbsoluteFirst = index == 0 && !hasItemsBefore;
  final isAbsoluteLast = index == totalLength - 1 && !hasItemsAfter;

  if (isAbsoluteFirst && isAbsoluteLast) {
    return commonCustomBarRadius; // Single item in the entire block
  } else if (isAbsoluteFirst) {
    return commonCustomBarRadiusFirst; // Top of the block
  } else if (isAbsoluteLast) {
    return commonCustomBarRadiusLast; // Bottom of the block
  }
  return BorderRadius.zero; // Default for middle items
}

ValueKey<int> listItemKey(String scope, int index, [Object? item]) {
  return ValueKey<int>(Object.hash(scope, index, item));
}

/// Reads a stored/decoded `List` of maps back into typed maps, dropping any
/// entry that is not a map. Returns an empty list for anything else.
List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

/// Validates if a URL is a YouTube playlist URL
bool isYoutubePlaylistUrl(String url) {
  return _youtubePlaylistRegExp.hasMatch(url);
}

/// Extracts the playlist ID from a YouTube playlist URL
String? extractYoutubePlaylistId(String url) {
  if (!isYoutubePlaylistUrl(url)) {
    return null;
  }

  final match = _youtubePlaylistIdRegExp.firstMatch(url);
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

final RegExp _youtubePlaylistRegExp = RegExp(
  r'^(https?:\/\/)?(www\.|m\.|music\.)?(youtube\.com|youtu\.be)\/.*(list=([a-zA-Z0-9_-]+)).*$',
);

final RegExp _youtubePlaylistIdRegExp = RegExp('[&?]list=([a-zA-Z0-9_-]+)');

bool isSponsorshipAnnouncementUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase();
  return host != null && (host == 'ko-fi.com' || host.endsWith('.ko-fi.com'));
}

/// Formats a [monthKey] (e.g. "2026-06") into a locale-aware month label
/// such as "June 2026". Falls back to [monthKey] if parsing fails.
String formatMonthPeriodLabel(Locale locale, String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length != 2) return monthKey;

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return monthKey;

  final label = DateFormat.yMMMM(locale.toString())
      .format(DateTime(year, month));
  return label.isEmpty
      ? monthKey
      : '${label[0].toUpperCase()}${label.substring(1)}';
}

/// The streams worth offering the player, best list first.
///
/// A stream whose URL came back empty is unusable however good its metadata
/// looks, and the android client answers with a full list of audio-only
/// formats whose URLs are all empty strings — picking one of those caches a
/// dead manifest and fails later, and worse, than failing here.
///
/// Muxed streams are a last resort: they carry a 360p video track nobody
/// listens to, at roughly three times the bitrate of the audio alone. But for
/// a video YouTube marks "made for kids" they are the only thing any client
/// still serves, so a nursery rhyme plays at that price or not at all.
List<AudioStreamInfo> playableAudioSources(StreamManifest manifest) {
  final audioOnly = manifest.audioOnly.where(_hasUsableUrl).toList();
  if (audioOnly.isNotEmpty) return audioOnly;

  return manifest.muxed.where(_hasUsableUrl).toList();
}

bool _hasUsableUrl(StreamInfo stream) => stream.url.host.isNotEmpty;

AudioStreamInfo? selectAudioStreamForQuality(
  List<AudioStreamInfo> availableSources,
) {
  if (availableSources.isEmpty) return null;

  final compatibleSources = _filterCompatibleAudioSources(availableSources);
  final selectionPool =
      (compatibleSources.isNotEmpty
            ? compatibleSources
            : List<AudioStreamInfo>.from(availableSources))
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

  final qualitySetting = audioQualitySetting.value;

  final AudioStreamInfo selected;
  if (qualitySetting == 'low') {
    selected = selectionPool.last;
  } else if (qualitySetting == 'medium') {
    selected = selectionPool[(selectionPool.length - 1) ~/ 2];
  } else {
    selected = selectionPool.first;
  }

  return _preferUnthrottledStream(selectionPool, selected);
}

/// How far below the selected bitrate an unthrottled stream may sit and still
/// count as the same quality.
const _unthrottledBitrateTolerance = 0.1;

/// YouTube caps the delivery rate of a stream whose URL isn't flagged
/// `ratebypass`, which starves the player's buffer during playback since it
/// reads the stream in one long request. Swap in an unthrottled stream when
/// one is offered at the quality [selected] already settled on.
AudioStreamInfo _preferUnthrottledStream(
  List<AudioStreamInfo> selectionPool,
  AudioStreamInfo selected,
) {
  if (!selected.isThrottled) return selected;

  final minBitrate =
      selected.bitrate.bitsPerSecond * (1 - _unthrottledBitrateTolerance);

  // selectionPool is sorted by descending bitrate, so the first match is the
  // best stream that qualifies.
  for (final stream in selectionPool) {
    if (!stream.isThrottled && stream.bitrate.bitsPerSecond >= minBitrate) {
      return stream;
    }
  }

  return selected;
}

List<AudioStreamInfo> _filterCompatibleAudioSources(
  List<AudioStreamInfo> sources,
) {
  return sources
      .where((stream) => _audioCompatibilityScore(stream) >= 2)
      .toList();
}

int _audioCompatibilityScore(AudioStreamInfo stream) {
  final codec = stream.codec.toString().toLowerCase();
  final container = stream.container.name.toLowerCase();

  if (_isDolbyCodec(codec)) {
    return 0;
  }

  if ((codec.contains('mp4a') || codec.contains('aac')) &&
      (container == 'mp4' || container == 'm4a')) {
    return 3;
  }

  if (codec.contains('opus') || codec.contains('vorbis')) {
    return 2;
  }

  return 1;
}

bool _isDolbyCodec(String codec) {
  return codec.contains('ec-3') ||
      codec.contains('ac-3') ||
      codec.contains('eac3') ||
      codec.contains('dolby');
}
