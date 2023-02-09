import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/screens/morePage.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/style/appTheme.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioApp extends StatefulWidget {
  @override
  AudioAppState createState() => AudioAppState();
}

@override
class AudioAppState extends State<AudioApp> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: size.height * 0.09,
        title: Text(
          AppLocalizations.of(context)!.nowPlaying,
          style: TextStyle(
            color: accent.primary,
            fontSize: size.height * 0.036,
            fontWeight: FontWeight.w700,
          ),
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
              color: accent.primary,
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
                    quality: 100,
                    artworkWidth: size.width - 100,
                    artworkHeight: size.width - 100,
                    nullArtworkWidget: Container(
                      width: size.width - 100,
                      height: size.width - 100,
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
                            color: accent.primary,
                          ),
                        ],
                      ),
                    ),
                    keepOldArtwork: true,
                  )
                else
                  SizedBox(
                    width: size.width - 100,
                    height: size.width - 100,
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
                              color: accent.primary,
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
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        metadata!.title
                            .toString()
                            .split(' (')[0]
                            .split('|')[0]
                            .trim(),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size.height * 0.035,
                          fontWeight: FontWeight.w700,
                          color: accent.primary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${metadata!.artist}',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.height * 0.015,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
            ValueListenableBuilder<Duration?>(
              valueListenable: position,
              builder: (_, positionvalue, __) {
                return ValueListenableBuilder<Duration?>(
                  valueListenable: duration,
                  builder: (_, durationvalue, __) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (durationvalue != null)
                          Slider(
                            activeColor: accent.primary,
                            inactiveColor: Colors.green[50],
                            value:
                                positionvalue?.inMilliseconds.toDouble() ?? 0.0,
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
                            max: durationvalue.inMilliseconds.toDouble(),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (positionvalue != null)
                              Text(
                                '$positionText '.replaceFirst('0:0', '0'),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            if (positionvalue != null)
                              Text(
                                durationText.replaceAll('0:', ''),
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
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  FluentIcons.arrow_download_24_filled,
                                  color: Theme.of(context).hintColor,
                                ),
                                iconSize: 20,
                                splashColor: Colors.transparent,
                                onPressed: () {
                                  downloadSong(
                                    context,
                                    mediaItemToMap(metadata as MediaItem),
                                  );
                                },
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  sponsorBlockSupport.value
                                      ? FluentIcons.play_circle_24_filled
                                      : FluentIcons.play_circle_24_regular,
                                  color: Theme.of(context).hintColor,
                                ),
                                iconSize: 20,
                                splashColor: Colors.transparent,
                                onPressed: () =>
                                    setState(changeSponsorBlockStatus),
                              ),
                            ],
                          ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            FluentIcons.arrow_shuffle_24_filled,
                            color: shuffleNotifier.value
                                ? accent.primary
                                : Theme.of(context).hintColor,
                          ),
                          iconSize: 20,
                          onPressed: changeShuffleStatus,
                          splashColor: Colors.transparent,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            FluentIcons.previous_24_filled,
                            color: hasPrevious
                                ? Theme.of(context).hintColor
                                : Colors.grey,
                          ),
                          iconSize: 40,
                          onPressed: playPrevious,
                          splashColor: Colors.transparent,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: ValueListenableBuilder<PlayerState>(
                            valueListenable: playerState,
                            builder: (_, value, __) {
                              if (value.processingState ==
                                      ProcessingState.loading ||
                                  value.processingState ==
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
                              } else if (value.playing != true) {
                                return IconButton(
                                  icon: Icon(
                                    FluentIcons.play_12_filled,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  iconSize: 40,
                                  onPressed: play,
                                  splashColor: Colors.transparent,
                                );
                              } else if (value.processingState !=
                                  ProcessingState.completed) {
                                return IconButton(
                                  icon: Icon(
                                    FluentIcons.pause_12_filled,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  iconSize: 40,
                                  onPressed: pause,
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
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            FluentIcons.next_24_filled,
                            color: hasNext
                                ? Theme.of(context).hintColor
                                : Colors.grey,
                          ),
                          iconSize: 40,
                          onPressed: playNext,
                          splashColor: Colors.transparent,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            FluentIcons.arrow_repeat_1_24_filled,
                            color: repeatNotifier.value
                                ? accent.primary
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
                                      color: accent.primary,
                                      icon: const Icon(
                                        FluentIcons.star_24_filled,
                                      ),
                                      iconSize: 20,
                                      splashColor: Colors.transparent,
                                      onPressed: () => {
                                        removeUserLikedSong(ytid),
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
                                        addUserLikedSong(ytid),
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
                                          ? accent.primary
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
                                                      color: accent.primary,
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
                                                              color: accent
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
                                  AppLocalizations.of(context)!.playlist,
                                  style: TextStyle(color: accent.primary),
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
                                                    color: accent.primary,
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
                                                          color: accent.primary,
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
                                  AppLocalizations.of(context)!.lyrics,
                                  style: TextStyle(color: accent.primary),
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
}
