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
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class NowPlayingPage extends StatefulWidget {
  @override
  _NowPlayingPageState createState() => _NowPlayingPageState();
}

@override
class _NowPlayingPageState extends State<NowPlayingPage> {
  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: size.height * 0.07,
        title: Text(
          context.l10n!.nowPlaying,
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: GestureDetector(
            child: Icon(
              FluentIcons.chevron_down_20_regular,
              color: colorScheme.primary,
            ),
            onTap: () => Navigator.pop(context, false),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            final metadata = snapshot.data;
            final audioId = metadata?.extras?['ytid'];
            if (metadata == null) {
              return const SizedBox();
            } else {
              final songLikeStatus = ValueNotifier<bool>(
                isSongAlreadyLiked(audioId),
              );
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.80,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: metadata.artUri.toString(),
                        imageBuilder: (context, imageProvider) => DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => const Spinner(),
                        errorWidget: (context, url, error) => DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromARGB(30, 255, 255, 255),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                FluentIcons.music_note_1_24_regular,
                                size: size.width / 8,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: size.height * 0.03,
                      left: 20,
                      right: 20,
                    ),
                    child: Column(
                      children: <Widget>[
                        MarqueeWidget(
                          backDuration: const Duration(seconds: 1),
                          child: Text(
                            metadata.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: size.height * 0.030,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        MarqueeWidget(
                          backDuration: const Duration(seconds: 1),
                          child: Text(
                            '${metadata.artist}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: size.height * 0.018,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (metadata.extras?['isLive'] != null &&
                      metadata.extras?['isLive'])
                    const SizedBox()
                  else
                    Material(
                      child: _buildPlayer(
                        size,
                        songLikeStatus,
                        audioId,
                        metadata,
                      ),
                    ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlayer(
    Size size,
    ValueNotifier<bool> songLikeStatus,
    dynamic audioId,
    dynamic mediaItem,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.01,
        horizontal: size.width * 0.05,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<PositionData>(
            stream: audioHandler.positionDataStream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              if (positionData == null) return const SizedBox.shrink();

              final positionText =
                  formatDuration(positionData.position.inMilliseconds);
              final durationText =
                  formatDuration(positionData.duration.inMilliseconds);

              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Slider(
                    activeColor: colorScheme.primary,
                    inactiveColor: Colors.green[50],
                    value: positionData.position.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      audioHandler.seek(Duration(milliseconds: value.toInt()));
                    },
                    max: positionData.duration.inMilliseconds.toDouble() + 5000,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        positionText,
                        style: TextStyle(
                          fontSize: 17,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        durationText,
                        style: TextStyle(
                          fontSize: 17,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          Padding(
            padding: EdgeInsets.only(top: size.height * 0.03),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: muteNotifier,
                              builder: (_, value, __) {
                                return customIconButton(
                                  value
                                      ? FluentIcons.speaker_mute_24_filled
                                      : FluentIcons.speaker_mute_24_regular,
                                  colorScheme.primary,
                                  constraints.maxWidth * 0.05,
                                  audioHandler.mute,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add,
                                color: colorScheme.primary,
                              ),
                              onPressed: () {
                                _showAddToPlaylistDialog(
                                  context,
                                  mediaItemToMap(mediaItem),
                                );
                              },
                            ),
                          ],
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: shuffleNotifier,
                          builder: (_, value, __) {
                            return customIconButton(
                              shuffleNotifier.value
                                  ? FluentIcons.arrow_shuffle_24_filled
                                  : FluentIcons.arrow_shuffle_off_24_filled,
                              colorScheme.primary,
                              constraints.maxWidth * 0.05,
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
                          iconSize: constraints.maxWidth * 0.09,
                          onPressed: () async {
                            await audioHandler.skipToPrevious();
                          },
                          splashColor: Colors.transparent,
                        ),
                        StreamBuilder<PlaybackState>(
                          stream: audioHandler.playbackState,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            if (playerState == null)
                              return const SizedBox.shrink();

                            final processingState = playerState.processingState;
                            final playing = playerState.playing;

                            IconData icon;
                            VoidCallback? onPressed;

                            if (processingState ==
                                    AudioProcessingState.loading ||
                                processingState ==
                                    AudioProcessingState.buffering) {
                              icon = FluentIcons.spinner_ios_20_filled;
                              onPressed = null;
                            } else if (!playing) {
                              icon = FluentIcons.play_circle_48_filled;
                              onPressed = audioHandler.play;
                            } else if (processingState !=
                                AudioProcessingState.completed) {
                              icon = FluentIcons.pause_circle_48_filled;
                              onPressed = audioHandler.pause;
                            } else {
                              icon = FluentIcons.replay_20_filled;
                              onPressed =
                                  () => audioHandler.seek(Duration.zero);
                            }

                            return GestureDetector(
                              onTap: onPressed,
                              child: Icon(
                                icon,
                                color: colorScheme.primary,
                                size: 60,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            FluentIcons.next_24_filled,
                            color: audioHandler.hasNext
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.5),
                          ),
                          iconSize: constraints.maxWidth * 0.09,
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
                              constraints.maxWidth * 0.05,
                              () => audioHandler.setRepeatMode(
                                value
                                    ? AudioServiceRepeatMode.none
                                    : AudioServiceRepeatMode.all,
                              ),
                            );
                          },
                        ),
                        Column(
                          children: [
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
                                  constraints.maxWidth * 0.05,
                                  () {
                                    updateSongLikeStatus(
                                      audioId,
                                      !songLikeStatus.value,
                                    );
                                    songLikeStatus.value =
                                        !songLikeStatus.value;
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
                                      : FluentIcons
                                          .music_note_2_play_20_regular,
                                  colorScheme.primary,
                                  constraints.maxWidth * 0.05,
                                  audioHandler.changeAutoPlayNextStatus,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: size.height * 0.047),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              showBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                    ),
                                  ),
                                  height: size.height / 2.14,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: <Widget>[
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: size.height * 0.012,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              IconButton(
                                                icon: Icon(
                                                  FluentIcons
                                                      .arrow_between_down_24_filled,
                                                  color: colorScheme.primary,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    right: 42,
                                                    bottom: 42,
                                                  ),
                                                  child: Center(
                                                    child: MarqueeWidget(
                                                      child: Text(
                                                        activePlaylist['title'],
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .primary,
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          addAutomaticKeepAlives: false,
                                          addRepaintBoundaries: false,
                                          itemCount:
                                              activePlaylist['list'].length,
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
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Text(context.l10n!.playlist),
                          ),
                          const Text(' | '),
                          TextButton(
                            onPressed: () {
                              getSongLyrics(
                                mediaItem.artist.toString(),
                                mediaItem.title.toString(),
                              );

                              showBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                    ),
                                  ),
                                  height: size.height / 2.14,
                                  child: Column(
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: size.height * 0.012,
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            IconButton(
                                              icon: Icon(
                                                FluentIcons
                                                    .arrow_between_down_24_filled,
                                                color: colorScheme.primary,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 42,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    context.l10n!.lyrics,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.primary,
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ValueListenableBuilder<String?>(
                                        valueListenable: lyrics,
                                        builder: (_, value, __) {
                                          if (value != null &&
                                              value != 'not found') {
                                            return Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                child: Center(
                                                  child: SingleChildScrollView(
                                                    child: Text(
                                                      value,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else if (value == null) {
                                            return const SizedBox(
                                              child: Spinner(),
                                            );
                                          } else {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 120,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  context
                                                      .l10n!.lyricsNotAvailable,
                                                  style: const TextStyle(
                                                    fontSize: 25,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Text(context.l10n!.lyrics),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
