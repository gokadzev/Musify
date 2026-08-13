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

/// Cache versioning constants for artist-related data
const int artistCatalogCacheVersion = 16;
const int artistSearchCacheVersion = 10;
const int artistProfileCacheVersion = 5;
const int artistAlbumCacheVersion = 2;
const int artistChannelCacheVersion = 2;

/// Request timeouts for artist API calls
const Duration artistRequestTimeout = Duration(seconds: 12);
const Duration artistProfileTimeout = Duration(seconds: 25);
const Duration musicAlbumTimeout = Duration(seconds: 12);
const int musicAlbumBatchSize = 6;

/// Regex patterns for artist name and text normalization
/// Compiled once for efficiency across multiple function calls
final class ArtistPatterns {
  ArtistPatterns._(); // Prevent instantiation

  // Patterns for removing common suffixes and labels
  static final topicChannel = RegExp(
    r'\s*topic channel\s*$',
    caseSensitive: false,
  );
  static final topicSuffix = RegExp(r'\s*-\s*topic\s*$', caseSensitive: false);
  static final officialArtistChannel = RegExp(
    r'\s*official artist channel\s*$',
    caseSensitive: false,
  );
  static final vevo = RegExp(r'\s*vevo\s*$', caseSensitive: false);

  // Word boundary patterns for strict matching
  static final officialChannel = RegExp(r'\bofficial channel\b');
  static final musicChannel = RegExp(r'\bmusic channel\b');
  static final official = RegExp(r'\bofficial\b');
  static final vevoWord = RegExp(r'\bvevo\b');

  // Patterns for canonicalization
  static final audioVideoLyrics = RegExp(
    r'\b(official|audio|video|lyrics?|visuali[sz]er)\b',
  );
  static final nonAlphanumeric = RegExp('[^a-z0-9&]+');
  static final multipleSpaces = RegExp(r'\s+');

  // Patterns for splitting featured artists
  static final feature = RegExp(
    r'\s+(?:feat\.?|ft\.?|featuring|with)\s+',
    caseSensitive: false,
  );
  static final collaboration = RegExp(
    r'\s+(?:x|\+|&)\s+',
    caseSensitive: false,
  );

  // Pattern for YouTube Music counters (e.g., "331M plays")
  static final countToken = RegExp(r'^\d+(?:[\.,]\d+)?\s?[KMBkmb]?\b');
}

/// Unicode ranges for styled character normalization (bold, italic, etc.)
/// Used to convert styled Unicode letters and digits to ASCII equivalents
final class StyledCharacterRanges {
  StyledCharacterRanges._(); // Prevent instantiation

  static const List<(int, int)> charRanges = [
    (0x1D400, 0x1D41A), // Mathematical Alphanumeric Symbols - Bold
    (0x1D434, 0x1D44E), // Mathematical Alphanumeric Symbols - Italic
    (0x1D468, 0x1D482), // Mathematical Alphanumeric Symbols - Bold Italic
    (0x1D4D0, 0x1D4EA), // Mathematical Alphanumeric Symbols - Double-struck
    (0x1D56C, 0x1D586), // Mathematical Alphanumeric Symbols - Bold Fraktur
    (0x1D5A0, 0x1D5BA), // Mathematical Alphanumeric Symbols - Script
    (0x1D5D4, 0x1D5EE), // Mathematical Alphanumeric Symbols - Bold Script
    (0x1D608, 0x1D622), // Mathematical Alphanumeric Symbols - Fraktur
    (
      0x1D63C,
      0x1D656,
    ), // Mathematical Alphanumeric Symbols - Double-struck Script
    (0x1D670, 0x1D68A), // Mathematical Alphanumeric Symbols - Bold Fraktur
    (0xFF21, 0xFF41), // Fullwidth Latin Letters
  ];

  static const List<int> digitStarts = [
    0x1D7CE, // Mathematical Alphanumeric Symbols - Bold Digits
    0x1D7D8, // Mathematical Alphanumeric Symbols - Double-struck Digits
    0x1D7E2, // Mathematical Alphanumeric Symbols - Bold Fraktur Digits
    0x1D7EC, // Mathematical Alphanumeric Symbols - Bold Script Digits
    0x1D7F6, // Mathematical Alphanumeric Symbols - Bold Monospace Digits
    0xFF10, // Fullwidth Digits
  ];
}
