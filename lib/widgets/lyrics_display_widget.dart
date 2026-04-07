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
import 'package:musify/models/lyric_line.dart';
import 'package:musify/models/position_data.dart';

/// Displays synced lyrics with real-time highlighting and auto-scrolling
class SyncedLyricsWidget extends StatefulWidget {
  const SyncedLyricsWidget({
    super.key,
    required this.lyrics,
    required this.positionDataStream,
  });

  /// Raw LRC format lyrics string
  final String lyrics;

  /// Stream providing current playback position
  final Stream<PositionData> positionDataStream;

  @override
  State<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends State<SyncedLyricsWidget> {
  late final List<LyricLine> _lines;
  late final ScrollController _scrollController;
  int _currentLineIndex = -1;

  @override
  void initState() {
    super.initState();
    _lines = LrcParser.parse(widget.lyrics);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const double _itemExtent = 52;

  void _scrollToCurrentLine(int lineIndex) {
    if (_lines.isEmpty || !_scrollController.hasClients) return;

    // Center the current line in the viewport
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset =
        lineIndex * _itemExtent - (viewportHeight / 2) + (_itemExtent / 2);
    final maxScroll = _scrollController.position.maxScrollExtent;
    final safeOffset = targetOffset.clamp(0.0, maxScroll);

    if ((safeOffset - _scrollController.offset).abs() > 1) {
      _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return _buildEmptyState(context);
    }

    return StreamBuilder<PositionData>(
      stream: widget.positionDataStream,
      builder: (context, snapshot) {
        final positionMs = snapshot.data?.position.inMilliseconds ?? 0;
        final currentLineIndex = LrcParser.findCurrentLineIndex(
          _lines,
          positionMs,
        );

        // Only update if line actually changed
        if (currentLineIndex != _currentLineIndex) {
          _currentLineIndex = currentLineIndex;
          Future.microtask(() => _scrollToCurrentLine(currentLineIndex));
        }

        return _buildLyricsList(context);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 48,
            color: colorScheme.onSecondaryContainer.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No lyrics available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lines.length,
      itemExtent: _itemExtent,
      itemBuilder: (context, index) {
        final isCurrentLine = index == _currentLineIndex;

        return Align(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: _getLyricTextStyle(isCurrentLine, colorScheme),
            child: Text(
              _lines[index].text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  TextStyle _getLyricTextStyle(bool isCurrentLine, ColorScheme colorScheme) {
    if (isCurrentLine) {
      return TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
        height: 1.3,
        letterSpacing: 0.3,
      );
    }

    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSecondaryContainer.withValues(alpha: 0.5),
      height: 1.3,
    );
  }
}

/// Displays plain text lyrics (non-synced)
class PlainLyricsWidget extends StatelessWidget {
  const PlainLyricsWidget({super.key, required this.lyrics});

  /// Plain text lyrics
  final String lyrics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Text(
        lyrics,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSecondaryContainer,
          height: 1.7,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Smart lyrics widget that automatically chooses between synced and plain display
class LyricsDisplayWidget extends StatelessWidget {
  const LyricsDisplayWidget({
    super.key,
    required this.lyrics,
    required this.positionDataStream,
  });

  /// Lyrics text (can be LRC format or plain text)
  final String lyrics;

  /// Stream providing current playback position
  final Stream<PositionData> positionDataStream;

  @override
  Widget build(BuildContext context) {
    // Check if lyrics are in LRC (synced) format
    if (LrcParser.isSynced(lyrics)) {
      return SyncedLyricsWidget(
        lyrics: lyrics,
        positionDataStream: positionDataStream,
      );
    }

    // Fallback to plain text display
    return PlainLyricsWidget(lyrics: lyrics);
  }
}
