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

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/song_bar.dart';

class QueueListView extends StatelessWidget {
  const QueueListView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<MediaItem>>(
      stream: audioHandler.queue,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];
        final mappedQueue = queue.isNotEmpty
            ? queue.map(mediaItemToMap).toList()
            : [];

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FluentIcons.apps_list_24_filled,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n!.queue,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (mappedQueue.isNotEmpty)
                          Text(
                            '${mappedQueue.length} ${context.l10n!.songs.toLowerCase()}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (mappedQueue.isNotEmpty)
                    FilledButton.tonalIcon(
                      onPressed: () {
                        audioHandler.clearQueue();
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        FluentIcons.dismiss_24_regular,
                        size: 18,
                      ),
                      label: Text(context.l10n!.clear),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              indent: 20,
              endIndent: 20,
            ),

            // Queue list
            Expanded(
              child: mappedQueue.isEmpty
                  ? _buildEmptyState(context, colorScheme, textTheme)
                  : _buildQueueList(context, mappedQueue, colorScheme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.music_note_1_24_regular,
                color: colorScheme.onSurfaceVariant,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n!.noSongsInQueue,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    List<dynamic> mappedQueue,
    ColorScheme colorScheme,
  ) {
    final currentIndex = audioHandler.currentQueueIndex;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: mappedQueue.length,
      itemBuilder: (context, index) {
        final song = mappedQueue[index];
        final isCurrentSong = index == currentIndex;
        final borderRadius = getItemBorderRadius(index, mappedQueue.length);

        return SongBar(
          song,
          false,
          onPlay: () {
            audioHandler.skipToSong(index);
          },
          backgroundColor: isCurrentSong
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHigh,
          borderRadius: borderRadius,
        );
      },
    );
  }
}
