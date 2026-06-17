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

import 'dart:async';

import 'package:musify/main.dart' show logger;
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/proxy_manager.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_music_explode_dart/youtube_music_explode_dart.dart';

const artistCatalogCacheVersion = 15;
const artistSearchCacheVersion = 10;
const _artistRequestTimeout = Duration(seconds: 12);
const _musicDiscographyTimeout = Duration(seconds: 25);
const _musicAlbumTimeout = Duration(seconds: 12);
const _musicAlbumBatchSize = 6;

final ytMusicClient = YoutubeMusicExplode();

Future<List<Map<String, dynamic>>> searchVerifiedArtists(
  String query, {
  int limit = 5,
}) async {
  final normalizedQuery = query.trim();
  if (normalizedQuery.isEmpty) return [];

  final cacheKey =
      'search_music_artists_v${artistSearchCacheVersion}_l$limit'
      '_${normalizedQuery.toLowerCase()}';
  final cachedArtists = await getData('cache', cacheKey);
  if (cachedArtists is List) {
    return cachedArtists
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .take(limit)
        .toList();
  }

  try {
    final artists = _dedupeResolvedArtists(
      (await ytMusicClient.music
              .searchArtists(normalizedQuery)
              .timeout(_artistRequestTimeout))
          .where((artist) => !looksUnofficialArtistName(artist.name))
          .map(_artistMapFromMusicArtist),
    ).take(limit).toList();

    if (artists.isNotEmpty) {
      unawaited(addOrUpdateData<List>('cache', cacheKey, artists));
    }
    return artists;
  } catch (e, stackTrace) {
    logger.log(
      'Error while searching YouTube Music artists for "$normalizedQuery"',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

Future<Map<String, dynamic>?> resolveArtist(
  String lookup, {
  String? sourceSongId,
  String? sourceVideoAuthor,
  String? preferredName,
  String? preferredImage,
  bool preferredVerified = false,
}) async {
  final normalizedLookup = lookup.trim();
  if (normalizedLookup.isEmpty || normalizedLookup == 'null') return null;

  final displayName = preferredName?.trim();
  if (preferredVerified &&
      _isChannelId(normalizedLookup) &&
      displayName != null &&
      displayName.isNotEmpty) {
    return _artistMapFromMusicArtist(
      MusicArtist(
        id: normalizedLookup,
        name: displayName,
        thumbnailUrl: preferredImage,
      ),
      preferredTitle: displayName,
      preferredImage: preferredImage,
    );
  }

  final normalizedSourceSongId = sourceSongId?.trim();
  final terms = <String>{};
  String? sourceVideoArtist;
  var resolvedSourceVideoAuthor = sourceVideoAuthor?.trim();

  void addAliases(String? value) {
    if (value == null) return;
    terms.addAll(_artistSearchAliases(value));
  }

  addAliases(displayName);

  if (normalizedSourceSongId != null && normalizedSourceSongId.isNotEmpty) {
    try {
      final sourceVideo = await ytClient.videos
          .get(normalizedSourceSongId)
          .timeout(_artistRequestTimeout);
      resolvedSourceVideoAuthor = sourceVideo.author.trim();
      sourceVideoArtist = _artistNameFromVideoTitle(sourceVideo.title);
      addAliases(sourceVideoArtist);
      addAliases(resolvedSourceVideoAuthor);
      for (final musicData in sourceVideo.musicData) {
        addAliases(musicData.artist);
      }
    } catch (e, stackTrace) {
      logger.log(
        'Could not load source video $normalizedSourceSongId for artist lookup',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  if (_isChannelId(normalizedLookup)) {
    try {
      final channel = await ytClient.channels
          .get(normalizedLookup)
          .timeout(_artistRequestTimeout);
      addAliases(channel.title);
    } catch (e, stackTrace) {
      logger.log(
        'Could not load seeded artist channel $normalizedLookup',
        error: e,
        stackTrace: stackTrace,
      );
    }
  } else if (normalizedLookup != normalizedSourceSongId) {
    addAliases(normalizedLookup);
  }

  final scoringName =
      displayName ??
      sourceVideoArtist ??
      _cleanArtistSearchTerm(resolvedSourceVideoAuthor ?? normalizedLookup);
  final artist = await _resolveMusicArtistFromTerms(
    terms,
    trustedLookupId: normalizedLookup,
    preferredImage: preferredImage,
    preferredTitle: scoringName,
    allowFirstResultForTrustedSeed: preferredVerified && displayName != null,
  );

  if (artist == null) {
    logger.log(
      'Artist lookup rejected: no canonical YouTube Music artist for '
      '"$normalizedLookup"; sourceSongId=$normalizedSourceSongId; '
      'preferredName=$displayName; terms=${terms.join(' | ')}',
    );
  }

  return artist;
}

Future<Map<String, dynamic>?> getArtistCatalog(
  String artistId, {
  bool forceRefresh = false,
  String? sourceSongId,
  String? sourceVideoAuthor,
  String? preferredName,
  String? preferredImage,
  bool preferredVerified = false,
}) async {
  try {
    final artist = await resolveArtist(
      artistId,
      preferredName: preferredName,
      preferredImage: preferredImage,
      sourceSongId: sourceSongId,
      sourceVideoAuthor: sourceVideoAuthor,
      preferredVerified: preferredVerified,
    );

    if (artist == null) {
      logger.log(
        'Artist catalog not found: lookup=$artistId; '
        'sourceSongId=$sourceSongId; preferredName=$preferredName',
      );
      return null;
    }

    final resolvedArtistId = artist['ytid']?.toString() ?? artistId;
    final cacheKey =
        'artist_catalog_v${artistCatalogCacheVersion}_$resolvedArtistId';
    if (!forceRefresh) {
      final cachedArtist = await getData('cache', cacheKey);
      if (cachedArtist is Map &&
          cachedArtist['list'] is List &&
          (cachedArtist['list'] as List).isNotEmpty) {
        return Map<String, dynamic>.from(cachedArtist);
      }
    } else {
      await deleteData('cache', cacheKey);
      await deleteData('cache', '${cacheKey}_date');
    }

    final songs = await _buildArtistCatalogFromMusic(artist);
    if (songs.isEmpty) {
      logger.log(
        'Artist catalog not found: no YouTube Music releases for '
        '${artist['title']} (${artist['ytid']}); lookup=$artistId; '
        'sourceSongId=$sourceSongId; preferredName=$preferredName',
      );
      return {
        ...artist,
        'source': 'youtube-artist',
        'isArtist': true,
        'catalogStatus': 'failed',
        'isCatalogComplete': false,
        'list': [],
      };
    }

    final artistPlaylist = {
      ...artist,
      'source': 'youtube-artist',
      'isArtist': true,
      'catalogStatus': 'complete',
      'isCatalogComplete': true,
      'list': songs,
    };

    unawaited(addOrUpdateData<Map>('cache', cacheKey, artistPlaylist));
    return artistPlaylist;
  } catch (e, stackTrace) {
    logger.log(
      'Error fetching artist catalog for $artistId',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}

String? normalizeArtistThumbnailUrl(String? value) {
  final thumbnail = value?.trim();
  if (thumbnail == null || thumbnail.isEmpty) return null;

  late final String normalized;
  if (thumbnail.startsWith('//')) {
    normalized = 'https:$thumbnail';
  } else if (thumbnail.startsWith('https:') &&
      !thumbnail.startsWith('https://')) {
    normalized =
        'https://${thumbnail.substring(6).replaceFirst(RegExp('^/+'), '')}';
  } else if (thumbnail.startsWith('http:') &&
      !thumbnail.startsWith('http://')) {
    normalized =
        'https://${thumbnail.substring(5).replaceFirst(RegExp('^/+'), '')}';
  } else if (thumbnail.startsWith('http://') ||
      thumbnail.startsWith('https://')) {
    normalized = thumbnail;
  } else if (thumbnail.startsWith('/')) {
    normalized = 'https://www.youtube.com$thumbnail';
  } else {
    normalized = 'https://$thumbnail';
  }

  return _upgradeArtistThumbnailResolution(normalized);
}

String _upgradeArtistThumbnailResolution(String thumbnail) {
  final uri = Uri.tryParse(thumbnail);
  final host = uri?.host.toLowerCase() ?? '';
  if (!host.endsWith('googleusercontent.com') && !host.endsWith('ggpht.com')) {
    return thumbnail;
  }

  return thumbnail
      .replaceFirst(RegExp(r'=w\d+-h\d+'), '=w544-h544')
      .replaceFirst(RegExp(r'=s\d+'), '=s544');
}

String normalizeArtistDisplayTitle(String value) =>
    _cleanArtistSearchTerm(value).replaceAll(RegExp(r'\s+'), ' ').trim();

bool looksUnofficialArtistName(String name) {
  final lowerName = name.toLowerCase();
  return lowerName.contains('cover') ||
      lowerName.contains('lyrics') ||
      lowerName.contains('lyric') ||
      lowerName.contains('reaction') ||
      lowerName.contains('fan') ||
      lowerName.contains('tribute') ||
      lowerName.contains('karaoke') ||
      lowerName.contains('parody') ||
      lowerName.contains('nightcore') ||
      lowerName.contains('sped up') ||
      lowerName.contains('slowed');
}

List<Map<String, dynamic>> dedupeArtistCatalogSongs(
  List<Map<String, dynamic>> songs,
) {
  final seenIds = <String>{};
  final seenTitles = <String>{};
  final unique = <Map<String, dynamic>>[];
  for (final song in songs) {
    final id = song['ytid']?.toString();
    if (id == null || id.isEmpty || !seenIds.add(id)) continue;

    final title = formatSongTitle(song['title']?.toString() ?? '');
    final artist = song['artist']?.toString() ?? '';
    if (title.trim().isEmpty || _sameArtistPageSongTitle(title, artist)) {
      continue;
    }

    final titleKey =
        '${_canonicalArtistName(artist)}:${_canonicalSongTitle(title)}';
    if (!seenTitles.add(titleKey)) {
      continue;
    }

    unique.add({...song, 'id': unique.length, 'title': title});
  }
  return unique;
}

Future<Map<String, dynamic>?> _resolveMusicArtistFromTerms(
  Set<String> terms, {
  required String trustedLookupId,
  required String? preferredImage,
  required String preferredTitle,
  required bool allowFirstResultForTrustedSeed,
}) async {
  final normalizedTerms = terms
      .map(normalizeArtistDisplayTitle)
      .where((term) => term.isNotEmpty)
      .toList();
  final searched = <String>{};

  for (final term in normalizedTerms) {
    if (!searched.add(term.toLowerCase())) continue;

    List<MusicArtist> candidates;
    try {
      candidates = await ytMusicClient.music
          .searchArtists(term)
          .timeout(_artistRequestTimeout);
    } catch (e, stackTrace) {
      logger.log(
        'YouTube Music artist search failed for "$term"',
        error: e,
        stackTrace: stackTrace,
      );
      continue;
    }

    for (final candidate in candidates) {
      if (candidate.id == trustedLookupId ||
          _canAcceptMusicArtist(
            candidate,
            term,
            allowFirstResultForTrustedSeed: allowFirstResultForTrustedSeed,
          )) {
        return _artistMapFromMusicArtist(
          candidate,
          preferredTitle: preferredTitle,
          preferredImage: preferredImage,
        );
      }
    }
  }

  return null;
}

bool _canAcceptMusicArtist(
  MusicArtist candidate,
  String term, {
  required bool allowFirstResultForTrustedSeed,
}) {
  if (candidate.id.isEmpty ||
      candidate.name.trim().isEmpty ||
      looksUnofficialArtistName(candidate.name)) {
    return false;
  }

  if (_strictSameArtistTitle(candidate.name, term)) return true;

  final termKey = _strictArtistTitleKey(term);
  final candidateKey = _strictArtistTitleKey(candidate.name);
  if (termKey.length >= 4 &&
      candidateKey.isNotEmpty &&
      (candidateKey.contains(termKey) || termKey.contains(candidateKey))) {
    return true;
  }

  return allowFirstResultForTrustedSeed;
}

Map<String, dynamic> _artistMapFromMusicArtist(
  MusicArtist artist, {
  String? preferredTitle,
  String? preferredImage,
}) {
  final title = normalizeArtistDisplayTitle(artist.name);
  return {
    'ytid': artist.id,
    'title': title,
    'sourceTitle': artist.name,
    if (preferredTitle != null && preferredTitle.trim().isNotEmpty)
      'lookupTitle': normalizeArtistDisplayTitle(preferredTitle),
    'image': normalizeArtistThumbnailUrl(artist.thumbnailUrl ?? preferredImage),
    'source': 'youtube-artist',
    'isArtist': true,
    'isVerifiedArtist': true,
    'list': [],
  };
}

List<Map<String, dynamic>> _dedupeResolvedArtists(
  Iterable<Map<String, dynamic>> artists,
) {
  final seenIds = <String>{};
  final seenTitles = <String>{};
  final unique = <Map<String, dynamic>>[];

  for (final artist in artists) {
    final id = artist['ytid']?.toString() ?? '';
    final titleKey = _strictArtistTitleKey(artist['title']?.toString() ?? '');
    if (id.isNotEmpty && !seenIds.add(id)) continue;
    if (titleKey.isNotEmpty && !seenTitles.add(titleKey)) continue;
    unique.add(artist);
  }

  return unique;
}

Future<List<Map<String, dynamic>>> _buildArtistCatalogFromMusic(
  Map<String, dynamic> artist,
) async {
  final artistId = artist['ytid']?.toString() ?? '';
  if (!_isChannelId(artistId)) return [];

  final artistName = normalizeArtistDisplayTitle(
    artist['title']?.toString() ??
        artist['sourceTitle']?.toString() ??
        artist['lookupTitle']?.toString() ??
        '',
  );

  try {
    final releases = await ytMusicClient.music
        .getArtistReleases(artistId)
        .timeout(_musicDiscographyTimeout);

    if (releases.isEmpty) {
      logger.log('YouTube Music discography empty for $artistName ($artistId)');
      return [];
    }

    final songs = <Map<String, dynamic>>[];
    for (var i = 0; i < releases.length; i += _musicAlbumBatchSize) {
      final batch = releases.skip(i).take(_musicAlbumBatchSize);
      final batchResults = await Future.wait(
        batch.map((album) => _loadAlbumSongs(album, artistId, artistName)),
      );
      for (final albumSongs in batchResults) {
        songs.addAll(albumSongs);
      }
    }

    final catalog = dedupeArtistCatalogSongs(songs);
    logger.log(
      'YouTube Music catalog for $artistName ($artistId): '
      '${releases.length} releases -> ${catalog.length} tracks',
    );
    return catalog;
  } catch (e, stackTrace) {
    logger.log(
      'YouTube Music discography failed for $artistName ($artistId)',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

Future<List<Map<String, dynamic>>> _loadAlbumSongs(
  MusicAlbum album,
  String channelId,
  String artistName,
) async {
  try {
    final tracks = await ytMusicClient.music
        .getAlbumTracks(album.id, author: artistName, channelId: channelId)
        .timeout(_musicAlbumTimeout);
    return [for (final track in tracks) returnSongLayout(0, track)];
  } catch (e, stackTrace) {
    logger.log(
      'Could not load YouTube Music album ${album.title} (${album.id})',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
}

bool _sameArtistPageSongTitle(String title, String artist) {
  final canonicalTitle = _canonicalSongTitle(title);
  final canonicalArtist = _canonicalArtistName(artist);
  return canonicalTitle.isNotEmpty && canonicalTitle == canonicalArtist;
}

String _artistNameFromVideoTitle(String title) {
  final sep = title.indexOf(' - ');
  if (sep <= 0) return '';
  return title.substring(0, sep).trim();
}

Set<String> _artistSearchAliases(String value) {
  final cleaned = _cleanArtistSearchTerm(value);
  if (cleaned.isEmpty) return {};

  final aliases = <String>{cleaned, _spaceCamelCaseArtistTitle(cleaned)};
  final featureSplit = cleaned.split(
    RegExp(r'\s+(?:feat\.?|ft\.?|featuring|with)\s+', caseSensitive: false),
  );
  if (featureSplit.first.trim().isNotEmpty) {
    aliases
      ..add(featureSplit.first.trim())
      ..add(_spaceCamelCaseArtistTitle(featureSplit.first.trim()));
  }

  final joinedArtists = cleaned.split(
    RegExp(r'\s+(?:x|\+|&)\s+', caseSensitive: false),
  );
  if (joinedArtists.first.trim().isNotEmpty) {
    aliases
      ..add(joinedArtists.first.trim())
      ..add(_spaceCamelCaseArtistTitle(joinedArtists.first.trim()));
  }

  final commaParts = cleaned.split(',');
  if (commaParts.length > 1 && commaParts.first.trim().length > 3) {
    aliases
      ..add(commaParts.first.trim())
      ..add(_spaceCamelCaseArtistTitle(commaParts.first.trim()));
  }

  return aliases.where((alias) => alias.trim().isNotEmpty).toSet();
}

String _spaceCamelCaseArtistTitle(String value) {
  final trimmed = value.trim();
  if (trimmed.length < 2) return trimmed;

  final buffer = StringBuffer(trimmed[0]);
  for (var index = 1; index < trimmed.length; index++) {
    final previous = trimmed.codeUnitAt(index - 1);
    final current = trimmed.codeUnitAt(index);
    final previousIsLower = previous >= 97 && previous <= 122;
    final currentIsUpper = current >= 65 && current <= 90;
    if (previousIsLower && currentIsUpper) {
      buffer.write(' ');
    }
    buffer.writeCharCode(current);
  }

  return buffer.toString().trim();
}

String _cleanArtistSearchTerm(String value) {
  return _stripLegacyArtistSuffixes(_normalizeArtistText(value))
      .replaceAll(RegExp(r'\s*vevo\s*$', caseSensitive: false), '')
      .replaceAll(
        RegExp(r'\s*official artist channel\s*$', caseSensitive: false),
        '',
      )
      .trim();
}

String _stripLegacyArtistSuffixes(String value) {
  return _normalizeArtistText(value)
      .trim()
      .replaceAll(RegExp(r'\s*topic channel\s*$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*-\s*topic\s*$', caseSensitive: false), '')
      .trim();
}

bool _strictSameArtistTitle(String left, String right) {
  final leftKey = _strictArtistTitleKey(left);
  final rightKey = _strictArtistTitleKey(right);

  return leftKey.isNotEmpty && leftKey == rightKey;
}

String _strictArtistTitleKey(String value) {
  return _cleanArtistSearchTerm(value)
      .toLowerCase()
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\bofficial artist channel\b'), '')
      .replaceAll(RegExp(r'\bofficial channel\b'), '')
      .replaceAll(RegExp(r'\bmusic channel\b'), '')
      .replaceAll(RegExp(r'\bofficial\b'), '')
      .replaceAll(RegExp(r'\bvevo\b'), '')
      .replaceAll(RegExp('[^a-z0-9&]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalizeArtistText(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    buffer.writeCharCode(_normalizeStyledRune(rune) ?? rune);
  }
  return buffer.toString();
}

int? _normalizeStyledRune(int rune) {
  int? mapLetters(int upperStart, int lowerStart) {
    if (rune >= upperStart && rune <= upperStart + 25) {
      return 0x41 + rune - upperStart;
    }
    if (rune >= lowerStart && rune <= lowerStart + 25) {
      return 0x61 + rune - lowerStart;
    }
    return null;
  }

  int? mapDigits(int digitStart) {
    if (rune >= digitStart && rune <= digitStart + 9) {
      return 0x30 + rune - digitStart;
    }
    return null;
  }

  for (final range in const [
    (0x1D400, 0x1D41A),
    (0x1D434, 0x1D44E),
    (0x1D468, 0x1D482),
    (0x1D4D0, 0x1D4EA),
    (0x1D56C, 0x1D586),
    (0x1D5A0, 0x1D5BA),
    (0x1D5D4, 0x1D5EE),
    (0x1D608, 0x1D622),
    (0x1D63C, 0x1D656),
    (0x1D670, 0x1D68A),
    (0xFF21, 0xFF41),
  ]) {
    final mapped = mapLetters(range.$1, range.$2);
    if (mapped != null) return mapped;
  }

  for (final digitStart in const [
    0x1D7CE,
    0x1D7D8,
    0x1D7E2,
    0x1D7EC,
    0x1D7F6,
    0xFF10,
  ]) {
    final mapped = mapDigits(digitStart);
    if (mapped != null) return mapped;
  }

  return null;
}

String _canonicalSongTitle(String value) {
  return formatSongTitle(value)
      .toLowerCase()
      .replaceAll('&amp;', '&')
      .replaceAll(
        RegExp(r'\b(official|audio|video|lyrics?|visuali[sz]er)\b'),
        '',
      )
      .replaceAll(RegExp('[^a-z0-9]+'), '');
}

String _canonicalArtistName(String value) {
  final lower = _normalizeArtistText(value)
      .toLowerCase()
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s*-\s*topic\b'), '')
      .replaceAll(RegExp(r'\bofficial artist channel\b'), '')
      .replaceAll(RegExp(r'\bofficial channel\b'), '')
      .replaceAll(RegExp(r'\bmusic channel\b'), '')
      .replaceAll(RegExp(r'\bofficial\b'), '')
      .trim();

  var cleaned = lower.replaceAll(RegExp('[^a-z0-9]+'), '');
  var previous = '';
  while (cleaned != previous) {
    previous = cleaned;
    cleaned = cleaned.replaceAll(
      RegExp(r'(official|music|channel|topic|vevo)$'),
      '',
    );
  }

  if (cleaned.isNotEmpty) return cleaned;

  return lower.replaceAll(RegExp(r'\s+'), '');
}

bool _isChannelId(String value) => ChannelId.validateChannelId(value);
