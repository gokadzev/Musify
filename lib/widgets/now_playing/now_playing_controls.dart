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
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/now_playing/marquee_text_widget.dart';
import 'package:musify/widgets/playback_icon_button.dart';
import 'package:musify/widgets/position_slider.dart';

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
    final isDesktop = size.width > 800;

    final titleFontSize = getResponsiveTitleFontSize(size);
    final artistFontSize = getResponsiveArtistFontSize(size);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isCompact = availableHeight < 280;
        final isVeryCompact = availableHeight < 200;

        final spacing = isVeryCompact
            ? 2.0
            : isCompact
            ? 4.0
            : 8.0;
        final iconScale = isVeryCompact
            ? 0.65
            : isCompact
            ? 0.75
            : 1.0;
        final fontScale = isCompact ? 0.9 : 1.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompact) const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 24,
                vertical: spacing,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MarqueeTextWidget(
                    text: metadata.title,
                    fontColor: colorScheme.secondary,
                    fontSize: titleFontSize * fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: spacing),
                  if (metadata.artist != null)
                    MarqueeTextWidget(
                      text: metadata.artist!,
                      fontColor: colorScheme.onSurfaceVariant,
                      fontSize: artistFontSize * fontScale,
                      fontWeight: FontWeight.w500,
                    ),
                ],
              ),
            ),
            if (!isCompact) const Spacer(),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 400 : constraints.maxWidth,
              ),
              child: const PositionSlider(),
            ),
            SizedBox(height: spacing),
            PlayerControlButtons(
              metadata: metadata,
              iconSize: adjustedIconSize * iconScale,
              miniIconSize: adjustedMiniIconSize * iconScale,
            ),
            if (!isCompact) const Spacer(),
          ],
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isTight = maxWidth < 360;
        final isUltraTight = maxWidth < 320;

        final horizontalPadding = isUltraTight
            ? 10.0
            : isTight
            ? 14.0
            : 20.0;
        final buttonSpacing = isUltraTight
            ? 6.0
            : isTight
            ? 10.0
            : screenWidth < 360
            ? 8.0
            : 16.0;
        final minButtonSize = isUltraTight
            ? 38.0
            : isTight
            ? 42.0
            : 46.0;
        final buttonPadding = EdgeInsets.all(
          isUltraTight
              ? 6.0
              : isTight
              ? 8.0
              : 10.0,
        );

        final buttonConstraints = BoxConstraints(
          minWidth: minButtonSize,
          minHeight: minButtonSize,
        );

        final controlIconSize =
            responsiveIconSize *
            (isUltraTight
                ? 0.75
                : isTight
                ? 0.85
                : 0.92);
        final miniControlSize =
            responsiveMiniIconSize *
            (isUltraTight
                ? 0.8
                : isTight
                ? 0.9
                : 1.0);
        final playPadding = EdgeInsets.all(
          responsiveIconSize *
              (isUltraTight
                  ? 0.30
                  : isTight
                  ? 0.36
                  : 0.45),
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: <Widget>[
              _buildShuffleButton(
                colorScheme,
                miniControlSize,
                buttonConstraints,
                buttonPadding,
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: Center(
                  child: StreamBuilder<List<MediaItem>>(
                    stream: audioHandler.queue,
                    builder: (context, snapshot) {
                      return ValueListenableBuilder<AudioServiceRepeatMode>(
                        valueListenable: repeatNotifier,
                        builder: (_, repeatMode, __) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    FluentIcons.previous_24_filled,
                                    color: audioHandler.hasPrevious
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                  constraints: buttonConstraints,
                                  iconSize: controlIconSize * 0.65,
                                  onPressed: audioHandler.hasPrevious
                                      ? () => audioHandler.skipToPrevious()
                                      : null,
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    disabledBackgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: buttonPadding,
                                    minimumSize: Size(
                                      minButtonSize,
                                      minButtonSize,
                                    ),
                                  ),
                                ),
                                SizedBox(width: buttonSpacing),
                                PlaybackIconButton(
                                  iconColor: colorScheme.onPrimary,
                                  backgroundColor: colorScheme.primary,
                                  iconSize: controlIconSize,
                                  padding: playPadding,
                                ),
                                SizedBox(width: buttonSpacing),
                                IconButton(
                                  icon: Icon(
                                    FluentIcons.next_24_filled,
                                    color: audioHandler.hasNext
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                  constraints: buttonConstraints,
                                  iconSize: controlIconSize * 0.65,
                                  onPressed: () =>
                                      repeatNotifier.value ==
                                          AudioServiceRepeatMode.one
                                      ? audioHandler.playAgain()
                                      : audioHandler.skipToNext(),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    disabledBackgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: buttonPadding,
                                    minimumSize: Size(
                                      minButtonSize,
                                      minButtonSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: buttonSpacing),
              _buildRepeatButton(
                colorScheme,
                miniControlSize,
                buttonConstraints,
                buttonPadding,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShuffleButton(
    ColorScheme colorScheme,
    double size,
    BoxConstraints buttonConstraints,
    EdgeInsets buttonPadding,
  ) {
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
          constraints: buttonConstraints,
          padding: buttonPadding,
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

  Widget _buildRepeatButton(
    ColorScheme colorScheme,
    double size,
    BoxConstraints buttonConstraints,
    EdgeInsets buttonPadding,
  ) {
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
              constraints: buttonConstraints,
              padding: buttonPadding,
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
