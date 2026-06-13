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

import 'dart:io';
import 'dart:ui' as ui;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:musify/constants/app_constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/user_songs_page.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/app_utils.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/listening_stats_utils.dart';
import 'package:musify/widgets/listening_recap_card.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TimeMachinePage extends StatefulWidget {
  const TimeMachinePage({super.key});

  @override
  State<TimeMachinePage> createState() => _TimeMachinePageState();
}

enum _TimeMachineSectionKind { annual, month, bottomSpace }

class _TimeMachineSection {
  const _TimeMachineSection.annual()
    : kind = _TimeMachineSectionKind.annual,
      monthKey = null;

  const _TimeMachineSection.month(this.monthKey)
    : kind = _TimeMachineSectionKind.month;

  const _TimeMachineSection.bottomSpace()
    : kind = _TimeMachineSectionKind.bottomSpace,
      monthKey = null;

  final _TimeMachineSectionKind kind;
  final String? monthKey;
}

class _TimeMachinePageState extends State<TimeMachinePage> {
  final Map<String, GlobalKey> _monthShareKeys = {};
  final GlobalKey _yearShareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: offlineMode,
      builder: (context, isOffline, _) {
        if (isOffline) return const UserSongsPage(page: 'offline');

        return ValueListenableBuilder<bool>(
          valueListenable: wrappedEnabled,
          builder: (context, isEnabled, _) {
            if (!isEnabled || !listeningStatsService.hasStats) {
              return _buildEmptyState(context);
            }

            return _buildTimeMachine(context);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.timeMachine)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.clock_24_regular,
              size: 42,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n!.noListeningStats,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeMachine(BuildContext context) {
    final now = DateTime.now();
    final monthKeys = listeningStatsService.availableMonthKeys;
    final showAnnualRecap = listeningStatsService.isAnnualRecapAvailable;
    final sections = _timeMachineSections(
      now: now,
      monthKeys: monthKeys,
      showAnnualRecap: showAnnualRecap,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.timeMachine)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
        scrollCacheExtent: const ScrollCacheExtent.pixels(500),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return switch (section.kind) {
            _TimeMachineSectionKind.annual => KeyedSubtree(
              key: const ValueKey('annual-recap'),
              child: _buildAnnualSection(context),
            ),
            _TimeMachineSectionKind.month => KeyedSubtree(
              key: ValueKey('month-${section.monthKey}'),
              child: _buildMonthSection(context, section.monthKey!),
            ),
            _TimeMachineSectionKind.bottomSpace =>
              const MiniPlayerBottomSpace(),
          };
        },
      ),
    );
  }

  List<_TimeMachineSection> _timeMachineSections({
    required DateTime now,
    required List<String> monthKeys,
    required bool showAnnualRecap,
  }) {
    final sections = <_TimeMachineSection>[];
    final currentMonthKey = listeningStatsMonthKey(now);
    final showAnnualBeforeMonths =
        showAnnualRecap && now.month != DateTime.january;

    if (showAnnualBeforeMonths) {
      sections.add(const _TimeMachineSection.annual());
    }

    for (final monthKey in monthKeys) {
      if (monthKey == currentMonthKey) {
        sections.add(_TimeMachineSection.month(monthKey));
      }
    }

    if (showAnnualRecap && !showAnnualBeforeMonths) {
      sections.add(const _TimeMachineSection.annual());
    }

    for (final monthKey in monthKeys) {
      if (monthKey != currentMonthKey) {
        sections.add(_TimeMachineSection.month(monthKey));
      }
    }

    sections.add(const _TimeMachineSection.bottomSpace());
    return sections;
  }

  Widget _buildMonthSection(BuildContext context, String monthKey) {
    final monthStats = listeningStatsService.monthStats(monthKey);
    if (!hasDisplayableListeningStats(monthStats)) {
      return const SizedBox.shrink();
    }

    final songs = listeningStatsService.monthTopSongs(
      monthKey,
      limit: wrappedExpandedSongsLimit,
    );
    final previewSongs = songs.take(wrappedShareSongsLimit).toList();
    final shareKey = _monthShareKeys.putIfAbsent(monthKey, GlobalKey.new);
    final monthTitle = _formatMonthTitle(context, monthKey);
    final periodLabel = _formatMonthPeriodLabel(context, monthKey);

    return _PeriodSection(
      title: monthTitle,
      onShare: () => _shareRecap(
        context,
        key: shareKey,
        fileName: 'musify-$monthKey-recap.png',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            key: shareKey,
            child: ListeningRecapCard(
              periodLabel: periodLabel,
              minutes: monthDisplayMinutes(monthStats),
              songs: previewSongs,
              onSongTap: (index) => _playSongs(songs, index),
              onSongLongPress: (index, position) =>
                  _showSongMenu(previewSongs, index, position),
            ),
          ),
          if (songs.length > previewSongs.length)
            _ViewMoreButton(
              onPressed: () => _showMoreSongs(context, monthTitle, songs),
            ),
        ],
      ),
    );
  }

  Widget _buildAnnualSection(BuildContext context) {
    final songs = listeningStatsService.yearTopSongs();
    final previewSongs = songs.take(wrappedShareSongsLimit).toList();
    final year = listeningStatsService.year.toString();
    final totalSeconds = listeningStatsService.yearTotalSeconds;

    return _PeriodSection(
      title: '${context.l10n!.annualRecap} $year',
      onShare: () => _shareRecap(
        context,
        key: _yearShareKey,
        fileName: 'musify-$year-recap.png',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            key: _yearShareKey,
            child: ListeningRecapCard(
              periodLabel: year,
              minutes: listeningStatsDisplayMinutes(
                totalSeconds,
                hasQualifiedSongs: songs.isNotEmpty,
              ),
              songs: previewSongs,
              onSongTap: (index) => _playSongs(songs, index),
              onSongLongPress: (index, position) =>
                  _showSongMenu(previewSongs, index, position),
              featureFirstSong: true,
              highlightMinutes: true,
              outlined: true,
            ),
          ),
          if (songs.length > previewSongs.length)
            _ViewMoreButton(
              onPressed: () => _showMoreSongs(
                context,
                '${context.l10n!.annualRecap} $year',
                songs,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _shareRecap(
    BuildContext context, {
    required GlobalKey key,
    required String fileName,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      await WidgetsBinding.instance.endOfFrame;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return;

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      final result = await SharePlus.instance.share(
        ShareParams(
          title: context.l10n!.shareTimeMachineText,
          subject: context.l10n!.shareTimeMachineText,
          text: context.l10n!.shareTimeMachineText,
          files: [XFile(file.path, mimeType: 'image/png')],
          fileNameOverrides: [fileName],
        ),
      );

      if (result.status == ShareResultStatus.unavailable && context.mounted) {
        showToast(context, context.l10n!.error);
      }
    } catch (e, stackTrace) {
      logger.log(
        'Error sharing Time Machine recap',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) showToast(context, context.l10n!.error);
    }
  }

  void _showMoreSongs(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> songs, {
    int limit = wrappedExpandedSongsLimit,
  }) {
    final visibleSongs = songs.take(limit).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          builder: (context, scrollController) => SafeArea(
            child: ListView.builder(
              controller: scrollController,
              padding: commonListViewBottomPadding,
              itemCount: visibleSongs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }

                final songIndex = index - 1;
                final song = visibleSongs[songIndex];
                return SongBar(
                  song,
                  true,
                  borderRadius: getItemBorderRadius(
                    songIndex,
                    visibleSongs.length,
                  ),
                  showPlayTime: true,
                  rank: songIndex + 1,
                  onPlay: () {
                    Navigator.pop(context);
                    _playSongs(visibleSongs, songIndex);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSongMenu(
    List<Map<String, dynamic>> songs,
    int index,
    Offset position,
  ) {
    if (index < 0 || index >= songs.length) return;
    showSongBarMenu(context, songs[index], globalPosition: position);
  }

  Future<void> _playSongs(List<Map<String, dynamic>> songs, int index) async {
    if (songs.isEmpty) return;
    await audioHandler.playPlaylistSong(
      playlist: {'title': context.l10n!.timeMachine, 'list': songs},
      songIndex: index,
    );
  }

  String _formatMonthTitle(BuildContext context, String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return monthKey;

    final locale = Localizations.localeOf(context).toString();
    final monthName = DateFormat.MMMM(locale).format(DateTime(year, month));
    return monthName.isEmpty
        ? monthKey
        : '${monthName[0].toUpperCase()}${monthName.substring(1)}';
  }

  String _formatMonthPeriodLabel(BuildContext context, String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return monthKey;

    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat.yMMMM(locale).format(DateTime(year, month));
    return label.isEmpty
        ? monthKey
        : '${label[0].toUpperCase()}${label.substring(1)}';
  }
}

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({
    required this.title,
    required this.child,
    required this.onShare,
  });

  final String title;
  final Widget child;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n!.shareRecap,
                  onPressed: onShare,
                  icon: const Icon(FluentIcons.share_24_regular),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ViewMoreButton extends StatelessWidget {
  const _ViewMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(FluentIcons.more_horizontal_24_regular),
          label: Text(context.l10n!.tapToView),
        ),
      ),
    );
  }
}
