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

final _lyricsController = FlipCardController();

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.nowPlaying),
      ),
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
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
                      Column(
                        children: [
                          const SizedBox(height: 1),
                          buildMarqueeText(
                            metadata.title,
                            Theme.of(context).colorScheme.primary,
                            screenHeight * 0.034,
                            FontWeight.bold,
                            screenWidth,
                          ),
                          const SizedBox(height: 4),
                          if (metadata.artist != null)
                            buildMarqueeText(
                              metadata.artist!,
                              Theme.of(context).colorScheme.secondary,
                              screenHeight * 0.015,
                              FontWeight.w400,
                              screenWidth,
                            ),
                        ],
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
    const padding = 90;
    final imageSize = size.width - padding;

    return FlipCard(
      rotateSide: RotateSide.right,
      onTapFlipping: true,
      controller: _lyricsController,
      frontWidget: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
          maxHeight: 300,
        ),
        child: SongArtworkWidget(
          metadata: metadata,
          size: imageSize,
          errorWidgetIconSize: size.width / 8,
        ),
      ),
      backWidget: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
          maxHeight: 300,
        ),
        child: Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
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
    double maxWidth,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.05),
      child: MarqueeWidget(
        backDuration: const Duration(seconds: 1),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: fontColor,
          ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildPositionSlider(),
        SizedBox(height: size.height * 0.03),
        buildPlayerControls(context, size, audioId, mediaItem),
      ],
    );
  }

  Widget buildPositionSlider() {
    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final positionData = snapshot.data!;
        final primaryColor = Theme.of(context).colorScheme.primary;
        final secondaryColor = Theme.of(context).colorScheme.secondaryContainer;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildSlider(
              secondaryColor,
              primaryColor,
              positionData,
            ),
            buildPositionRow(
              primaryColor,
              positionData,
            ),
          ],
        );
      },
    );
  }

  Widget buildSlider(
    Color sliderColor,
    Color activeColor,
    PositionData positionData,
  ) {
    return Slider(
      activeColor: activeColor,
      inactiveColor: sliderColor,
      value: positionData.position.inSeconds.toDouble(),
      onChanged: (value) {
        audioHandler.seek(Duration(seconds: value.toInt()));
      },
      max: positionData.duration.inSeconds.toDouble(),
    );
  }

  Widget buildPositionRow(Color fontColor, PositionData positionData) {
    final positionText = formatDuration(positionData.position.inSeconds);
    final durationText = formatDuration(positionData.duration.inSeconds);
    final textStyle = TextStyle(fontSize: 17, color: fontColor);

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
    dynamic audioId,
    MediaItem mediaItem,
  ) {
    final songLikeStatus = ValueNotifier<bool>(isSongAlreadyLiked(audioId));
    late final songOfflineStatus =
        ValueNotifier<bool>(isSongAlreadyOffline(audioId));
    const iconSize = 20.0;

    final _primaryColor = Theme.of(context).colorScheme.primary;
    final _secondaryColor = Theme.of(context).colorScheme.secondaryContainer;

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: shuffleNotifier,
              builder: (_, value, __) {
                return IconButton(
                  icon: Icon(
                    value
                        ? FluentIcons.arrow_shuffle_24_filled
                        : FluentIcons.arrow_shuffle_off_24_filled,
                    color: value ? _primaryColor : _secondaryColor,
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
                color:
                    audioHandler.hasPrevious ? _primaryColor : _secondaryColor,
              ),
              iconSize: size.width * 0.09 < 35 ? size.width * 0.09 : 35,
              onPressed: () => audioHandler.skipToPrevious(),
              splashColor: Colors.transparent,
            ),
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                return buildPlaybackIconButton(
                  snapshot.data,
                  size.width * 0.19 < 72 ? size.width * 0.19 : 72,
                  _primaryColor,
                );
              },
            ),
            IconButton(
              icon: Icon(
                FluentIcons.next_24_filled,
                color: audioHandler.hasNext ? _primaryColor : _secondaryColor,
              ),
              iconSize: size.width * 0.09 < 35 ? size.width * 0.09 : 35,
              onPressed: () => audioHandler.skipToNext(),
              splashColor: Colors.transparent,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: repeatNotifier,
              builder: (_, value, __) {
                return IconButton(
                  icon: Icon(
                    value
                        ? FluentIcons.arrow_repeat_1_24_filled
                        : FluentIcons.arrow_repeat_all_off_24_filled,
                    color: value ? _primaryColor : _secondaryColor,
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
        SizedBox(height: size.height * 0.1),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: songOfflineStatus,
              builder: (_, value, __) {
                return IconButton(
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
                return IconButton(
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
            IconButton(
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
              IconButton(
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
            IconButton(
              icon: Icon(
                FluentIcons.text_32_filled,
                color: _primaryColor,
              ),
              iconSize: iconSize,
              onPressed: _lyricsController.flipcard,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: songLikeStatus,
              builder: (_, value, __) {
                return IconButton(
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
            ValueListenableBuilder<bool>(
              valueListenable: playNextSongAutomatically,
              builder: (_, value, __) {
                return IconButton(
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
        ),
      ],
    );
  }
}
