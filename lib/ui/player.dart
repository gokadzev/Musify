import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/helper/mediaitem.dart';
import 'package:musify/helper/transparent.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/style/appTheme.dart';
import 'package:on_audio_query/on_audio_query.dart';

String status = 'hidden';

typedef OnError = void Function(Exception exception);

StreamSubscription? positionSubscription;
StreamSubscription? durationSubscription;

Duration? duration;
Duration? position;

enum MPlayerState { stopped, playing, paused, loading }

class AudioApp extends StatefulWidget {
  @override
  AudioAppState createState() => AudioAppState();
}

@override
class AudioAppState extends State<AudioApp> {
  @override
  void initState() {
    super.initState();

    positionSubscription = audioPlayer.positionStream
        .listen((p) => {if (mounted) setState(() => position = p)});
    durationSubscription = audioPlayer.durationStream.listen(
      (d) => {
        if (mounted) {setState(() => duration = d)}
      },
    );
  }

  @override
  void dispose() {
    positionSubscription!.cancel();
    durationSubscription!.cancel();
    super.dispose();
  }

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
            color: accent,
            fontSize: size.height * 0.036,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 32,
              color: accent,
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: size.height * 0.012),
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
                      artworkWidth: size.width / 1.2,
                      artworkHeight: size.height / 2.7,
                      nullArtworkWidget: Container(
                        width: size.width / 1.2,
                        height: size.height / 2.7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(30, 255, 255, 255),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              MdiIcons.musicNoteOutline,
                              size: size.width / 8,
                              color: accent,
                            ),
                          ],
                        ),
                      ),
                      keepOldArtwork: true,
                    )
                  else
                    SizedBox(
                      width: size.width / 1.2,
                      height: size.height / 2.7,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: FadeInImage.memoryNetwork(
                          image: metadata.artUri.toString(),
                          fit: BoxFit.cover,
                          placeholder: transparentImage,
                          imageErrorBuilder: (context, url, error) =>
                              DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(30, 255, 255, 255),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  MdiIcons.musicNoteOutline,
                                  size: size.width / 8,
                                  color: accent,
                                ),
                              ],
                            ),
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
                            color: accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${metadata!.artist}',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accentLight,
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
            if (duration != null)
              Slider(
                activeColor: accent,
                inactiveColor: Colors.green[50],
                value: position?.inMilliseconds.toDouble() ?? 0.0,
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
                max: duration!.inMilliseconds.toDouble(),
              ),
            if (position != null) _buildProgressView(),
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
                                icon: const Icon(
                                  MdiIcons.download,
                                  color: Colors.white,
                                ),
                                iconSize: size.width * 0.056,
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
                                      ? MdiIcons.playCircle
                                      : MdiIcons.playCircleOutline,
                                  color: Colors.white,
                                ),
                                iconSize: size.width * 0.056,
                                splashColor: Colors.transparent,
                                onPressed: () =>
                                    setState(changeSponsorBlockStatus),
                              ),
                            ],
                          ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            MdiIcons.shuffle,
                            color:
                                shuffleNotifier.value ? accent : Colors.white,
                          ),
                          iconSize: size.width * 0.056,
                          onPressed: changeShuffleStatus,
                          splashColor: Colors.transparent,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.skip_previous,
                            color: hasPrevious ? Colors.white : Colors.grey,
                            size: size.width * 0.1,
                          ),
                          iconSize: size.width * 0.056,
                          onPressed: playPrevious,
                          splashColor: Colors.transparent,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
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
                                  width: size.width * 0.08,
                                  height: size.width * 0.08,
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                );
                              } else if (value.playing != true) {
                                return IconButton(
                                  icon: const Icon(MdiIcons.play),
                                  iconSize: size.width * 0.1,
                                  color: bgColor,
                                  onPressed: play,
                                  splashColor: Colors.transparent,
                                );
                              } else if (value.processingState !=
                                  ProcessingState.completed) {
                                return IconButton(
                                  icon: const Icon(MdiIcons.pause),
                                  iconSize: size.width * 0.1,
                                  color: bgColor,
                                  onPressed: pause,
                                  splashColor: Colors.transparent,
                                );
                              } else {
                                return IconButton(
                                  icon: const Icon(MdiIcons.replay),
                                  iconSize: size.width * 0.056,
                                  color: bgColor,
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
                            Icons.skip_next,
                            color: hasNext ? Colors.white : Colors.grey,
                            size: size.width * 0.1,
                          ),
                          iconSize: size.width * 0.08,
                          onPressed: playNext,
                          splashColor: Colors.transparent,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            MdiIcons.repeat,
                            color: repeatNotifier.value ? accent : Colors.white,
                          ),
                          iconSize: size.width * 0.056,
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
                                      color: accent,
                                      icon: const Icon(MdiIcons.star),
                                      iconSize: size.width * 0.056,
                                      splashColor: Colors.transparent,
                                      onPressed: () => {
                                        removeUserLikedSong(ytid),
                                        songLikeStatus.value = false
                                      },
                                    );
                                  } else {
                                    return IconButton(
                                      color: Colors.white,
                                      icon: const Icon(MdiIcons.starOutline),
                                      iconSize: size.width * 0.056,
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
                                          ? MdiIcons.skipNextCircle
                                          : MdiIcons.skipNextCircleOutline,
                                      color: value ? accent : Colors.white,
                                    ),
                                    iconSize: size.width * 0.056,
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
                      child: Builder(
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
                                    color: Color(0xFF151515),
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
                                                Icons.arrow_back_ios,
                                                color: accent,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  {Navigator.pop(context)},
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 42,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .lyrics,
                                                    style: TextStyle(
                                                      color: accent,
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
                                                  child: SingleChildScrollView(
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: accentLight,
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
                                              padding: const EdgeInsets.only(
                                                top: 120,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .lyricsNotAvailable,
                                                  style: TextStyle(
                                                    color: accentLight,
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
                              style: TextStyle(color: accent),
                            ),
                          );
                        },
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      );

  Row _buildProgressView() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            position != null
                ? '$positionText '.replaceFirst('0:0', '0')
                : duration != null
                    ? durationText
                    : '',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const Spacer(),
          Text(
            position != null
                ? durationText.replaceAll('0:', '')
                : duration != null
                    ? durationText
                    : '',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          )
        ],
      );
}
