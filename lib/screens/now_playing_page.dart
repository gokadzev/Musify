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

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playback_icon_button.dart';
import 'package:musify/widgets/position_slider.dart';
import 'package:musify/widgets/queue_list_view.dart';
import 'package:musify/widgets/song_artwork.dart';
import 'package:musify/widgets/song_bar.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final _lyricsController = FlipCardController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLargeScreen = size.width > 800;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = size.width;
    final baseIconSize = screenWidth < 360
        ? 36.0
        : screenWidth < 400
        ? 40.0
        : 44.0;
    final miniIconSize = screenWidth < 360 ? 18.0 : 22.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            if (snapshot.data == null || !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final metadata = snapshot.data!;
            return Column(
              children: [
                _buildAppBar(context, colorScheme),
                Expanded(
                  child: isLargeScreen
                      ? _DesktopLayout(
                          metadata: metadata,
                          size: size,
                          adjustedIconSize: baseIconSize,
                          adjustedMiniIconSize: miniIconSize,
                          lyricsController: _lyricsController,
                        )
                      : _MobileLayout(
                          metadata: metadata,
                          size: size,
                          adjustedIconSize: baseIconSize,
                          adjustedMiniIconSize: miniIconSize,
                          isLargeScreen: isLargeScreen,
                          lyricsController: _lyricsController,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.onSurface,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.metadata,
    required this.size,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.lyricsController,
  });
  final MediaItem metadata;
  final Size size;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: NowPlayingArtwork(
                      size: size,
                      metadata: metadata,
                      lyricsController: lyricsController,
                    ),
                  ),
                ),
                if (!(metadata.extras?['isLive'] ?? false))
                  Expanded(
                    flex: 2,
                    child: NowPlayingControls(
                      size: size,
                      audioId: metadata.extras?['ytid'],
                      adjustedIconSize: adjustedIconSize,
                      adjustedMiniIconSize: adjustedMiniIconSize,
                      metadata: metadata,
                    ),
                  ),
                BottomActionsRow(
                  audioId: metadata.extras?['ytid'],
                  metadata: metadata,
                  iconSize: adjustedMiniIconSize,
                  isLargeScreen: true,
                  lyricsController: lyricsController,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.outlineVariant.withValues(alpha: 0),
                colorScheme.outlineVariant,
                colorScheme.outlineVariant,
                colorScheme.outlineVariant.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        const Expanded(child: QueueListView()),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.metadata,
    required this.size,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.isLargeScreen,
    required this.lyricsController,
  });
  final MediaItem metadata;
  final Size size;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final bool isLargeScreen;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      return _buildLandscapeLayout(context);
    }
    return _buildPortraitLayout(context);
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            flex: 5,
            child: Center(
              child: NowPlayingArtwork(
                size: size,
                metadata: metadata,
                lyricsController: lyricsController,
              ),
            ),
          ),
          if (!(metadata.extras?['isLive'] ?? false))
            Expanded(
              flex: 4,
              child: NowPlayingControls(
                size: size,
                audioId: metadata.extras?['ytid'],
                adjustedIconSize: adjustedIconSize,
                adjustedMiniIconSize: adjustedMiniIconSize,
                metadata: metadata,
              ),
            ),
          BottomActionsRow(
            audioId: metadata.extras?['ytid'],
            metadata: metadata,
            iconSize: adjustedMiniIconSize,
            isLargeScreen: isLargeScreen,
            lyricsController: lyricsController,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: NowPlayingArtwork(
                size: size,
                metadata: metadata,
                lyricsController: lyricsController,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!(metadata.extras?['isLive'] ?? false))
                  Expanded(
                    child: NowPlayingControls(
                      size: size,
                      audioId: metadata.extras?['ytid'],
                      adjustedIconSize: adjustedIconSize,
                      adjustedMiniIconSize: adjustedMiniIconSize,
                      metadata: metadata,
                    ),
                  ),
                BottomActionsRow(
                  audioId: metadata.extras?['ytid'],
                  metadata: metadata,
                  iconSize: adjustedMiniIconSize,
                  isLargeScreen: isLargeScreen,
                  lyricsController: lyricsController,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NowPlayingArtwork extends StatelessWidget {
  const NowPlayingArtwork({
    super.key,
    required this.size,
    required this.metadata,
    required this.lyricsController,
  });
  final Size size;
  final MediaItem metadata;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isLandscape = screenWidth > screenHeight;
    final imageSize = isLandscape
        ? screenHeight * 0.50
        : screenWidth < 360
        ? screenWidth * 0.75
        : screenWidth < 600
        ? screenWidth * 0.80
        : screenWidth * 0.65;

    const borderRadius = 24.0;

    return FlipCard(
      rotateSide: RotateSide.right,
      onTapFlipping: !offlineMode.value,
      controller: lyricsController,
      frontWidget: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SongArtworkWidget(
            metadata: metadata,
            size: imageSize,
            errorWidgetIconSize: size.width / 8,
            borderRadius: borderRadius,
          ),
        ),
      ),
      backWidget: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: FutureBuilder<String?>(
          future: getSongLyrics(metadata.artist, metadata.title),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: colorScheme.onSecondaryContainer,
                  strokeWidth: 3,
                ),
              );
            } else if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.text_quote_24_regular,
                      size: 48,
                      color: colorScheme.onSecondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n!.lyricsNotAvailable,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            } else {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Text(
                  snapshot.data ?? context.l10n!.lyricsNotAvailable,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSecondaryContainer,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class MarqueeTextWidget extends StatelessWidget {
  const MarqueeTextWidget({
    super.key,
    required this.text,
    required this.fontColor,
    required this.fontSize,
    required this.fontWeight,
  });
  final String text;
  final Color fontColor;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return MarqueeWidget(
      backDuration: const Duration(seconds: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: fontColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class NowPlayingControls extends StatelessWidget {
  const NowPlayingControls({
    super.key,
    required this.size,
    required this.audioId,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.metadata,
  });
  final Size size;
  final dynamic audioId;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isLandscape = screenWidth > screenHeight;
    final titleFontSize = screenWidth < 360
        ? 20.0
        : screenWidth < 400
        ? 22.0
        : isLandscape
        ? screenHeight * 0.035
        : screenHeight * 0.028;

    final artistFontSize = screenWidth < 360
        ? 14.0
        : screenWidth < 400
        ? 15.0
        : isLandscape
        ? screenHeight * 0.022
        : screenHeight * 0.018;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: screenWidth * 0.88,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MarqueeTextWidget(
                text: metadata.title,
                fontColor: colorScheme.onSurface,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              if (metadata.artist != null)
                MarqueeTextWidget(
                  text: metadata.artist!,
                  fontColor: colorScheme.onSurfaceVariant,
                  fontSize: artistFontSize,
                  fontWeight: FontWeight.w500,
                ),
            ],
          ),
        ),
        const Spacer(),
        const PositionSlider(),
        const SizedBox(height: 8),
        PlayerControlButtons(
          metadata: metadata,
          iconSize: adjustedIconSize,
          miniIconSize: adjustedMiniIconSize,
        ),
        const Spacer(),
      ],
    );
  }
}

class PlayerControlButtons extends StatelessWidget {
  const PlayerControlButtons({
    super.key,
    required this.metadata,
    required this.iconSize,
    required this.miniIconSize,
  });
  final MediaItem metadata;
  final double iconSize;
  final double miniIconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final responsiveIconSize = screenWidth < 360 ? iconSize * 0.85 : iconSize;
    final responsiveMiniIconSize = screenWidth < 360
        ? miniIconSize * 0.85
        : miniIconSize;
    final buttonSpacing = screenWidth < 360 ? 8.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildShuffleButton(colorScheme, responsiveMiniIconSize),
          StreamBuilder<List<MediaItem>>(
            stream: audioHandler.queue,
            builder: (context, snapshot) {
              return ValueListenableBuilder<AudioServiceRepeatMode>(
                valueListenable: repeatNotifier,
                builder: (_, repeatMode, __) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          FluentIcons.previous_24_filled,
                          color: audioHandler.hasPrevious
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        iconSize: responsiveIconSize * 0.6,
                        onPressed: audioHandler.hasPrevious
                            ? () => audioHandler.skipToPrevious()
                            : null,
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      SizedBox(width: buttonSpacing),
                      PlaybackIconButton(
                        iconColor: colorScheme.onPrimary,
                        backgroundColor: colorScheme.primary,
                        iconSize: responsiveIconSize * 0.85,
                        padding: EdgeInsets.all(responsiveIconSize * 0.45),
                      ),
                      SizedBox(width: buttonSpacing),
                      IconButton(
                        icon: Icon(
                          FluentIcons.next_24_filled,
                          color: audioHandler.hasNext
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        iconSize: responsiveIconSize * 0.6,
                        onPressed: () =>
                            repeatNotifier.value == AudioServiceRepeatMode.one
                            ? audioHandler.playAgain()
                            : audioHandler.skipToNext(),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          _buildRepeatButton(colorScheme, responsiveMiniIconSize),
        ],
      ),
    );
  }

  Widget _buildShuffleButton(ColorScheme colorScheme, double size) {
    return ValueListenableBuilder<bool>(
      valueListenable: shuffleNotifier,
      builder: (_, value, __) {
        return IconButton(
          icon: Icon(
            value
                ? FluentIcons.arrow_shuffle_24_filled
                : FluentIcons.arrow_shuffle_off_24_filled,
            color: value ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
          iconSize: size,
          style: IconButton.styleFrom(
            backgroundColor: value
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            audioHandler.setShuffleMode(
              value
                  ? AudioServiceShuffleMode.none
                  : AudioServiceShuffleMode.all,
            );
          },
        );
      },
    );
  }

  Widget _buildRepeatButton(ColorScheme colorScheme, double size) {
    return StreamBuilder<List<MediaItem>>(
      stream: audioHandler.queue,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];
        return ValueListenableBuilder<AudioServiceRepeatMode>(
          valueListenable: repeatNotifier,
          builder: (_, repeatMode, __) {
            final isActive = repeatMode != AudioServiceRepeatMode.none;

            return IconButton(
              icon: Icon(
                repeatMode == AudioServiceRepeatMode.one
                    ? FluentIcons.arrow_repeat_1_24_filled
                    : isActive
                    ? FluentIcons.arrow_repeat_all_24_filled
                    : FluentIcons.arrow_repeat_all_off_24_filled,
                color: isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              iconSize: size,
              style: IconButton.styleFrom(
                backgroundColor: isActive
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final AudioServiceRepeatMode newMode;
                if (repeatMode == AudioServiceRepeatMode.none) {
                  newMode = queue.length <= 1
                      ? AudioServiceRepeatMode.one
                      : AudioServiceRepeatMode.all;
                } else if (repeatMode == AudioServiceRepeatMode.all) {
                  newMode = AudioServiceRepeatMode.one;
                } else {
                  newMode = AudioServiceRepeatMode.none;
                }
                repeatNotifier.value = newMode;
                audioHandler.setRepeatMode(newMode);
              },
            );
          },
        );
      },
    );
  }
}

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
  final FlipCardController lyricsController;

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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: 8,
            children: [
              _buildActionButton(
                context: context,
                icon: FluentIcons.cellular_data_1_24_regular,
                activeIcon: FluentIcons.cellular_off_24_regular,
                colorScheme: colorScheme,
                size: responsiveIconSize,
                statusNotifier: songOfflineStatus,
                onPressed: audioId == null
                    ? null
                    : () => _toggleOffline(songOfflineStatus),
                tooltip: 'Offline',
              ),
              if (!offlineMode.value)
                _buildSimpleActionButton(
                  context: context,
                  icon: FluentIcons.add_24_regular,
                  colorScheme: colorScheme,
                  size: responsiveIconSize,
                  onPressed: () => showAddToPlaylistDialog(
                    context,
                    mediaItemToMap(metadata),
                  ),
                  tooltip: 'Add to playlist',
                ),
              if (queue.isNotEmpty && !isLargeScreen)
                _buildSimpleActionButton(
                  context: context,
                  icon: FluentIcons.apps_list_24_filled,
                  colorScheme: colorScheme,
                  size: responsiveIconSize,
                  onPressed: () => _showQueue(context, mappedQueue),
                  tooltip: 'Queue',
                ),
              if (!offlineMode.value) ...[
                _buildSimpleActionButton(
                  context: context,
                  icon: FluentIcons.text_quote_24_regular,
                  colorScheme: colorScheme,
                  size: responsiveIconSize,
                  onPressed: lyricsController.flipcard,
                  tooltip: 'Lyrics',
                ),
                _buildSleepTimerButton(
                  context,
                  colorScheme,
                  responsiveIconSize,
                ),
                _buildActionButton(
                  context: context,
                  icon: FluentIcons.heart_24_regular,
                  activeIcon: FluentIcons.heart_24_filled,
                  colorScheme: colorScheme,
                  size: responsiveIconSize,
                  statusNotifier: songLikeStatus,
                  activeColor: colorScheme.error,
                  onPressed: () {
                    updateSongLikeStatus(audioId, !songLikeStatus.value);
                    songLikeStatus.value = !songLikeStatus.value;
                  },
                  tooltip: 'Like',
                ),
              ],
            ],
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

  Future<void> _toggleOffline(ValueNotifier<bool> status) async {
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
    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottmomPadding,
        itemCount: mappedQueue.length,
        itemBuilder: (BuildContext context, int index) {
          final borderRadius = getItemBorderRadius(index, mappedQueue.length);
          return SongBar(
            mappedQueue[index],
            false,
            onPlay: () => audioHandler.skipToSong(index),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: borderRadius,
          );
        },
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
                  Icon(
                    FluentIcons.timer_24_regular,
                    color: colorScheme.primary,
                  ),
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
}
