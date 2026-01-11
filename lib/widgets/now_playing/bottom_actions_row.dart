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
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/song_bar.dart';

class BottomActionsRow extends StatelessWidget {
  const BottomActionsRow({
    super.key,
    required this.audioId,
    required this.metadata,
    required this.iconSize,
    required this.isLargeScreen,
    required this.lyricsController,
  });
  final dynamic audioId;
  final MediaItem metadata;
  final double iconSize;
  final bool isLargeScreen;
  final dynamic lyricsController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final songLikeStatus = ValueNotifier<bool>(isSongAlreadyLiked(audioId));
    final songOfflineStatus = ValueNotifier<bool>(
      isSongAlreadyOffline(audioId),
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    final responsiveIconSize = screenWidth < 360 ? iconSize * 0.85 : iconSize;
    final spacing = screenWidth < 360 ? 6.0 : 10.0;

    return StreamBuilder<List<MediaItem>>(
      stream: audioHandler.queue,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];
        final mappedQueue = queue.isNotEmpty
            ? queue.map(mediaItemToMap).toList()
            : [];

        final actions = <Widget>[
          _buildActionButton(
            context: context,
            icon: FluentIcons.cellular_data_1_24_regular,
            activeIcon: FluentIcons.cellular_off_24_regular,
            colorScheme: colorScheme,
            size: responsiveIconSize,
            statusNotifier: songOfflineStatus,
            onPressed: audioId == null
                ? null
                : () => _toggleOffline(songOfflineStatus, audioId, metadata),
            tooltip: 'Offline',
          ),
        ];

        if (!offlineMode.value) {
          actions.add(
            _buildSimpleActionButton(
              context: context,
              icon: FluentIcons.add_24_regular,
              colorScheme: colorScheme,
              size: responsiveIconSize,
              onPressed: () =>
                  showAddToPlaylistDialog(context, mediaItemToMap(metadata)),
              tooltip: 'Add to playlist',
            ),
          );
        }

        if (queue.isNotEmpty && !isLargeScreen) {
          actions.add(
            _buildSimpleActionButton(
              context: context,
              icon: FluentIcons.apps_list_24_filled,
              colorScheme: colorScheme,
              size: responsiveIconSize,
              onPressed: () => _showQueue(context, mappedQueue),
              tooltip: 'Queue',
            ),
          );
        }

        if (!offlineMode.value) {
          actions.addAll([
            _buildActionButton(
              context: context,
              icon: FluentIcons.heart_24_regular,
              activeIcon: FluentIcons.heart_24_filled,
              colorScheme: colorScheme,
              size: responsiveIconSize,
              statusNotifier: songLikeStatus,
              activeColor: colorScheme.primary,
              onPressed: () {
                updateSongLikeStatus(audioId, !songLikeStatus.value);
                songLikeStatus.value = !songLikeStatus.value;
              },
              tooltip: 'Like',
            ),
            _buildSimpleActionButton(
              context: context,
              icon: FluentIcons.text_quote_24_regular,
              colorScheme: colorScheme,
              size: responsiveIconSize,
              onPressed: lyricsController.flipcard,
              tooltip: 'Lyrics',
            ),
            _buildSleepTimerButton(context, colorScheme, responsiveIconSize),
          ]);
        }

        final childrenWithSpacing = <Widget>[];
        for (var i = 0; i < actions.length; i++) {
          childrenWithSpacing.add(actions[i]);
          if (i != actions.length - 1) {
            childrenWithSpacing.add(SizedBox(width: spacing));
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: childrenWithSpacing,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required ColorScheme colorScheme,
    required double size,
    required ValueNotifier<bool> statusNotifier,
    required VoidCallback? onPressed,
    Color? activeColor,
    String? tooltip,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: statusNotifier,
      builder: (_, isActive, __) {
        return IconButton(
          icon: Icon(
            isActive ? activeIcon : icon,
            color: isActive
                ? (activeColor ?? colorScheme.primary)
                : colorScheme.onSurfaceVariant,
          ),
          iconSize: size,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: isActive
                ? (activeColor ?? colorScheme.primary).withValues(alpha: 0.15)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
        );
      },
    );
  }

  Widget _buildSimpleActionButton({
    required BuildContext context,
    required IconData icon,
    required ColorScheme colorScheme,
    required double size,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, color: colorScheme.onSurfaceVariant),
      iconSize: size,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildSleepTimerButton(
    BuildContext context,
    ColorScheme colorScheme,
    double size,
  ) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: sleepTimerNotifier,
      builder: (_, value, __) {
        final isActive = value != null;
        return IconButton(
          icon: Icon(
            isActive
                ? FluentIcons.timer_24_filled
                : FluentIcons.timer_24_regular,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          iconSize: size,
          tooltip: 'Sleep timer',
          style: IconButton.styleFrom(
            backgroundColor: isActive
                ? colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (isActive) {
              audioHandler.cancelSleepTimer();
              sleepTimerNotifier.value = null;
              showToast(
                context,
                context.l10n!.sleepTimerCancelled,
                duration: const Duration(seconds: 1, milliseconds: 500),
              );
            } else {
              _showSleepTimerDialog(context);
            }
          },
        );
      },
    );
  }
}

Future<void> _toggleOffline(
  ValueNotifier<bool> status,
  dynamic audioId,
  MediaItem metadata,
) async {
  final originalValue = status.value;
  status.value = !originalValue;

  try {
    final bool success;
    if (originalValue) {
      success = await removeSongFromOffline(audioId);
    } else {
      success = await makeSongOffline(mediaItemToMap(metadata));
    }
    if (!success) {
      status.value = originalValue;
    }
  } catch (e) {
    status.value = originalValue;
    logger.log('Error toggling offline status', e, null);
  }
}

void _showQueue(BuildContext context, List<dynamic> mappedQueue) {
  final colorScheme = Theme.of(context).colorScheme;
  final currentIndex = audioHandler.currentQueueIndex;

  showCustomBottomSheet(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FluentIcons.apps_list_24_filled,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n!.queue,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${mappedQueue.length} ${context.l10n!.songs}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  audioHandler.clearQueue();
                  Navigator.pop(context);
                },
                icon: const Icon(FluentIcons.dismiss_24_regular, size: 18),
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
        // Queue list
        ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: commonListViewBottomPadding,
          itemCount: mappedQueue.length,
          itemBuilder: (BuildContext context, int index) {
            final isCurrentSong = index == currentIndex;
            final borderRadius = getItemBorderRadius(index, mappedQueue.length);

            return SongBar(
              mappedQueue[index],
              false,
              onPlay: () {
                audioHandler.skipToSong(index);
                Navigator.pop(context);
              },
              backgroundColor: isCurrentSong
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerHigh,
              borderRadius: borderRadius,
            );
          },
        ),
      ],
    ),
  );
}

void _showSleepTimerDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (context) {
      final duration = sleepTimerNotifier.value ?? Duration.zero;
      var hours = duration.inMinutes ~/ 60;
      var minutes = duration.inMinutes % 60;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: colorScheme.surfaceContainerHigh,
            title: Row(
              children: [
                Icon(FluentIcons.timer_24_regular, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  context.l10n!.setSleepTimer,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n!.selectDuration,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTimeSelector(
                  context: context,
                  label: context.l10n!.hours,
                  value: hours,
                  colorScheme: colorScheme,
                  onDecrement: () {
                    if (hours > 0) setState(() => hours--);
                  },
                  onIncrement: () => setState(() => hours++),
                ),
                const SizedBox(height: 16),
                _buildTimeSelector(
                  context: context,
                  label: context.l10n!.minutes,
                  value: minutes,
                  colorScheme: colorScheme,
                  onDecrement: () {
                    if (minutes > 0) setState(() => minutes--);
                  },
                  onIncrement: () {
                    if (minutes < 59) setState(() => minutes++);
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [15, 30, 45, 60].map((mins) {
                    return ActionChip(
                      label: Text('$mins min'),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onPressed: () {
                        setState(() {
                          hours = mins ~/ 60;
                          minutes = mins % 60;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.l10n!.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final duration = Duration(hours: hours, minutes: minutes);
                  if (duration.inSeconds > 0) {
                    audioHandler.setSleepTimer(duration);
                    showToast(
                      context,
                      context.l10n!.sleepTimerSet,
                      duration: const Duration(seconds: 1, milliseconds: 500),
                    );
                  }
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.l10n!.setTimer),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildTimeSelector({
  required BuildContext context,
  required String label,
  required int value,
  required ColorScheme colorScheme,
  required VoidCallback onDecrement,
  required VoidCallback onIncrement,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.remove_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onDecrement,
            ),
            Container(
              width: 48,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    ),
  );
}
