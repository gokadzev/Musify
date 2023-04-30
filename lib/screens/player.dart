import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:on_audio_query/on_audio_query.dart' hide context;

class AudioApp extends StatefulWidget {
  @override
  AudioAppState createState() => AudioAppState();
}

@override
class AudioAppState extends State<AudioApp> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w70 = size.width - 70;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: size.height * 0.07,
        title: Text(
          context.l10n()!.nowPlaying,
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: IconButton(
            focusColor: Colors.transparent,
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(
              FluentIcons.chevron_down_20_regular,
              color: colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<SequenceState?>(
          stream: audioPlayer.sequenceStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            if (state?.sequence.isEmpty ?? true) {
              return const SizedBox();
            }
            final metadata = state!.currentSource!.tag;
            final songLikeStatus = ValueNotifier<bool>(
              isSongAlreadyLiked(metadata.extras['ytid']),
            );
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (metadata.extras['localSongId'] is int)
                  QueryArtworkWidget(
                    id: metadata.extras['localSongId'] as int,
                    type: ArtworkType.AUDIO,
                    artworkBorder: BorderRadius.circular(8),
                    artworkQuality: FilterQuality.high,
                    size: w70.toInt(),
                    artworkWidth: w70,
                    artworkHeight: w70,
                    nullArtworkWidget: Container(
                      width: w70,
                      height: w70,
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
                    keepOldArtwork: true,
                  )
                else
                  SizedBox(
                    width: w70,
                    height: w70,
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
                Padding(
                  padding: EdgeInsets.only(
                    top: size.height * 0.04,
                    bottom: size.height * 0.01,
                    left: size.width - (size.width - 30),
                    right: size.width - (size.width - 30),
                  ),
                  child: Column(
                    children: <Widget>[
                      MarqueeWidget(
                        backDuration: const Duration(seconds: 1),
                        child: Text(
                          metadata!.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.height * 0.030,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MarqueeWidget(
                        backDuration: const Duration(seconds: 1),
                        child: Text(
                          '${metadata!.artist}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.height * 0.020,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (metadata.extras['isLive'] != null &&
                    metadata.extras['isLive'])
                  controlButtonsForLive(
                    songLikeStatus,
                    metadata.extras['ytid'],
                  )
                else
                  Material(
                    child: _buildPlayer(
                      size,
                      songLikeStatus,
                      metadata.extras['ytid'],
                      metadata,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayer(
    Size size,
    ValueNotifier<bool> songLikeStatus,
    dynamic ytid,
    dynamic metadata,
  ) =>
      Container(
        padding: EdgeInsets.only(
          top: size.height * 0.01,
          left: 16,
          right: 16,
          bottom: size.height * 0.03,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<PositionData>(
              stream: positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (positionData != null)
                      Slider(
                        activeColor: colorScheme.primary,
                        inactiveColor: Colors.green[50],
                        value: positionData.position.inMilliseconds.toDouble(),
                        onChanged: (double? value) {
                          setState(() {
                            audioPlayer.seek(
                              Duration(
                                milliseconds: value!.round(),
                              ),
                            );
                            value = value;
                          });
                        },
                        max: positionData.duration.inMilliseconds.toDouble(),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (positionData != null)
                          Text(
                            positionData.position
                                .toString()
                                .split('.')
                                .first
                                .replaceFirst('0:0', '0'),
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        if (positionData != null)
                          Text(
                            positionData.duration
                                .toString()
                                .split('.')
                                .first
                                .replaceAll('0:', ''),
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).hintColor,
                            ),
                          )
                      ],
                    )
                  ],
                );
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: size.height * 0.03),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        if (metadata.extras['ytid'].toString().isNotEmpty)
                          Column(
                            children: [
                              IconButton(
                                color: Theme.of(context).hintColor,
                                icon: const Icon(
                                  FluentIcons.arrow_download_24_regular,
                                ),
                                onPressed: () => downloadSong(
                                  context,
                                  mediaItemToMap(metadata as MediaItem),
                                ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: muteNotifier,
                                builder: (_, value, __) {
                                  return IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      FluentIcons.speaker_mute_24_regular,
                                      color: value
                                          ? colorScheme.primary
                                          : Theme.of(context).hintColor,
                                    ),
                                    iconSize: 20,
                                    onPressed: mute,
                                    splashColor: Colors.transparent,
                                  );
                                },
                              ),
                            ],
                          ),
                        ValueListenableBuilder<bool>(
                          valueListenable: shuffleNotifier,
                          builder: (_, value, __) {
                            return IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                FluentIcons.arrow_shuffle_24_filled,
                                color: value
                                    ? colorScheme.primary
                                    : Theme.of(context).hintColor,
                              ),
                              iconSize: 20,
                              onPressed: changeShuffleStatus,
                              splashColor: Colors.transparent,
                            );
                          },
                        ),
                        IconButton(
                          padding: const EdgeInsets.only(right: 10),
                          icon: Icon(
                            FluentIcons.previous_24_filled,
                            color: hasPrevious
                                ? Theme.of(context).hintColor
                                : Colors.grey,
                          ),
                          iconSize: 30,
                          onPressed: () async => {
                            await playPrevious(),
                          },
                          splashColor: Colors.transparent,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: StreamBuilder<PlayerState>(
                            stream: audioPlayer.playerStateStream,
                            builder: (context, snapshot) {
                              final playerState = snapshot.data;
                              final processingState =
                                  playerState?.processingState;
                              final playing = playerState?.playing;
                              if (processingState == ProcessingState.loading ||
                                  processingState ==
                                      ProcessingState.buffering) {
                                return Container(
                                  margin: const EdgeInsets.all(8),
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).hintColor,
                                    ),
                                  ),
                                );
                              } else if (playing != true) {
                                return IconButton(
                                  icon: Icon(
                                    FluentIcons.play_12_filled,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  iconSize: 40,
                                  onPressed: audioPlayer.play,
                                  splashColor: Colors.transparent,
                                );
                              } else if (processingState !=
                                  ProcessingState.completed) {
                                return IconButton(
                                  icon: Icon(
                                    FluentIcons.pause_12_filled,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  iconSize: 40,
                                  onPressed: audioPlayer.pause,
                                  splashColor: Colors.transparent,
                                );
                              } else {
                                return IconButton(
                                  icon: Icon(
                                    FluentIcons.replay_20_filled,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  iconSize: 30,
                                  onPressed: () => audioPlayer.seek(
                                    Duration.zero,
                                    index: audioPlayer.effectiveIndices!.first,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          padding: const EdgeInsets.only(left: 10),
                          icon: Icon(
                            FluentIcons.next_24_filled,
                            color: hasNext
                                ? Theme.of(context).hintColor
                                : Colors.grey,
                          ),
                          iconSize: 30,
                          onPressed: () async => {
                            await playNext(),
                          },
                          splashColor: Colors.transparent,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            FluentIcons.arrow_repeat_1_24_filled,
                            color: repeatNotifier.value
                                ? colorScheme.primary
                                : Theme.of(context).hintColor,
                          ),
                          iconSize: 20,
                          onPressed: changeLoopStatus,
                          splashColor: Colors.transparent,
                        ),
                        if (metadata.extras['ytid'].toString().isNotEmpty)
                          Column(
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: songLikeStatus,
                                builder: (_, value, __) {
                                  if (value == true) {
                                    return IconButton(
                                      color: colorScheme.primary,
                                      icon: const Icon(
                                        FluentIcons.star_24_filled,
                                      ),
                                      iconSize: 20,
                                      splashColor: Colors.transparent,
                                      onPressed: () => {
                                        updateSongLikeStatus(ytid, false),
                                        songLikeStatus.value = false
                                      },
                                    );
                                  } else {
                                    return IconButton(
                                      color: Theme.of(context).hintColor,
                                      icon: const Icon(
                                        FluentIcons.star_24_regular,
                                      ),
                                      iconSize: 20,
                                      splashColor: Colors.transparent,
                                      onPressed: () => {
                                        updateSongLikeStatus(ytid, true),
                                        songLikeStatus.value = true
                                      },
                                    );
                                  }
                                },
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: playNextSongAutomatically,
                                builder: (_, value, __) {
                                  return IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      value
                                          ? FluentIcons
                                              .music_note_2_play_20_filled
                                          : FluentIcons
                                              .music_note_2_play_20_regular,
                                      color: value
                                          ? colorScheme.primary
                                          : Theme.of(context).hintColor,
                                    ),
                                    iconSize: 20,
                                    splashColor: Colors.transparent,
                                    onPressed: changeAutoPlayNextStatus,
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (metadata.extras['ytid'].toString().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: size.height * 0.047),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Builder(
                            builder: (context) {
                              return TextButton(
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
                                                      color:
                                                          colorScheme.primary,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => {
                                                      Navigator.pop(context)
                                                    },
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
                                                            activePlaylist[
                                                                'title'],
                                                            style: TextStyle(
                                                              color: colorScheme
                                                                  .primary,
                                                              fontSize: 30,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 5,
                                                    bottom: 5,
                                                  ),
                                                  child: SongBar(
                                                    activePlaylist['list']
                                                        [index],
                                                    false,
                                                  ),
                                                );
                                              },
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  context.l10n()!.playlist,
                                ),
                              );
                            },
                          ),
                          const Text(' | '),
                          Builder(
                            builder: (context) {
                              return TextButton(
                                onPressed: () {
                                  getSongLyrics(
                                    metadata.artist.toString(),
                                    metadata.title.toString(),
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
                                                      {Navigator.pop(context)},
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      right: 42,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!
                                                            .lyrics,
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
                                              ],
                                            ),
                                          ),
                                          ValueListenableBuilder<String>(
                                            valueListenable: lyrics,
                                            builder: (_, value, __) {
                                              if (value != 'null' &&
                                                  value != 'not found') {
                                                return Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    child: Center(
                                                      child:
                                                          SingleChildScrollView(
                                                        child: Text(
                                                          value,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } else if (value == 'null') {
                                                return const SizedBox(
                                                  child: Spinner(),
                                                );
                                              } else {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 120,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .lyricsNotAvailable,
                                                      style: const TextStyle(
                                                        fontSize: 25,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  context.l10n()!.lyrics,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget controlButtonsForLive(
    ValueNotifier<bool> songLikeStatus,
    dynamic ytid,
  ) =>
      Padding(
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: muteNotifier,
              builder: (_, value, __) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    FluentIcons.speaker_mute_24_regular,
                    color: value
                        ? colorScheme.primary
                        : Theme.of(context).hintColor,
                  ),
                  iconSize: 20,
                  onPressed: mute,
                  splashColor: Colors.transparent,
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: StreamBuilder<PlayerState>(
                stream: audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;
                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).hintColor,
                        ),
                      ),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: Icon(
                        FluentIcons.play_12_filled,
                        color: Theme.of(context).hintColor,
                      ),
                      iconSize: 40,
                      onPressed: audioPlayer.play,
                      splashColor: Colors.transparent,
                    );
                  } else if (processingState != ProcessingState.completed) {
                    return IconButton(
                      icon: Icon(
                        FluentIcons.pause_12_filled,
                        color: Theme.of(context).hintColor,
                      ),
                      iconSize: 40,
                      onPressed: audioPlayer.pause,
                      splashColor: Colors.transparent,
                    );
                  } else {
                    return IconButton(
                      icon: Icon(
                        FluentIcons.replay_20_filled,
                        color: Theme.of(context).hintColor,
                      ),
                      iconSize: 30,
                      onPressed: () => audioPlayer.seek(
                        Duration.zero,
                        index: audioPlayer.effectiveIndices!.first,
                      ),
                    );
                  }
                },
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: songLikeStatus,
              builder: (_, value, __) {
                if (value == true) {
                  return IconButton(
                    color: colorScheme.primary,
                    icon: const Icon(
                      FluentIcons.star_24_filled,
                    ),
                    iconSize: 20,
                    splashColor: Colors.transparent,
                    onPressed: () => {
                      updateSongLikeStatus(ytid, false),
                      songLikeStatus.value = false
                    },
                  );
                } else {
                  return IconButton(
                    color: Theme.of(context).hintColor,
                    icon: const Icon(
                      FluentIcons.star_24_regular,
                    ),
                    iconSize: 20,
                    splashColor: Colors.transparent,
                    onPressed: () => {
                      updateSongLikeStatus(ytid, true),
                      songLikeStatus.value = true
                    },
                  );
                }
              },
            ),
          ],
        ),
      );
}
