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

/// Model class for scoring songs in the recommendation algorithm
class ScoredSong {
  ScoredSong({
    required this.song,
    required this.baseScore,
    required this.isLiked,
    this.isRecentlyPlayed = false,
    this.isFromUserPlaylist = false,
    this.isFromLikedPlaylist = false,
    this.artistAffinity = 0,
  });

  final Map song;
  final double baseScore;
  final bool isLiked;
  final bool isRecentlyPlayed;
  final bool isFromUserPlaylist;
  final bool isFromLikedPlaylist;
  final int
  artistAffinity; // How many times this artist appears in user's library
  double finalScore = 0;

  /// Scoring weights for recommendation algorithm
  static const double likedBonus = 3;
  static const double userPlaylistBonus = 2;
  static const double likedPlaylistBonus = 4;
  static const double recentlyPlayedPenalty = 8;
  static const double maxRandomFactor = 5;
  static const double artistAffinityMultiplier = 1.5; // Per occurrence

  /// Calculates the final score with all bonuses, penalties and randomization
  void calculateFinalScore(int seed) {
    var score = baseScore;

    // Bonus for liked songs
    if (isLiked) score += likedBonus;

    // Bonus for songs from user playlists
    if (isFromUserPlaylist) score += userPlaylistBonus;

    // Bonus for songs from liked playlists
    if (isFromLikedPlaylist) score += likedPlaylistBonus;

    // Bonus for favorite artists (capped at 5 occurrences)
    final cappedAffinity = artistAffinity.clamp(0, 5);
    score += cappedAffinity * artistAffinityMultiplier;

    // Penalty for very recently played
    if (isRecentlyPlayed) score -= recentlyPlayedPenalty;

    // Add randomization factor (0 to maxRandomFactor points)
    final randomFactor =
        ((song['ytid'].hashCode ^ seed) % 500) / 100.0; // 0.0 to 5.0
    score += randomFactor;

    finalScore = score;
  }
}
