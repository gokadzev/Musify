import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/customWidgets/custom_animated_bottom_bar.dart';
import 'package:musify/helper/version.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/ui/homePage.dart';
import 'package:musify/ui/playlistsPage.dart';
import 'package:musify/ui/searchPage.dart';
import 'package:musify/ui/settingsPage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/ui/player.dart';
import 'package:musify/style/appColors.dart';

class Musify extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

class AppState extends State<Musify> {
  int activeTab = 0;

  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: bgColor,
      statusBarColor: bgColor,
    ));
    initAudioPlayer();
    audioPlayer?.durationStream.listen((d) => {
          if (this.mounted) {setState(() => duration = d)}
        });
    checkAppUpdates().then((value) => {
          if (value)
            {
              Fluttertoast.showToast(
                  msg: "App Update Is Available!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: accent,
                  textColor: Colors.white,
                  fontSize: 14.0)
            }
        });
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
        if (activePlaylist.length != 0 && id! + 1 < activePlaylist.length) {
          playNext();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(bottomNavigationBar: getFooter(), body: getBody()),
    );
  }

  Widget getFooter() {
    List items = <BottomNavBarItem>[
      BottomNavBarItem(
        icon: Icon(MdiIcons.homeOutline),
        title: Text('Home'),
        activeColor: accent,
        inactiveColor: Colors.white,
        textAlign: TextAlign.center,
      ),
      BottomNavBarItem(
        icon: Icon(MdiIcons.magnify),
        title: Text('Search'),
        activeColor: accent,
        inactiveColor: Colors.white,
        textAlign: TextAlign.center,
      ),
      BottomNavBarItem(
        icon: Icon(MdiIcons.bookOutline),
        title: Text('Playlists'),
        activeColor: accent,
        inactiveColor: Colors.white,
        textAlign: TextAlign.center,
      ),
      BottomNavBarItem(
        icon: Icon(MdiIcons.cogOutline),
        title: Text('Settings'),
        activeColor: accent,
        inactiveColor: Colors.white,
        textAlign: TextAlign.center,
      )
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<String>(
            valueListenable: kUrlNotifier,
            builder: (_, value, __) {
              return kUrlNotifier.value != ""
                  ? Container(
                      height: 75,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18)),
                          color: kUrlNotifier.value != ""
                              ? Color(0xff1c252a)
                              : bgColor),
                      child: Padding(
                          padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                          child: GestureDetector(
                              onTap: () {
                                if (kUrl != "") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AudioApp()),
                                  );
                                }
                              },
                              child: Row(
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      MdiIcons.appleKeyboardControl,
                                      size: 22,
                                    ),
                                    onPressed: null,
                                    disabledColor: accent,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 0.0,
                                        top: 7,
                                        bottom: 7,
                                        right: 15),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: CachedNetworkImage(
                                          imageUrl: highResImage!,
                                          fit: BoxFit.fill,
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                width: 50,
                                                height: 50,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Icon(
                                                        MdiIcons
                                                            .musicNoteOutline,
                                                        size: 30,
                                                        color: accent),
                                                  ],
                                                ),
                                                decoration: new BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                  gradient: new LinearGradient(
                                                    colors: [
                                                      accent.withAlpha(30),
                                                      Colors.white.withAlpha(30)
                                                    ],
                                                  ),
                                                ),
                                              )),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          title!.length > 15
                                              ? title!.substring(0, 15) + "..."
                                              : title!,
                                          style: TextStyle(
                                              color: accent,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          artist!.length > 15
                                              ? artist!.substring(0, 15) + "..."
                                              : artist!,
                                          style: TextStyle(
                                              color: accent, fontSize: 15),
                                        )
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  ValueListenableBuilder<MPlayerState>(
                                      valueListenable: buttonNotifier,
                                      builder: (_, value, __) {
                                        return IconButton(
                                          icon: buttonNotifier.value ==
                                                  MPlayerState.playing
                                              ? Icon(MdiIcons.pause)
                                              : Icon(MdiIcons.playOutline),
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
                                      })
                                ],
                              ))))
                  : const SizedBox.shrink();
            }),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0)),
          width: MediaQuery.of(context).size.width * 0.95,
          height: 65,
          margin: const EdgeInsets.only(bottom: 10),
          child: _buildBottomBar(items),
        )
      ],
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: activeTab,
      children: [HomePage(), SearchPage(), PlaylistsPage(), SettingsPage()],
    );
  }

  Widget _buildBottomBar(items) {
    return CustomAnimatedBottomBar(
      animationDuration: Duration(milliseconds: 360),
      containerHeight: 70,
      backgroundColor: Color(0XFF282828),
      selectedIndex: activeTab,
      showElevation: true,
      itemCornerRadius: 24,
      curve: Curves.easeIn,
      onItemSelected: (index) => setState(() => activeTab = index),
      items: items,
    );
  }
}
