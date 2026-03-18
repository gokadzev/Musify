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
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/no_artwork_cube.dart';

class QueueWidget extends StatefulWidget {
  const QueueWidget({super.key, this.isBottomSheet = false});

  final bool isBottomSheet;

  @override
  State<QueueWidget> createState() => _QueueWidgetState();
}

class _QueueWidgetState extends State<QueueWidget> {
  List<Map> _queue = [];
  late StreamSubscription<List<Map>> _subscription;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _subscription = audioHandler.queueAsMapStream.listen((queue) {
      if (mounted && !_isDismissing) {
        setState(() {
          _queue = List<Map>.from(queue);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentIndex = audioHandler.currentQueueIndex;

    if (widget.isBottomSheet) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, colorScheme, textTheme, compact: true),
          _buildBottomSheetContent(context, colorScheme, currentIndex),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(context, colorScheme, textTheme, compact: false),
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          indent: 8,
          endIndent: 8,
        ),
        Expanded(
          child: _queue.isEmpty
              ? _buildEmptyState(context, colorScheme, textTheme)
              : _buildList(context, colorScheme, currentIndex),
        ),
      ],
    );
  }

  void _confirmClearQueue(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmationDialog(
        confirmationMessage: context.l10n!.clearQueueQuestion,
        submitMessage: context.l10n!.clear,
        isDangerous: true,
        onCancel: () => Navigator.pop(context),
        onSubmit: () {
          Navigator.pop(context);
          audioHandler.clearQueue();
          if (widget.isBottomSheet) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required bool compact,
  }) {
    return Padding(
      padding: compact
          ? const EdgeInsets.only(left: 10, right: 8, bottom: 12)
          : const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 8 : 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              FluentIcons.apps_list_24_filled,
              color: colorScheme.onPrimaryContainer,
              size: compact ? 20.0 : 22.0,
            ),
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n!.queue,
                  style: compact
                      ? TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        )
                      : textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                ),
                if (_queue.isNotEmpty)
                  Text(
                    '${_queue.length} ${context.l10n!.songs.toLowerCase()}',
                    style: compact
                        ? TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          )
                        : textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
              ],
            ),
          ),
          if (_queue.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: () => _confirmClearQueue(context),
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
    );
  }

  Widget _buildBottomSheetContent(
    BuildContext context,
    ColorScheme colorScheme,
    int currentIndex,
  ) {
    if (_queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          context.l10n!.noSongsInQueue,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        ),
      );
    }
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.52,
      child: _buildList(context, colorScheme, currentIndex, closeOnTap: true),
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

  String _queueEntryKey(Map song, int index) {
    return song['queueEntryId']?.toString() ?? 'legacy_${song['ytid']}_$index';
  }

  Widget _buildList(
    BuildContext context,
    ColorScheme colorScheme,
    int currentIndex, {
    bool closeOnTap = false,
  }) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24, left: 8, right: 8),
      itemCount: _queue.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        setState(() {
          final item = _queue.removeAt(oldIndex);
          _queue.insert(newIndex, item);
        });
        audioHandler.reorderQueue(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) => Material(
        elevation: 6,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
        child: child,
      ),
      itemBuilder: (context, index) {
        final song = _queue[index];
        final isCurrentSong = index == currentIndex;
        final queueEntryId = _queueEntryKey(song, index);
        return QueueTile(
          key: ValueKey(queueEntryId),
          song: song,
          index: index,
          queueEntryId: queueEntryId,
          isCurrentSong: isCurrentSong,
          colorScheme: colorScheme,
          onTap: () {
            audioHandler.skipToSong(index);
            if (closeOnTap) Navigator.pop(context);
          },
          confirmDismiss: (_) async {
            _isDismissing = true;
            return true;
          },
          onDismissed: () {
            final actualIndex = _queue.indexWhere(
              (item) => item['queueEntryId']?.toString() == queueEntryId,
            );
            if (actualIndex == -1) return;
            setState(() {
              _isDismissing = false;
              _queue.removeAt(actualIndex);
            });
            audioHandler.removeFromQueue(actualIndex);
          },
        );
      },
    );
  }
}

class QueueTile extends StatelessWidget {
  const QueueTile({
    super.key,
    required this.song,
    required this.index,
    required this.queueEntryId,
    required this.isCurrentSong,
    required this.colorScheme,
    required this.onTap,
    required this.onDismissed,
    this.confirmDismiss,
  });

  final Map song;
  final int index;
  final String queueEntryId;
  final bool isCurrentSong;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;

  static const double _artSize = 46;
  static const double _artRadius = 10;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(queueEntryId),
      confirmDismiss: confirmDismiss,
      onDismissed: (_) => onDismissed(),
      background: _DismissBackground(
        alignment: Alignment.centerLeft,
        colorScheme: colorScheme,
      ),
      secondaryBackground: _DismissBackground(
        alignment: Alignment.centerRight,
        colorScheme: colorScheme,
      ),
      child: Material(
        color: isCurrentSong
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.transparent,
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _ArtworkThumbnail(
                  song: song,
                  size: _artSize,
                  radius: _artRadius,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title']?.toString() ?? '',
                        style: TextStyle(
                          color: isCurrentSong
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: isCurrentSong
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song['artist']?.toString() ?? '',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrentSong) ...[
                  Icon(
                    FluentIcons.music_note_2_24_filled,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                ],
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  const _ArtworkThumbnail({
    required this.song,
    required this.size,
    required this.radius,
    required this.colorScheme,
  });

  final Map song;
  final double size;
  final double radius;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final artworkPath = song['artworkPath'] as String?;
    if (artworkPath != null && artworkPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(artworkPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    final imageUrl = song['lowResImage']?.toString() ?? '';
    if (imageUrl.isEmpty) return _fallback();
    return CachedNetworkImage(
      width: size,
      height: size,
      imageUrl: imageUrl,
      imageBuilder: (_, imageProvider) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image(image: imageProvider, fit: BoxFit.cover),
      ),
      placeholder: (_, __) => _loading(),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => NullArtworkWidget(
    size: size,
    borderRadius: radius,
    iconSize: size * 0.45,
  );

  Widget _loading() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({
    required this.alignment,
    required this.colorScheme,
  });

  final Alignment alignment;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        FluentIcons.delete_24_filled,
        color: colorScheme.onErrorContainer,
        size: 22,
      ),
    );
  }
}
