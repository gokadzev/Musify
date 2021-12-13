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
import 'package:musify/music.dart';
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
      systemNavigationBarColor: Color(0xff1c252a),
      statusBarColor: Colors.transparent,
    ));
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
          ],
        ),
      ),
      child: Scaffold(bottomNavigationBar: getFooter(), body: getBody()),
    );
  }

  Widget getFooter() {
    List items = [
      MdiIcons.homeOutline,
      MdiIcons.magnify,
      MdiIcons.bookOutline,
      MdiIcons.cogOutline,
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
                      //color: Color(0xff1c252a),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18)),
                          color: Color(0xff1c252a)),
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
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    MdiIcons.appleKeyboardControl,
                                    size: 22,
                                  ),
                                  onPressed: null,
                                  disabledColor: accent,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 0.0, top: 7, bottom: 7, right: 15),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: image!,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 0.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      title!.length > 18
                                          ? title!.substring(0, 18) + "..."
                                          : title!,
                                      style: TextStyle(
                                          color: accent,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      artist!.length > 18
                                          ? artist!.substring(0, 18) + "..."
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
                                            buttonNotifier.value =
                                                MPlayerState.paused;
                                          } else if (buttonNotifier.value ==
                                              MPlayerState.paused) {
                                            audioPlayer?.setUrl(kUrl!);
                                            audioPlayer?.play();
                                            buttonNotifier.value =
                                                MPlayerState.playing;
                                          }
                                        });
                                      },
                                      iconSize: 45,
                                    );
                                  })
                            ],
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink();
            }),
        Container(
          height: 65,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(80.0),
              color: Color(0XFF282828),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 0))
              ]),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(items.length, (index) {
                  return IconButton(
                      icon: Icon(
                        items[index],
                        color: activeTab == index ? accent : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          activeTab = index;
                        });
                      });
                })),
          ),
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
}
