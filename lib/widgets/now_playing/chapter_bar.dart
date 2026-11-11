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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/models/song_chapter.dart';
import 'package:musify/services/chapters_service.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/utilities/formatter.dart';

/// Steps through the tracks of a long video, and names the one being played.
///
/// Shows nothing at all for a song that is a single track, which is nearly all
/// of them.
class ChapterBar extends StatelessWidget {
  const ChapterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SongChapters?>(
      valueListenable: chaptersService.current,
      builder: (context, chapters, __) {
        if (chapters == null || chapters.isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<PositionData>(
          stream: audioHandler.positionDataStream,
          initialData: audioHandler.currentPositionData,
          builder: (context, snapshot) {
            final position = snapshot.data?.position ?? Duration.zero;
            final index = chapters.indexAt(position);
            if (index < 0) return const SizedBox.shrink();

            return _bar(context, chapters, index);
          },
        );
      },
    );
  }

  Widget _bar(BuildContext context, SongChapters chapters, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _StepButton(
            icon: FluentIcons.chevron_left_24_regular,
            tooltip: l10n.previousChapter,
            onPressed: audioHandler.seekToPreviousChapter,
            colorScheme: colorScheme,
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showCustomBottomSheet(
                context,
                ChapterListView(chapters: chapters),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${index + 1}/${chapters.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        chapterLabel(chapters.chapters[index]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _StepButton(
            icon: FluentIcons.chevron_right_24_regular,
            tooltip: l10n.nextChapter,
            onPressed: index < chapters.length - 1
                ? audioHandler.seekToNextChapter
                : null,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

/// A chapter the uploader left unnamed is still worth jumping to, so it goes
/// by the time it starts at.
String chapterLabel(SongChapter chapter) => chapter.title.isNotEmpty
    ? chapter.title
    : formatDuration(chapter.start.inSeconds);

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colorScheme,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: onPressed == null
            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
            : colorScheme.onSurfaceVariant,
      ),
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

/// The whole tracklist, to jump straight to a track rather than step to it.
class ChapterListView extends StatelessWidget {
  const ChapterListView({super.key, required this.chapters});

  final SongChapters chapters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream,
      initialData: audioHandler.currentPositionData,
      builder: (context, snapshot) {
        final current = chapters.indexAt(
          snapshot.data?.position ?? Duration.zero,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                context.l10n!.chapters,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            for (var i = 0; i < chapters.length; i++)
              ListTile(
                selected: i == current,
                selectedColor: colorScheme.primary,
                leading: SizedBox(
                  width: 62,
                  child: Text(
                    formatDuration(chapters.chapters[i].start.inSeconds),
                    style: TextStyle(
                      fontSize: 13,
                      color: i == current
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(
                  chapterLabel(chapters.chapters[i]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  unawaited(audioHandler.seekToChapter(i));
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }
}
