import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playback_icon_button.dart';
import 'package:musify/widgets/song_artwork.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: size.height * 0.07,
        title: Text(context.l10n!.nowPlaying),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            } else {
              final metadata = snapshot.data!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: size.height * 0.01),
                  buildArtwork(size, metadata),
                  SizedBox(height: size.height * 0.03),
                  buildMarqueeText(
                    metadata.title,
                    Theme.of(context).colorScheme.primary,
                    size.height * 0.030,
                    FontWeight.bold,
                    size.width,
                  ),
                  const SizedBox(height: 4),
                  if (metadata.artist != null)
                    buildMarqueeText(
                      metadata.artist!,
                      Theme.of(context).colorScheme.primary,
                      size.height * 0.018,
                      FontWeight.w500,
                      size.width,
                    ),
                  if (!(metadata.extras?['isLive'] ?? false))
                    _buildPlayer(
                      context,
                      size,
                      metadata.extras?['ytid'],
                      metadata,
                    ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildArtwork(Size size, MediaItem metadata) {
    const padding = 90;
    final imageSize = size.width - padding;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 300,
      ),
      child: SongArtworkWidget(
        metadata: metadata,
        size: imageSize,
        errorWidgetIconSize: size.width / 8,
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
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.02,
        horizontal: size.width * 0.05,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildPositionSlider(),
          SizedBox(height: size.height * 0.03),
          buildPlayerControls(context, size, audioId, mediaItem),
        ],
      ),
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildSlider(Theme.of(context).colorScheme.primary, positionData),
            buildPositionRow(
              Theme.of(context).colorScheme.primary,
              positionData,
            ),
          ],
        );
      },
    );
  }

  Widget buildSlider(Color activeColor, PositionData positionData) {
    return Slider(
      activeColor: activeColor,
      inactiveColor: Colors.green[50],
      value: positionData.position.inMilliseconds.toDouble(),
      onChanged: (value) {
        audioHandler.seek(Duration(milliseconds: value.toInt()));
      },
      max: positionData.duration.inMilliseconds.toDouble() + 5000,
    );
  }

  Widget buildPositionRow(Color fontColor, PositionData positionData) {
    final positionText = formatDuration(positionData.position.inMilliseconds);
    final durationText = formatDuration(positionData.duration.inMilliseconds);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          positionText,
          style: TextStyle(
            fontSize: 17,
            color: fontColor,
          ),
        ),
        const Spacer(),
        Text(
          durationText,
          style: TextStyle(
            fontSize: 17,
            color: fontColor,
          ),
        ),
      ],
    );
  }

  Widget buildPlayerControls(
    BuildContext context,
    Size size,
    dynamic audioId,
    MediaItem mediaItem,
  ) {
    final songLikeStatus = ValueNotifier<bool>(isSongAlreadyLiked(audioId));
    const iconSize = 20.0;
    return Column(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: shuffleNotifier,
                builder: (_, value, __) {
                  return IconButton(
                    icon: Icon(
                      value
                          ? FluentIcons.arrow_shuffle_24_filled
                          : FluentIcons.arrow_shuffle_off_24_filled,
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
                  color: audioHandler.hasPrevious
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
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
                    Theme.of(context).colorScheme.primary,
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  FluentIcons.next_24_filled,
                  color: audioHandler.hasNext
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
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
        ),
        SizedBox(height: size.height * 0.1),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: muteNotifier,
              builder: (_, value, __) {
                return IconButton(
                  icon: Icon(
                    value
                        ? FluentIcons.speaker_mute_24_filled
                        : FluentIcons.speaker_mute_24_regular,
                  ),
                  iconSize: iconSize,
                  onPressed: audioHandler.mute,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              iconSize: iconSize,
              onPressed: () {
                _showAddToPlaylistDialog(context, mediaItemToMap(mediaItem));
              },
            ),
            if (activePlaylist['list'].isNotEmpty)
              IconButton(
                icon: const Icon(FluentIcons.apps_list_24_filled),
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
              icon: const Icon(FluentIcons.text_32_filled),
              iconSize: iconSize,
              onPressed: () {
                getSongLyrics(
                  mediaItem.artist ?? '',
                  mediaItem.title,
                );
                showCustomBottomSheet(
                  context,
                  ValueListenableBuilder<String?>(
                    valueListenable: lyrics,
                    builder: (_, value, __) {
                      if (value != null && value != 'not found') {
                        return Padding(
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
                        );
                      } else if (value == null) {
                        return const Spinner();
                      } else {
                        return Text(
                          context.l10n!.lyricsNotAvailable,
                          style: const TextStyle(
                            fontSize: 25,
                          ),
                          textAlign: TextAlign.center,
                        );
                      }
                    },
                  ),
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: songLikeStatus,
              builder: (_, value, __) {
                return IconButton(
                  icon: Icon(
                    value
                        ? FluentIcons.star_24_filled
                        : FluentIcons.star_24_regular,
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

  void _showAddToPlaylistDialog(BuildContext context, dynamic song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n!.addToPlaylist),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final playlist in userCustomPlaylists)
                Card(
                  color: Theme.of(context).colorScheme.secondary,
                  child: ListTile(
                    title: Text(playlist['title']),
                    onTap: () {
                      addSongInCustomPlaylist(playlist['title'], song);
                      showToast(context, context.l10n!.addedSuccess);
                      Navigator.pop(context);
                    },
                    textColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
