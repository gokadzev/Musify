import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/main.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/no_artwork_cube.dart';
import 'package:musify/widgets/playback_icon_button.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: size.height * 0.07,
        title: Text(context.l10n!.nowPlaying),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            final metadata = snapshot.data;

            if (metadata == null) {
              return const SizedBox.shrink();
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: size.height * 0.01),
                  buildArtwork(size, metadata),
                  SizedBox(height: size.height * 0.03),
                  buildMarqueeText(
                    metadata.title,
                    size.height * 0.030,
                    FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  buildMarqueeText(
                    metadata.artist ?? '',
                    size.height * 0.018,
                    FontWeight.w500,
                  ),
                  if (!(metadata.extras?['isLive'] ?? false))
                    _buildPlayer(size, metadata.extras?['ytid'], metadata),
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
      child: metadata.artUri?.scheme == 'file'
          ? SizedBox(
              width: imageSize,
              height: imageSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(metadata.extras?['artWorkPath'])),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          : CachedNetworkImage(
              width: imageSize,
              height: imageSize,
              imageUrl: metadata.artUri.toString(),
              imageBuilder: (context, imageProvider) =>
                  _buildImageDecoration(imageProvider),
              placeholder: (context, url) => const Spinner(),
              errorWidget: (context, url, error) => NullArtworkWidget(
                iconSize: size.width / 8,
              ),
            ),
    );
  }

  Widget _buildImageDecoration(ImageProvider<Object> imageProvider) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget buildMarqueeText(String text, double fontSize, FontWeight fontWeight) {
    return MarqueeWidget(
      backDuration: const Duration(seconds: 1),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPlayer(
    Size size,
    dynamic audioId,
    dynamic mediaItem,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.01,
        horizontal: size.width * 0.05,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildPositionSlider(),
          SizedBox(height: size.height * 0.03),
          buildPlayerControls(size, audioId, mediaItem),
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

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildSlider(snapshot.data!),
            buildPositionRow(snapshot.data!),
          ],
        );
      },
    );
  }

  Widget buildSlider(PositionData positionData) {
    return Slider(
      activeColor: colorScheme.primary,
      inactiveColor: Colors.green[50],
      value: positionData.position.inMilliseconds.toDouble(),
      onChanged: (value) {
        audioHandler.seek(Duration(milliseconds: value.toInt()));
      },
      max: positionData.duration.inMilliseconds.toDouble() + 5000,
    );
  }

  Widget buildPositionRow(PositionData positionData) {
    final positionText = formatDuration(positionData.position.inMilliseconds);
    final durationText = formatDuration(positionData.duration.inMilliseconds);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildText(positionText),
        const Spacer(),
        buildText(durationText),
      ],
    );
  }

  Widget buildText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        color: colorScheme.primary,
      ),
    );
  }

  Widget buildPlayerControls(Size size, dynamic audioId, MediaItem mediaItem) {
    final songLikeStatus = ValueNotifier<bool>(isSongAlreadyLiked(audioId));
    return LayoutBuilder(
      builder: (context, constraints) {
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
                      return customIconButton(
                        shuffleNotifier.value
                            ? FluentIcons.arrow_shuffle_24_filled
                            : FluentIcons.arrow_shuffle_off_24_filled,
                        colorScheme.primary,
                        20,
                        () {
                          audioHandler.setShuffleMode(
                            shuffleNotifier.value
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
                          ? colorScheme.primary
                          : colorScheme.primary.withOpacity(0.5),
                    ),
                    iconSize: constraints.maxWidth * 0.09 < 35
                        ? constraints.maxWidth * 0.09
                        : 35,
                    onPressed: () async {
                      await audioHandler.skipToPrevious();
                    },
                    splashColor: Colors.transparent,
                  ),
                  StreamBuilder<PlaybackState>(
                    stream: audioHandler.playbackState,
                    builder: (context, snapshot) {
                      return buildPlaybackIconButton(snapshot.data, 60);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      FluentIcons.next_24_filled,
                      color: audioHandler.hasNext
                          ? colorScheme.primary
                          : colorScheme.primary.withOpacity(0.5),
                    ),
                    iconSize: constraints.maxWidth * 0.09 < 35
                        ? constraints.maxWidth * 0.09
                        : 35,
                    onPressed: () async {
                      await audioHandler.skipToNext();
                    },
                    splashColor: Colors.transparent,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: repeatNotifier,
                    builder: (_, value, __) {
                      return customIconButton(
                        value
                            ? FluentIcons.arrow_repeat_1_24_filled
                            : FluentIcons.arrow_repeat_all_off_24_filled,
                        colorScheme.primary,
                        20,
                        () => audioHandler.setRepeatMode(
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
            SizedBox(height: size.height * 0.047),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: muteNotifier,
                  builder: (_, value, __) {
                    return customIconButton(
                      value
                          ? FluentIcons.speaker_mute_24_filled
                          : FluentIcons.speaker_mute_24_regular,
                      colorScheme.primary,
                      20,
                      audioHandler.mute,
                    );
                  },
                ),
                customIconButton(
                  Icons.add,
                  colorScheme.primary,
                  20,
                  () {
                    _showAddToPlaylistDialog(
                      context,
                      mediaItemToMap(mediaItem),
                    );
                  },
                ),
                customIconButton(
                  FluentIcons.apps_list_24_filled,
                  colorScheme.primary,
                  20,
                  () {
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
                customIconButton(
                  FluentIcons.text_32_filled,
                  colorScheme.primary,
                  20,
                  () {
                    getSongLyrics(
                      mediaItem.artist.toString(),
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
                    return customIconButton(
                      value
                          ? FluentIcons.star_24_filled
                          : FluentIcons.star_24_regular,
                      songLikeStatus.value
                          ? colorScheme.primary
                          : colorScheme.primary,
                      20,
                      () {
                        updateSongLikeStatus(
                          audioId,
                          !songLikeStatus.value,
                        );
                        songLikeStatus.value = !songLikeStatus.value;
                      },
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: playNextSongAutomatically,
                  builder: (_, value, __) {
                    return customIconButton(
                      value
                          ? FluentIcons.music_note_2_play_20_filled
                          : FluentIcons.music_note_2_play_20_regular,
                      colorScheme.primary,
                      20,
                      audioHandler.changeAutoPlayNextStatus,
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
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
                  color: colorScheme.secondary,
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

  Widget customIconButton(
    IconData iconData,
    Color color,
    double iconSize,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(iconData, color: color),
      iconSize: iconSize,
      onPressed: onPressed,
      splashColor: Colors.transparent,
    );
  }
}
