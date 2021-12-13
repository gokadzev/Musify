import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:Musify/style/appColors.dart';

import 'API/musify.dart';
import 'services/audio_manager.dart';

String status = 'hidden';

typedef void OnError(Exception exception);

StreamSubscription? positionSubscription;
StreamSubscription? audioPlayerStateSubscription;

Duration? duration;
Duration? position;

get isPlaying => buttonNotifier.value == MPlayerState.playing;

get isPaused => buttonNotifier.value == MPlayerState.paused;

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

    initAudioPlayer();
  }

  void initAudioPlayer() {
    if (buttonNotifier.value != MPlayerState.playing) {
      setState(() {
        play();
      });
    }

    audioPlayer?.durationStream.listen((d) => setState(() => duration = d));

    positionSubscription = audioPlayer?.positionStream
        .listen((p) => {if (mounted) setState(() => position = p)});

    audioPlayerStateSubscription = audioPlayer?.playerStateStream.listen((s) {
      final isPlaying = s.playing;
      final processingState = s.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        buttonNotifier.value = MPlayerState.loading;
      } else if (!isPlaying) {
        buttonNotifier.value = MPlayerState.paused;
      } else if (processingState != ProcessingState.completed) {
        buttonNotifier.value = MPlayerState.playing;
      } else {
        buttonNotifier.value = MPlayerState.stopped;
        duration = Duration.zero;
        audioPlayer!.seek(Duration.zero);
      }
    });
  }

  void onComplete() {
    if (mounted) setState(() => buttonNotifier.value = MPlayerState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff384850),
            Color(0xff263238),
            Color(0xff263238),
            //Color(0xff61e88a),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          backgroundColor: bgColor,
          elevation: 0,
          //backgroundColor: Color(0xff384850),
          centerTitle: true,
          title: GradientText(
            "Now Playing",
            shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
            gradient: LinearGradient(colors: [
              accent,
              accent,
            ]),
            style: TextStyle(
              color: accent,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 14.0),
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
            padding: const EdgeInsets.only(top: 35.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    shape: BoxShape.rectangle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: CachedNetworkImageProvider(image!),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 35.0, bottom: 35),
                  child: Column(
                    children: <Widget>[
                      GradientText(
                        title!,
                        shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
                        gradient: LinearGradient(colors: [
                          accent,
                          accent,
                        ]),
                        textScaleFactor: 2.5,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          album! + "  |  " + artist!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accentLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(child: _buildPlayer()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.only(top: 15.0, left: 16, right: 16, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (duration != null)
              Slider(
                  activeColor: accent,
                  inactiveColor: Colors.green[50],
                  value: position?.inMilliseconds.toDouble() ?? 0.0,
                  onChanged: (double? value) {
                    print(value);
                    setState(() {
                      audioPlayer!.seek((Duration(
                          seconds: (value! / 1000).roundToDouble().toInt())));
                      value = value;
                    });
                  },
                  min: 0.0,
                  max: duration!.inMilliseconds.toDouble()),
            if (position != null) _buildProgressView(),
            Padding(
              padding: const EdgeInsets.only(top: 18.0),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent,
                                //Color(0xff00c754),
                                accent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(100)),
                        child: ValueListenableBuilder<MPlayerState>(
                          valueListenable: buttonNotifier,
                          builder: (_, value, __) {
                            switch (value) {
                              case MPlayerState.loading:
                                return Container(
                                  margin: const EdgeInsets.all(8.0),
                                  width: 32.0,
                                  height: 32.0,
                                  child: const CircularProgressIndicator(),
                                );
                              case MPlayerState.paused:
                                return IconButton(
                                  icon: const Icon(MdiIcons.play),
                                  iconSize: 32.0,
                                  onPressed: () {
                                    play();
                                  },
                                );
                              case MPlayerState.playing:
                                return IconButton(
                                  icon: const Icon(MdiIcons.pause),
                                  iconSize: 32.0,
                                  onPressed: () {
                                    pause();
                                  },
                                );
                              case MPlayerState.stopped:
                                return IconButton(
                                  icon: const Icon(MdiIcons.play),
                                  iconSize: 32.0,
                                  onPressed: () {
                                    play();
                                  },
                                );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Builder(builder: (context) {
                      return TextButton(
                          onPressed: () {
                            showBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                      decoration: BoxDecoration(
                                          color: Color(0xff212c31),
                                          borderRadius: BorderRadius.only(
                                              topLeft:
                                                  const Radius.circular(18.0),
                                              topRight:
                                                  const Radius.circular(18.0))),
                                      height: 400,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10.0),
                                            child: Row(
                                              children: <Widget>[
                                                IconButton(
                                                    icon: Icon(
                                                      Icons.arrow_back_ios,
                                                      color: accent,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => {
                                                          Navigator.pop(context)
                                                        }),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 42.0),
                                                    child: Center(
                                                      child: Text(
                                                        "Lyrics",
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
                                          lyrics != "null"
                                              ? Expanded(
                                                  flex: 1,
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6.0),
                                                      child: Center(
                                                        child:
                                                            SingleChildScrollView(
                                                          child: Text(
                                                            lyrics!,
                                                            style: TextStyle(
                                                              fontSize: 16.0,
                                                              color:
                                                                  accentLight,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      )),
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 120.0),
                                                  child: Center(
                                                    child: Container(
                                                      child: Text(
                                                        "No Lyrics available ;(",
                                                        style: TextStyle(
                                                            color: accentLight,
                                                            fontSize: 25),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ));
                          },
                          child: Text(
                            "Lyrics",
                            style: TextStyle(color: accent),
                          ));
                    }),
                  )
                ],
              ),
            ),
          ],
        ),
      );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          position != null
              ? "${positionText ?? ''} ".replaceFirst("0:0", "0")
              : duration != null
                  ? durationText
                  : '',
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        ),
        Spacer(),
        Text(
          position != null
              ? "${durationText ?? ''}".replaceAll("0:", "")
              : duration != null
                  ? durationText
                  : '',
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        )
      ]);
}
