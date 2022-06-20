import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/custom_animated_bottom_bar.dart';
import 'package:musify/helper/version.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/homePage.dart';
import 'package:musify/ui/player.dart';
import 'package:musify/ui/playlistsPage.dart';
import 'package:musify/ui/searchPage.dart';
import 'package:musify/ui/settingsPage.dart';

class Musify extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

class AppState extends State<Musify> {
  int activeTab = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: bgColor,
        statusBarColor: bgColor,
      ),
    );
    initAudioPlayer();
    audioPlayer?.durationStream.listen(
      (d) => {
        if (mounted) {setState(() => duration = d)}
      },
    );
    checkAppUpdates().then(
      (value) => {
        if (value == true)
          {
            Fluttertoast.showToast(
              msg: "App Update Is Available!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: accent,
              textColor: Colors.white,
              fontSize: 14.0,
            )
          }
      },
    );
  }

  void initAudioPlayer() {
    audioPlayerStateSubscription =
        audioPlayer?.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        buttonNotifier.value = MPlayerState.loading;
      } else if (!isPlaying) {
        buttonNotifier.value = MPlayerState.paused;
      } else if (processingState != ProcessingState.completed) {
        buttonNotifier.value = MPlayerState.playing;
      } else {
        audioPlayer?.seek(Duration.zero);
        audioPlayer?.pause();
        if (activePlaylist.isNotEmpty && id! + 1 < activePlaylist.length) {
          playNext();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(bottomNavigationBar: getFooter(), body: getBody());
  }

  Widget getFooter() {
    final List<BottomNavBarItem> items = [
      BottomNavBarItem(
        icon: const Icon(MdiIcons.homeOutline),
        title: const Text('Home'),
        activeColor: accent,
        inactiveColor: Colors.white,
        textAlign: TextAlign.center,
      ),
      BottomNavBarItem(
        icon: const Icon(MdiIcons.magnify),
        title: const Text('Search'),
        activeColor: accent,
        inactiveColor: Colors.white,
        textAlign: TextAlign.center,
      ),
      BottomNavBarItem(
        icon: const Icon(MdiIcons.bookOutline),
        title: const Text('Playlists'),
        activeColor: accent,
        inactiveColor: Colors.white,
        textAlign: TextAlign.center,
      ),
      BottomNavBarItem(
        icon: const Icon(MdiIcons.cogOutline),
        title: const Text('Settings'),
        activeColor: accent,
        inactiveColor: Colors.white,
        textAlign: TextAlign.center,
      )
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<SequenceState?>(
          stream: audioPlayer!.sequenceStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            if (state?.sequence.isEmpty ?? true) {
              return const SizedBox();
            }
            final metadata = state!.currentSource!.tag;
            return Container(
              height: 75,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                color: bgLight,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AudioApp(),
                      ),
                    );
                  },
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(
                          MdiIcons.appleKeyboardControl,
                          size: 22,
                        ),
                        onPressed: null,
                        disabledColor: accent,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 7,
                          bottom: 7,
                          right: 15,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: metadata!.artUri.toString(),
                            fit: BoxFit.fill,
                            errorWidget: (context, url, error) => Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withAlpha(30),
                                    Colors.white.withAlpha(30)
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    MdiIcons.musicNoteOutline,
                                    size: 30,
                                    color: accent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              metadata!.title.toString().length > 15
                                  ? "${metadata!.title.toString().split(' (')[0].split('|')[0].trim().substring(0, 15)}..."
                                  : metadata!.title.toString(),
                              style: TextStyle(
                                color: accent,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              metadata!.artist.toString().length > 15
                                  ? "${metadata!.artist.toString().substring(0, 15)}..."
                                  : metadata!.artist.toString(),
                              style: TextStyle(
                                color: accent,
                                fontSize: 15,
                              ),
                            )
                          ],
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<MPlayerState>(
                        valueListenable: buttonNotifier,
                        builder: (_, value, __) {
                          return IconButton(
                            icon: buttonNotifier.value == MPlayerState.playing
                                ? const Icon(MdiIcons.pause)
                                : const Icon(MdiIcons.playOutline),
                            color: accent,
                            splashColor: Colors.transparent,
                            onPressed: () {
                              setState(() {
                                if (buttonNotifier.value ==
                                    MPlayerState.playing) {
                                  audioPlayer?.pause();
                                } else if (buttonNotifier.value ==
                                    MPlayerState.paused) {
                                  audioPlayer?.play();
                                }
                              });
                            },
                            iconSize: 45,
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        _buildBottomBar(items),
      ],
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: activeTab,
      children: [HomePage(), SearchPage(), PlaylistsPage(), SettingsPage()],
    );
  }

  Widget _buildBottomBar(List<BottomNavBarItem> items) {
    return CustomAnimatedBottomBar(
        animationDuration: const Duration(milliseconds: 330),
        containerHeight: 65,
        backgroundColor: bgLight,
        selectedIndex: activeTab,
        showElevation: true,
        itemCornerRadius: 15,
        curve: Curves.easeIn,
        onItemSelected: (index) => setState(() => activeTab = index),
        items: items,
        radius: BorderRadius.zero);
  }
}
