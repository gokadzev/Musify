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

import 'package:musify/API/musify.dart';
import 'package:musify/main.dart';
import 'package:musify/models/scored_song.dart';

class MusifyAlgorithm {
  factory MusifyAlgorithm() => _instance;
  MusifyAlgorithm._();
  static final MusifyAlgorithm _instance = MusifyAlgorithm._();

  /// Base scores for different song sources
  static const double likedSongScore = 10;
  static const double likedPlaylistSongScore = 8;
  static const double userPlaylistScore = 7;
  static const double youtubePlaylistScore = 6;
  static const double recentlyPlayedScore = 6;
  static const double globalSongScore = 3;

  /// Configuration
  static const int recentSongsToAvoid = 5;
  static const int olderRecentSongsToInclude = 15;
  static const int defaultRecommendationCount = 15;
  static const int defaultMaxPerArtist = 2;

  /// Gets recommendations from mixed sources using Musify's own algorithm
  Future<List> getRecommendations() async {
    try {
      final scoredSongs = <ScoredSong>[];
      final seenYtIds = <String>{};

      // Get recently played ytids to avoid (last N songs)
      final recentlyPlayedYtIds = userRecentlyPlayed
          .take(recentSongsToAvoid)
          .map((s) => s['ytid']?.toString())
          .whereType<String>()
          .toSet();

      // Build artist affinity map from user's library
      final artistAffinity = _buildArtistAffinityMap();

      // 1. Add liked songs with high weight
      _addLikedSongs(
        scoredSongs,
        seenYtIds,
        recentlyPlayedYtIds,
        artistAffinity,
      );

      // 2. Add songs from liked playlists
      await _addLikedPlaylistSongs(
        scoredSongs,
        seenYtIds,
        recentlyPlayedYtIds,
        artistAffinity,
      );

      // 3. Add songs from user's YouTube playlists
      await _addYoutubePlaylistSongs(
        scoredSongs,
        seenYtIds,
        recentlyPlayedYtIds,
        artistAffinity,
      );

      // 4. Add recently played (skip the most recent, take older ones)
      _addOlderRecentlyPlayed(scoredSongs, seenYtIds, artistAffinity);

      // 5. Add songs from user custom playlists
      _addUserPlaylistSongs(
        scoredSongs,
        seenYtIds,
        recentlyPlayedYtIds,
        artistAffinity,
      );

      // 6. Add global songs as fallback/discovery
      await _addGlobalSongs(scoredSongs, seenYtIds, artistAffinity);

      return _selectDiverseRecommendations(scoredSongs);
    } catch (e, stackTrace) {
      logger.log('Error in MusifyAlgorithm.getRecommendations', e, stackTrace);
      return [];
    }
  }

  /// Builds a map of artist -> occurrence count from user's library
  Map<String, int> _buildArtistAffinityMap() {
    final affinity = <String, int>{};

    // Count from liked songs
    for (final song in userLikedSongsList) {
      final artist = _extractArtist(song);
      affinity[artist] = (affinity[artist] ?? 0) + 2; // Liked = 2x weight
    }

    // Count from recently played
    for (final song in userRecentlyPlayed) {
      final artist = _extractArtist(song);
      affinity[artist] = (affinity[artist] ?? 0) + 1;
    }

    // Count from custom playlists
    for (final playlist in userCustomPlaylists.value) {
      final songs = playlist['list'] as List? ?? [];
      for (final song in songs) {
        final artist = _extractArtist(song);
        affinity[artist] = (affinity[artist] ?? 0) + 1;
      }
    }

    return affinity;
  }

  void _addLikedSongs(
    List<ScoredSong> scoredSongs,
    Set<String> seenYtIds,
    Set<String> recentlyPlayedYtIds,
    Map<String, int> artistAffinity,
  ) {
    for (final song in userLikedSongsList) {
      final ytid = song['ytid']?.toString();
      if (ytid != null && seenYtIds.add(ytid)) {
        final isRecentlyPlayed = recentlyPlayedYtIds.contains(ytid);
        final artist = _extractArtist(song);
        scoredSongs.add(
          ScoredSong(
            song: song,
            baseScore: likedSongScore,
            isLiked: true,
            isRecentlyPlayed: isRecentlyPlayed,
            artistAffinity: artistAffinity[artist] ?? 0,
          ),
        );
      }
    }
  }

  Future<void> _addLikedPlaylistSongs(
    List<ScoredSong> scoredSongs,
    Set<String> seenYtIds,
    Set<String> recentlyPlayedYtIds,
    Map<String, int> artistAffinity,
  ) async {
    if (userLikedPlaylists.isEmpty) return;

    for (final playlist in userLikedPlaylists) {
      final playlistId = playlist['ytid']?.toString();
      if (playlistId == null) continue;

      try {
        // Get songs from the liked playlist (uses cache if available)
        final songs = await getSongsFromPlaylist(playlistId);

        for (final song in songs) {
          final ytid = song['ytid']?.toString();
          if (ytid != null && seenYtIds.add(ytid)) {
            final isRecentlyPlayed = recentlyPlayedYtIds.contains(ytid);
            final artist = _extractArtist(song);
            scoredSongs.add(
              ScoredSong(
                song: song,
                baseScore: likedPlaylistSongScore,
                isLiked: false,
                isRecentlyPlayed: isRecentlyPlayed,
                isFromLikedPlaylist: true,
                artistAffinity: artistAffinity[artist] ?? 0,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        logger.log('Error loading liked playlist $playlistId', e, stackTrace);
      }
    }
  }

  Future<void> _addYoutubePlaylistSongs(
    List<ScoredSong> scoredSongs,
    Set<String> seenYtIds,
    Set<String> recentlyPlayedYtIds,
    Map<String, int> artistAffinity,
  ) async {
    if (userPlaylists.value.isEmpty) return;

    for (final playlistId in userPlaylists.value) {
      try {
        // Get songs from the YouTube playlist (uses cache if available)
        final songs = await getSongsFromPlaylist(playlistId);

        for (final song in songs) {
          final ytid = song['ytid']?.toString();
          if (ytid != null && seenYtIds.add(ytid)) {
            final isRecentlyPlayed = recentlyPlayedYtIds.contains(ytid);
            final artist = _extractArtist(song);
            scoredSongs.add(
              ScoredSong(
                song: song,
                baseScore: youtubePlaylistScore,
                isLiked: false,
                isRecentlyPlayed: isRecentlyPlayed,
                isFromUserPlaylist: true,
                artistAffinity: artistAffinity[artist] ?? 0,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        logger.log('Error loading YouTube playlist $playlistId', e, stackTrace);
      }
    }
  }

  void _addOlderRecentlyPlayed(
    List<ScoredSong> scoredSongs,
    Set<String> seenYtIds,
    Map<String, int> artistAffinity,
  ) {
    final olderRecentlyPlayed = userRecentlyPlayed
        .skip(recentSongsToAvoid)
        .take(olderRecentSongsToInclude);

    for (final song in olderRecentlyPlayed) {
      final ytid = song['ytid']?.toString();
      if (ytid != null && seenYtIds.add(ytid)) {
        final artist = _extractArtist(song);
        scoredSongs.add(
          ScoredSong(
            song: song,
            baseScore: recentlyPlayedScore,
            isLiked: false,
            artistAffinity: artistAffinity[artist] ?? 0,
          ),
        );
      }
    }
  }

  void _addUserPlaylistSongs(
    List<ScoredSong> scoredSongs,
    Set<String> seenYtIds,
    Set<String> recentlyPlayedYtIds,
    Map<String, int> artistAffinity,
  ) {
    if (userCustomPlaylists.value.isEmpty) return;

    for (final userPlaylist in userCustomPlaylists.value) {
      final playlistList = userPlaylist['list'] as List? ?? [];
      for (final song in playlistList) {
        final ytid = song['ytid']?.toString();
        if (ytid != null && seenYtIds.add(ytid)) {
          final isRecentlyPlayed = recentlyPlayedYtIds.contains(ytid);
          final artist = _extractArtist(song);
          scoredSongs.add(
            ScoredSong(
              song: song,
              baseScore: userPlaylistScore,
              isLiked: false,
              isRecentlyPlayed: isRecentlyPlayed,
              isFromUserPlaylist: true,
              artistAffinity: artistAffinity[artist] ?? 0,
            ),
          );
        }
      }
    }
  }

  Future<void> _addGlobalSongs(
    List<ScoredSong> scoredSongs,
    Set<String> seenYtIds,
    Map<String, int> artistAffinity,
  ) async {
    if (globalSongs.isEmpty) {
      const playlistId = 'PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx';
      globalSongs = await getSongsFromPlaylist(playlistId);
    }

    for (final song in globalSongs) {
      final ytid = song['ytid']?.toString();
      if (ytid != null && seenYtIds.add(ytid)) {
        final artist = _extractArtist(song);
        scoredSongs.add(
          ScoredSong(
            song: song,
            baseScore: globalSongScore,
            isLiked: false,
            artistAffinity: artistAffinity[artist] ?? 0,
          ),
        );
      }
    }
  }

  /// Selects diverse recommendations using weighted scoring and artist limiting
  List _selectDiverseRecommendations(
    List<ScoredSong> scoredSongs, {
    int count = defaultRecommendationCount,
    int maxPerArtist = defaultMaxPerArtist,
  }) {
    if (scoredSongs.isEmpty) return [];

    // Calculate final scores with randomization
    final seed = DateTime.now().millisecondsSinceEpoch;
    for (final scored in scoredSongs) {
      scored.calculateFinalScore(seed);
    }

    // Sort by final score (descending)
    scoredSongs.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    // Select with artist diversity
    final selected = <Map>[];
    final artistCount = <String, int>{};

    for (final scored in scoredSongs) {
      if (selected.length >= count) break;

      final artist = _extractArtist(scored.song);

      // Limit songs per artist for diversity
      final currentCount = artistCount[artist] ?? 0;
      if (currentCount >= maxPerArtist) continue;

      selected.add(scored.song);
      artistCount[artist] = currentCount + 1;
    }

    // Final shuffle to avoid predictable ordering
    selected.shuffle();
    return selected;
  }

  /// Extracts artist name from song, with fallback
  String _extractArtist(Map song) {
    final artist = song['artist']?.toString().toLowerCase().trim();
    if (artist != null && artist.isNotEmpty && artist != 'unknown') {
      return artist;
    }
    // Fallback: try to extract from title (common format: "Artist - Title")
    final title = song['title']?.toString() ?? '';
    final dashIndex = title.indexOf(' - ');
    if (dashIndex > 0) {
      return title.substring(0, dashIndex).toLowerCase().trim();
    }
    return 'unknown_${song['ytid'] ?? ''}';
  }
}
