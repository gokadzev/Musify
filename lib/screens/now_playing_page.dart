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
import 'package:musify/models/position_data.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/utilities/utils.dart';
import 'package:musify/widgets/custom_slider.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playback_icon_button.dart';
import 'package:musify/widgets/song_artwork.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

final _lyricsController = FlipCardController();

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLargeScreen = size.width > 800;
    const adjustedIconSize = 43.0;
    const adjustedMiniIconSize = 20.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_downward),
          splashColor: Colors.transparent,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          if (snapshot.data == null || !snapshot.hasData) {
            return const SizedBox.shrink();
          } else {
            final metadata = snapshot.data!;

            return isLargeScreen
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            buildArtwork(context, size, metadata),
                            const SizedBox(height: 5),
                            if (!(metadata.extras?['isLive'] ?? false))
                              _buildPlayer(
                                context,
                                size,
                                metadata.extras?['ytid'],
                                adjustedIconSize,
                                adjustedMiniIconSize,
                                metadata,
                              ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: buildQueueList(context),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: 10),
                      buildArtwork(context, size, metadata),
                      const SizedBox(height: 10),
                      if (!(metadata.extras?['isLive'] ?? false))
                        _buildPlayer(
                          context,
                          size,
                          metadata.extras?['ytid'],
                          adjustedIconSize,
                          adjustedMiniIconSize,
                          metadata,
                        ),
                      const SizedBox(height: 10),
                      buildBottomActions(
                        context,
                        metadata.extras?['ytid'],
                        metadata,
                        adjustedMiniIconSize,
                        isLargeScreen,
                      ),
                      const SizedBox(height: 35),
                    ],
                  );
          }
        },
      ),
    );
  }

  Widget buildQueueList(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            context.l10n!.playlist,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: activePlaylist['list'].length,
            itemBuilder: (context, index) {
              final borderRadius = getItemBorderRadius(
                index,
                activePlaylist['list'].length,
              );
              return SongBar(
                activePlaylist['list'][index],
                false,
                onPlay: () => {
                  audioHandler.playPlaylistSong(songIndex: index),
                },
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: borderRadius,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildArtwork(BuildContext context, Size size, MediaItem metadata) {
    const _padding = 50;
    const _radius = 17.0;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isLandscape = screenWidth > screenHeight;
    final imageSize = isLandscape
        ? screenHeight * 0.40
        : (screenWidth + screenHeight) / 3.35 - _padding;
    const lyricsTextStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
    );

    return FlipCard(
      rotateSide: RotateSide.right,
      onTapFlipping: !offlineMode.value,
      controller: _lyricsController,
      frontWidget: SongArtworkWidget(
        metadata: metadata,
        size: imageSize,
        errorWidgetIconSize: size.width / 8,
        borderRadius: _radius,
      ),
      backWidget: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: FutureBuilder<String?>(
          future: getSongLyrics(metadata.artist ?? '', metadata.title),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Spinner();
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  context.l10n!.lyricsNotAvailable,
                  style: lyricsTextStyle.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            } else if (snapshot.hasData && snapshot.data != 'not found') {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    snapshot.data!,
                    style: lyricsTextStyle.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else {
              return Center(
                child: Text(
                  context.l10n!.lyricsNotAvailable,
                  style: lyricsTextStyle.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
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

  Widget buildMarqueeText(
    String text,
    Color fontColor,
    double fontSize,
    FontWeight fontWeight,
  ) {
    return MarqueeWidget(
      backDuration: const Duration(seconds: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: fontColor,
        ),
      ),
    );
  }

  Widget _buildPlayer(
    BuildContext context,
    Size size,
    dynamic audioId,
    double adjustedIconSize,
    double adjustedMiniIconSize,
    MediaItem mediaItem,
  ) {
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          SizedBox(
            width: screenWidth * 0.85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildMarqueeText(
                  mediaItem.title,
                  Theme.of(context).colorScheme.primary,
                  screenHeight * 0.028,
                  FontWeight.w600,
                ),
                const SizedBox(height: 10),
                if (mediaItem.artist != null)
                  buildMarqueeText(
                    mediaItem.artist!,
                    Theme.of(context).colorScheme.secondary,
                    screenHeight * 0.017,
                    FontWeight.w500,
                  ),
              ],
            ),
          ),
          const Spacer(),
          buildPositionSlider(),
          const Spacer(),
          buildPlayerControls(
            context,
            mediaItem,
            adjustedIconSize,
            adjustedMiniIconSize,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget buildPositionSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: StreamBuilder<PositionData>(
        stream: audioHandler.positionDataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }
          final positionData = snapshot.data!;
          final primaryColor = Theme.of(context).colorScheme.primary;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildSlider(
                positionData,
              ),
              buildPositionRow(
                primaryColor,
                positionData,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildSlider(
    PositionData positionData,
  ) {
    return CustomSlider(
      isSquiglySliderEnabled: useSquigglySlider.value,
      value: positionData.position.inSeconds.toDouble(),
      onChanged: (value) {
        audioHandler.seek(Duration(seconds: value.toInt()));
      },
      max: positionData.duration.inSeconds.toDouble(),
      squiggleAmplitude: 3,
      squiggleWavelength: 5,
      squiggleSpeed: 0.1,
    );
  }

  Widget buildPositionRow(Color fontColor, PositionData positionData) {
    final positionText = formatDuration(positionData.position.inSeconds);
    final durationText = formatDuration(positionData.duration.inSeconds);
    final textStyle = TextStyle(fontSize: 15, color: fontColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(positionText, style: textStyle),
          Text(durationText, style: textStyle),
        ],
      ),
    );
  }

  Widget buildPlayerControls(
    BuildContext context,
    MediaItem mediaItem,
    double playButtonIconSize,
    double miniIconsSize,
  ) {
    final theme = Theme.of(context);
    final _primaryColor = theme.colorScheme.primary;
    final _secondaryColor = theme.colorScheme.secondaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: shuffleNotifier,
            builder: (_, value, __) {
              return value
                  ? IconButton.filled(
                      icon: Icon(
                        FluentIcons.arrow_shuffle_24_filled,
                        color: _secondaryColor,
                      ),
                      iconSize: miniIconsSize,
                      onPressed: () {
                        audioHandler.setShuffleMode(
                          AudioServiceShuffleMode.none,
                        );
                      },
                    )
                  : IconButton.filledTonal(
                      icon: Icon(
                        FluentIcons.arrow_shuffle_off_24_filled,
                        color: _primaryColor,
                      ),
                      iconSize: miniIconsSize,
                      onPressed: () {
                        audioHandler.setShuffleMode(
                          AudioServiceShuffleMode.all,
                        );
                      },
                    );
            },
          ),
          Row(
            children: [
              ValueListenableBuilder<AudioServiceRepeatMode>(
                valueListenable: repeatNotifier,
                builder: (_, repeatMode, __) {
                  return IconButton(
                    icon: Icon(
                      FluentIcons.previous_24_filled,
                      color: audioHandler.hasPrevious
                          ? _primaryColor
                          : _secondaryColor,
                    ),
                    iconSize: playButtonIconSize / 1.7,
                    onPressed: () =>
                        repeatNotifier.value == AudioServiceRepeatMode.one
                            ? audioHandler.playAgain()
                            : audioHandler.skipToPrevious(),
                    splashColor: Colors.transparent,
                  );
                },
              ),
              const SizedBox(width: 10),
              StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  return buildPlaybackIconButton(
                    snapshot.data,
                    playButtonIconSize,
                    _primaryColor,
                    _secondaryColor,
                    elevation: 0,
                    padding: EdgeInsets.all(playButtonIconSize * 0.40),
                  );
                },
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<AudioServiceRepeatMode>(
                valueListenable: repeatNotifier,
                builder: (_, repeatMode, __) {
                  return IconButton(
                    icon: Icon(
                      FluentIcons.next_24_filled,
                      color: audioHandler.hasNext
                          ? _primaryColor
                          : _secondaryColor,
                    ),
                    iconSize: playButtonIconSize / 1.7,
                    onPressed: () =>
                        repeatNotifier.value == AudioServiceRepeatMode.one
                            ? audioHandler.playAgain()
                            : audioHandler.skipToNext(),
                    splashColor: Colors.transparent,
                  );
                },
              ),
            ],
          ),
          ValueListenableBuilder<AudioServiceRepeatMode>(
            valueListenable: repeatNotifier,
            builder: (_, repeatMode, __) {
              return repeatMode != AudioServiceRepeatMode.none
                  ? IconButton.filled(
                      icon: Icon(
                        repeatMode == AudioServiceRepeatMode.all
                            ? FluentIcons.arrow_repeat_all_24_filled
                            : FluentIcons.arrow_repeat_1_24_filled,
                        color: _secondaryColor,
                      ),
                      iconSize: miniIconsSize,
                      onPressed: () {
                        repeatNotifier.value =
                            repeatMode == AudioServiceRepeatMode.all
                                ? AudioServiceRepeatMode.one
                                : AudioServiceRepeatMode.none;

                        audioHandler.setRepeatMode(repeatMode);
                      },
                    )
                  : IconButton.filledTonal(
                      icon: Icon(
                        FluentIcons.arrow_repeat_all_off_24_filled,
                        color: _primaryColor,
                      ),
                      iconSize: miniIconsSize,
                      onPressed: () {
                        final _isSingleSongPlaying =
                            activePlaylist['list'].isEmpty;
                        repeatNotifier.value = _isSingleSongPlaying
                            ? AudioServiceRepeatMode.one
                            : AudioServiceRepeatMode.all;

                        if (repeatNotifier.value == AudioServiceRepeatMode.one)
                          audioHandler.setRepeatMode(repeatNotifier.value);
                      },
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget buildBottomActions(
    BuildContext context,
    dynamic audioId,
    MediaItem mediaItem,
    double iconSize,
    bool isLargeScreen,
  ) {
    final songLikeStatus = ValueNotifier<bool>(isSongAlreadyLiked(audioId));
    late final songOfflineStatus =
        ValueNotifier<bool>(isSongAlreadyOffline(audioId));

    final _primaryColor = Theme.of(context).colorScheme.primary;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: songOfflineStatus,
          builder: (_, value, __) {
            return IconButton.filledTonal(
              icon: Icon(
                value
                    ? FluentIcons.cellular_off_24_regular
                    : FluentIcons.cellular_data_1_24_regular,
                color: _primaryColor,
              ),
              iconSize: iconSize,
              onPressed: () {
                if (value) {
                  removeSongFromOffline(audioId);
                } else {
                  makeSongOffline(mediaItemToMap(mediaItem));
                }

                songOfflineStatus.value = !songOfflineStatus.value;
              },
            );
          },
        ),
        if (!offlineMode.value)
          IconButton.filledTonal(
            icon: Icon(
              Icons.add,
              color: _primaryColor,
            ),
            iconSize: iconSize,
            onPressed: () {
              showAddToPlaylistDialog(context, mediaItemToMap(mediaItem));
            },
          ),
        if (activePlaylist['list'].isNotEmpty && !isLargeScreen)
          IconButton.filledTonal(
            icon: Icon(
              FluentIcons.apps_list_24_filled,
              color: _primaryColor,
            ),
            iconSize: iconSize,
            onPressed: () {
              showCustomBottomSheet(
                context,
                ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: commonListViewBottmomPadding,
                  itemCount: activePlaylist['list'].length,
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    final borderRadius = getItemBorderRadius(
                      index,
                      activePlaylist['list'].length,
                    );
                    return SongBar(
                      activePlaylist['list'][index],
                      false,
                      onPlay: () => {
                        audioHandler.playPlaylistSong(songIndex: index),
                      },
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: borderRadius,
                    );
                  },
                ),
              );
            },
          ),
        if (!offlineMode.value)
          IconButton.filledTonal(
            icon: Icon(
              FluentIcons.text_32_filled,
              color: _primaryColor,
            ),
            iconSize: iconSize,
            onPressed: _lyricsController.flipcard,
          ),
        if (!offlineMode.value)
          ValueListenableBuilder<bool>(
            valueListenable: songLikeStatus,
            builder: (_, value, __) {
              return IconButton.filledTonal(
                icon: Icon(
                  value
                      ? FluentIcons.heart_24_filled
                      : FluentIcons.heart_24_regular,
                  color: _primaryColor,
                ),
                iconSize: iconSize,
                onPressed: () {
                  updateSongLikeStatus(audioId, !songLikeStatus.value);
                  songLikeStatus.value = !songLikeStatus.value;
                },
              );
            },
          ),
      ],
    );
  }
}
