/*
 *     Copyright (C) 2024 Valeri Gokadze
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
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playback_icon_button.dart';
import 'package:musify/widgets/song_artwork.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:musify/widgets/squiggly_slider.dart';

final _lyricsController = FlipCardController();

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          if (snapshot.data == null || !snapshot.hasData) {
            return const SizedBox.shrink();
          } else {
            final metadata = snapshot.data!;
            final screenHeight = size.height;
            final screenWidth = size.width;
            return Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildArtwork(context, size, metadata),
                      SizedBox(
                        width: screenWidth * 0.85,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 1),
                            buildMarqueeText(
                              metadata.title,
                              Theme.of(context).colorScheme.primary,
                              screenHeight * 0.028,
                              FontWeight.w600,
                            ),
                            if (metadata.artist != null)
                              buildMarqueeText(
                                metadata.artist!,
                                Theme.of(context).colorScheme.secondary,
                                screenHeight * 0.017,
                                FontWeight.w500,
                              ),
                          ],
                        ),
                      ),
                      if (!(metadata.extras?['isLive'] ?? false))
                        _buildPlayer(
                          context,
                          size,
                          metadata.extras?['ytid'],
                          metadata,
                        ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildArtwork(BuildContext context, Size size, MediaItem metadata) {
    const _padding = 50;
    const _radius = 20.0;
    const _maxSize = 360.0;
    final imageSize = size.width - _padding;

    return FlipCard(
      rotateSide: RotateSide.right,
      onTapFlipping: isOnline,
      controller: _lyricsController,
      frontWidget: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _maxSize,
          maxHeight: _maxSize,
        ),
        child: SongArtworkWidget(
          metadata: metadata,
          size: imageSize,
          errorWidgetIconSize: size.width / 8,
          borderRadius: _radius,
        ),
      ),
      backWidget: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _maxSize,
          maxHeight: _maxSize,
        ),
        child: Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: ValueListenableBuilder<String?>(
            valueListenable: lyrics,
            builder: (_, value, __) {
              if (lastFetchedLyrics !=
                  '${metadata.artist} - ${metadata.title}') {
                getSongLyrics(
                  metadata.artist ?? '',
                  metadata.title,
                );
              }
              if (value != null && value != 'not found') {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Center(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              } else if (value == null) {
                return const Spinner();
              } else {
                return Center(
                  child: Text(
                    context.l10n!.lyricsNotAvailable,
                    style: const TextStyle(
                      fontSize: 25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
            },
          ),
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
    MediaItem mediaItem,
  ) {
    const iconSize = 20.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildPositionSlider(),
        buildPlayerControls(context, size, mediaItem, iconSize),
        SizedBox(height: size.height * 0.04),
        buildBottomActions(context, audioId, mediaItem, iconSize),
      ],
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
    return SquigglySlider(
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
    Size size,
    MediaItem mediaItem,
    double iconSize,
  ) {
    final _primaryColor = Theme.of(context).colorScheme.primary;
    final _secondaryColor = Theme.of(context).colorScheme.secondaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: shuffleNotifier,
            builder: (_, value, __) {
              return IconButton.filled(
                icon: Icon(
                  value
                      ? FluentIcons.arrow_shuffle_24_filled
                      : FluentIcons.arrow_shuffle_off_24_filled,
                  color: _secondaryColor,
                ),
                iconSize: iconSize,
                onPressed: () {
                  audioHandler.setShuffleMode(
                    value
                        ? AudioServiceShuffleMode.none
                        : AudioServiceShuffleMode.all,
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(
              FluentIcons.previous_24_filled,
              color: audioHandler.hasPrevious ? _primaryColor : _secondaryColor,
            ),
            iconSize: size.width * 0.11 > 45 ? size.width * 0.11 : 45,
            onPressed: () => audioHandler.skipToPrevious(),
            splashColor: Colors.transparent,
          ),
          StreamBuilder<PlaybackState>(
            stream: audioHandler.playbackState,
            builder: (context, snapshot) {
              return buildPlaybackIconButton(
                snapshot.data,
                size.width * 0.19 > 20 && size.width < 50 ? size.width : 50,
                _primaryColor,
                _secondaryColor,
                elevation: 0,
              );
            },
          ),
          IconButton(
            icon: Icon(
              FluentIcons.next_24_filled,
              color: audioHandler.hasNext ? _primaryColor : _secondaryColor,
            ),
            iconSize: size.width * 0.11 > 45 ? size.width * 0.11 : 45,
            onPressed: () => audioHandler.skipToNext(),
            splashColor: Colors.transparent,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: repeatNotifier,
            builder: (_, value, __) {
              return IconButton.filled(
                icon: Icon(
                  value
                      ? FluentIcons.arrow_repeat_1_24_filled
                      : FluentIcons.arrow_repeat_all_off_24_filled,
                  color: _secondaryColor,
                ),
                iconSize: iconSize,
                onPressed: () => audioHandler.setRepeatMode(
                  value
                      ? AudioServiceRepeatMode.none
                      : AudioServiceRepeatMode.all,
                ),
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
        ValueListenableBuilder<bool>(
          valueListenable: muteNotifier,
          builder: (_, value, __) {
            return IconButton.filledTonal(
              icon: Icon(
                value
                    ? FluentIcons.speaker_mute_24_filled
                    : FluentIcons.speaker_mute_24_regular,
                color: _primaryColor,
              ),
              iconSize: iconSize,
              onPressed: audioHandler.mute,
            );
          },
        ),
        if (isOnline)
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
        if (activePlaylist['list'].isNotEmpty)
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
                  itemCount: activePlaylist['list'].length,
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: 5,
                        bottom: 5,
                      ),
                      child: SongBar(
                        activePlaylist['list'][index],
                        false,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        if (isOnline)
          IconButton.filledTonal(
            icon: Icon(
              FluentIcons.text_32_filled,
              color: _primaryColor,
            ),
            iconSize: iconSize,
            onPressed: _lyricsController.flipcard,
          ),
        if (isOnline)
          ValueListenableBuilder<bool>(
            valueListenable: songLikeStatus,
            builder: (_, value, __) {
              return IconButton.filledTonal(
                icon: Icon(
                  value
                      ? FluentIcons.star_24_filled
                      : FluentIcons.star_24_regular,
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
        if (isOnline)
          ValueListenableBuilder<bool>(
            valueListenable: playNextSongAutomatically,
            builder: (_, value, __) {
              return IconButton.filledTonal(
                icon: Icon(
                  value
                      ? FluentIcons.music_note_2_play_20_filled
                      : FluentIcons.music_note_2_play_20_regular,
                  color: _primaryColor,
                ),
                iconSize: iconSize,
                onPressed: audioHandler.changeAutoPlayNextStatus,
              );
            },
          ),
      ],
    );
  }
}
