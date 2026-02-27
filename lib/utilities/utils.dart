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
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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
  r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.*(list=([a-zA-Z0-9_-]+)).*$',
);

final RegExp _youtubePlaylistIdRegExp = RegExp('[&?]list=([a-zA-Z0-9_-]+)');

bool isSponsorshipAnnouncementUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase();
  return host != null && (host == 'ko-fi.com' || host.endsWith('.ko-fi.com'));
}

/// Selects the best audio stream based on the configured quality.
AudioStreamInfo selectAudioStreamForQuality(
  List<AudioStreamInfo> availableSources,
) {
  final compatibleSources = _filterCompatibleSources(availableSources);
  final selectionPool = compatibleSources.isNotEmpty
      ? compatibleSources
      : availableSources;

  final qualitySetting = audioQualitySetting.value;

  if (qualitySetting == 'low') {
    return selectionPool.last;
  } else if (qualitySetting == 'medium') {
    return selectionPool[selectionPool.length ~/ 2];
  }

  return selectionPool.withHighestBitrate();
}

AudioOnlyStreamInfo selectAudioOnlyStreamForQuality(
  List<AudioOnlyStreamInfo> availableSources,
) {
  final sortedByCompatibility = _sortAudioOnlyByCompatibility(availableSources);
  final compatibleSources = _filterCompatibleAudioOnlySources(
    sortedByCompatibility,
  );
  final selectionPool = compatibleSources.isNotEmpty
      ? compatibleSources
      : sortedByCompatibility;

  final qualitySetting = audioQualitySetting.value;

  if (qualitySetting == 'low') {
    return selectionPool.last;
  } else if (qualitySetting == 'medium') {
    return selectionPool[selectionPool.length ~/ 2];
  }

  return selectionPool.withHighestBitrate();
}

List<AudioOnlyStreamInfo> _filterCompatibleAudioOnlySources(
  List<AudioOnlyStreamInfo> sources,
) {
  return sources.where((stream) {
    final codec = stream.codec.toString().toLowerCase();
    final container = stream.container.name.toLowerCase();

    if (_isDolbyCodec(codec)) {
      return false;
    }

    return _isPreferredAudioOnlyCodec(codec, container);
  }).toList();
}

List<AudioOnlyStreamInfo> _sortAudioOnlyByCompatibility(
  List<AudioOnlyStreamInfo> sources,
) {
  final sorted = List<AudioOnlyStreamInfo>.from(sources)
    ..sort((a, b) {
      final aScore = _audioOnlyCompatibilityScore(a);
      final bScore = _audioOnlyCompatibilityScore(b);
      return bScore.compareTo(aScore);
    });
  return sorted;
}

int _audioOnlyCompatibilityScore(AudioOnlyStreamInfo stream) {
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

List<AudioStreamInfo> _filterCompatibleSources(List<AudioStreamInfo> sources) {
  return sources.where((stream) {
    final codec = stream.codec.toString().toLowerCase();

    if (_isDolbyCodec(codec)) {
      return false;
    }

    return _isPreferredCodec(codec);
  }).toList();
}

bool _isDolbyCodec(String codec) {
  return codec.contains('ec-3') ||
      codec.contains('ac-3') ||
      codec.contains('eac3') ||
      codec.contains('dolby');
}

bool _isPreferredCodec(String codec) {
  return codec.contains('mp4a') ||
      codec.contains('aac') ||
      codec.contains('opus') ||
      codec.contains('vorbis');
}

bool _isPreferredAudioOnlyCodec(String codec, String container) {
  if ((codec.contains('mp4a') || codec.contains('aac')) &&
      (container == 'mp4' || container == 'm4a')) {
    return true;
  }

  return codec.contains('opus') || codec.contains('vorbis');
}
