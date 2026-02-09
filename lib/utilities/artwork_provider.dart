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

import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ArtworkProvider {
  ArtworkProvider._();

  static final Map<String, ImageProvider> _cache = {};

  static ImageProvider get(String artwork) {
    if (artwork.isEmpty) throw ArgumentError('artwork must not be empty');

    final cached = _cache[artwork];
    if (cached != null) return cached;

    late ImageProvider provider;
    try {
      if (artwork.startsWith('http')) {
        provider = CachedNetworkImageProvider(artwork);
      } else if (artwork.startsWith('data:image')) {
        final commaIdx = artwork.indexOf(',');
        if (commaIdx == -1) throw Exception('invalid base64 image');
        final bytes = base64Decode(artwork.substring(commaIdx + 1));
        provider = MemoryImage(bytes);
      } else if (!kIsWeb &&
          (artwork.startsWith('file://') || artwork.startsWith('/'))) {
        final path = artwork.replaceFirst('file://', '');
        provider = FileImage(File(path));
      } else {
        provider = AssetImage(artwork);
      }
    } catch (_) {
      provider = const AssetImage('assets/placeholder.png');
    }

    _cache[artwork] = provider;
    return provider;
  }

  static void clearCache() => _cache.clear();
}
