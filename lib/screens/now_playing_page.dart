import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:on_audio_query/on_audio_query.dart' hide context;

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
                  FractionallySizedBox(
                    widthFactor: 0.80,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: QueryArtworkWidget(
                        id: metadata.extras['localSongId'] as int,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.circular(8),
                        artworkQuality: FilterQuality.high,
                        size: size.width.toInt() - 100,
                        nullArtworkWidget: DecoratedBox(
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
                      ),
                    ),
                  )
                else
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
                          metadata!.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.height * 0.030,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MarqueeWidget(
                        backDuration: const Duration(seconds: 1),
                        child: Text(
                          '${metadata!.artist}',
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
                if (metadata.extras['isLive'] != null &&
                    metadata.extras['isLive'])
                  const SizedBox()
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
            stream: positionDataStream,
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
                      setState(() {
                        audioPlayer.seek(Duration(milliseconds: value.round()));
                      });
                    },
                    max: positionData.duration.inMilliseconds.toDouble(),
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
                  )
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
                        if (metadata.extras['ytid'].toString().isNotEmpty)
                          Column(
                            children: [
                              IconButton(
                                color: colorScheme.primary,
                                icon: const Icon(
                                  FluentIcons.arrow_download_24_regular,
                                ),
                                onPressed: () => prefferedDownloadMode.value ==
                                        'normal'
                                    ? downloadSong(
                                        context,
                                        mediaItemToMap(metadata as MediaItem),
                                      )
                                    : downloadSongFaster(
                                        context,
                                        mediaItemToMap(metadata as MediaItem),
                                      ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: muteNotifier,
                                builder: (_, value, __) {
                                  return IconButton(
                                    icon: Icon(
                                      value
                                          ? FluentIcons.speaker_mute_24_filled
                                          : FluentIcons.speaker_mute_24_regular,
                                      color: colorScheme.primary,
                                    ),
                                    iconSize: constraints.maxWidth * 0.05,
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
                              icon: Icon(
                                FluentIcons.arrow_shuffle_24_filled,
                                color: value
                                    ? colorScheme.primary
                                    : colorScheme.primary,
                              ),
                              iconSize: constraints.maxWidth * 0.05,
                              onPressed: changeShuffleStatus,
                              splashColor: Colors.transparent,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            FluentIcons.previous_24_filled,
                            color: hasPrevious
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.5),
                          ),
                          iconSize: constraints.maxWidth * 0.09,
                          onPressed: () async {
                            await playPrevious();
                          },
                          splashColor: Colors.transparent,
                        ),
                        StreamBuilder<PlayerState>(
                          stream: audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            if (playerState == null)
                              return const SizedBox.shrink();

                            final processingState = playerState.processingState;
                            final playing = playerState.playing;

                            if (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering) {
                              return const Spinner();
                            }

                            return GestureDetector(
                              onTap: playing
                                  ? audioPlayer.pause
                                  : audioPlayer.play,
                              child: Icon(
                                playing
                                    ? FluentIcons.pause_circle_48_filled
                                    : FluentIcons.play_circle_48_filled,
                                color: colorScheme.primary,
                                size: 60,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            FluentIcons.next_24_filled,
                            color: hasNext
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.5),
                          ),
                          iconSize: constraints.maxWidth * 0.09,
                          onPressed: () async {
                            await playNext();
                          },
                          splashColor: Colors.transparent,
                        ),
                        IconButton(
                          icon: Icon(
                            FluentIcons.arrow_repeat_1_24_filled,
                            color: repeatNotifier.value
                                ? colorScheme.primary
                                : colorScheme.primary,
                          ),
                          iconSize: constraints.maxWidth * 0.05,
                          onPressed: changeLoopStatus,
                          splashColor: Colors.transparent,
                        ),
                        if (metadata.extras['ytid'].toString().isNotEmpty)
                          Column(
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: songLikeStatus,
                                builder: (_, value, __) {
                                  final iconData = value
                                      ? FluentIcons.star_24_filled
                                      : FluentIcons.star_24_regular;
                                  return IconButton(
                                    color: value
                                        ? colorScheme.primary
                                        : colorScheme.primary,
                                    icon: Icon(iconData),
                                    iconSize: constraints.maxWidth * 0.05,
                                    splashColor: Colors.transparent,
                                    onPressed: () {
                                      updateSongLikeStatus(ytid, !value);
                                      songLikeStatus.value = !value;
                                    },
                                  );
                                },
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: playNextSongAutomatically,
                                builder: (_, value, __) {
                                  final iconData = value
                                      ? FluentIcons.music_note_2_play_20_filled
                                      : FluentIcons
                                          .music_note_2_play_20_regular;
                                  return IconButton(
                                    icon: Icon(
                                      iconData,
                                      color: value
                                          ? colorScheme.primary
                                          : colorScheme.primary,
                                    ),
                                    iconSize: constraints.maxWidth * 0.05,
                                    splashColor: Colors.transparent,
                                    onPressed: changeAutoPlayNextStatus,
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
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
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        context,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                          right: 42,
                                                          bottom: 42,
                                                        ),
                                                        child: Center(
                                                          child: MarqueeWidget(
                                                            child: Text(
                                                              activePlaylist[
                                                                  'title'],
                                                              style: TextStyle(
                                                                color:
                                                                    colorScheme
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
                                                    activePlaylist['list']
                                                        .length,
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
                                  child: Text(context.l10n()!.playlist),
                                );
                              },
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
}
