import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/customWidgets/custom_animated_bottom_bar.dart';
import 'package:musify/helper/flutter_toast.dart';
import 'package:musify/helper/version.dart';
import 'package:musify/main.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appTheme.dart';
import 'package:musify/ui/homePage.dart';
import 'package:musify/ui/morePage.dart';
import 'package:musify/ui/player.dart';
import 'package:musify/ui/playlistsPage.dart';
import 'package:musify/ui/searchPage.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Musify extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

ValueNotifier<int> activeTab = ValueNotifier<int>(0);

class AppState extends State<Musify> {
  @override
  void initState() {
    super.initState();
    checkAppUpdates().then(
      (value) => {
        if (value == true)
          {
            showToast(
              '${AppLocalizations.of(context)!.appUpdateIsAvailable}!',
            ),
          }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(),
      SearchPage(),
      PlaylistsPage(),
      MorePage(),
    ];
    return Scaffold(
      bottomNavigationBar: getFooter(),
      body: ValueListenableBuilder<int>(
        valueListenable: activeTab,
        builder: (_, value, __) {
          return pages[value];
        },
      ),
    );
  }

  Widget getFooter() {
    final items = <BottomNavBarItem>[
      BottomNavBarItem(
        icon: const Icon(MdiIcons.home),
        title: Text(
          AppLocalizations.of(context)!.home,
          maxLines: 1,
        ),
        activeColor: themeMode == ThemeMode.light ? accent.shade900 : accent,
        inactiveColor: Theme.of(context).hintColor,
      ),
      BottomNavBarItem(
        icon: const Icon(MdiIcons.magnify),
        title: Text(
          AppLocalizations.of(context)!.search,
          maxLines: 1,
        ),
        activeColor: themeMode == ThemeMode.light ? accent.shade900 : accent,
        inactiveColor: Theme.of(context).hintColor,
      ),
      BottomNavBarItem(
        icon: const Icon(MdiIcons.book),
        title: Text(
          AppLocalizations.of(context)!.playlists,
          maxLines: 1,
        ),
        activeColor: themeMode == ThemeMode.light ? accent.shade900 : accent,
        inactiveColor: Theme.of(context).hintColor,
      ),
      BottomNavBarItem(
        icon: const Icon(MdiIcons.dotsHorizontal),
        title: Text(
          AppLocalizations.of(context)!.more,
          maxLines: 1,
        ),
        activeColor: themeMode == ThemeMode.light ? accent.shade900 : accent,
        inactiveColor: Theme.of(context).hintColor,
      )
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<SequenceState?>(
          stream: audioPlayer.sequenceStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            if (state?.sequence.isEmpty ?? true) {
              return const SizedBox();
            }
            final metadata = state!.currentSource!.tag;
            return Container(
              height: 75,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 2),
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
                        child: metadata.extras['localSongId'] is int
                            ? QueryArtworkWidget(
                                id: metadata.extras['localSongId'] as int,
                                type: ArtworkType.AUDIO,
                                artworkBorder: BorderRadius.circular(8),
                                artworkWidth: 60,
                                artworkHeight: 60,
                                artworkFit: BoxFit.cover,
                                nullArtworkWidget: Icon(
                                  MdiIcons.musicNoteOutline,
                                  size: 30,
                                  color: accent,
                                ),
                                keepOldArtwork: true,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: metadata!.artUri.toString(),
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 60,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width: 50,
                                    height: 50,
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(
                                        30,
                                        255,
                                        255,
                                        255,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            metadata!.title.toString().length > 15
                                ? '${metadata!.title.toString().substring(0, 15)}...'
                                : metadata!.title.toString(),
                            style: TextStyle(
                              color: accent,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            metadata!.artist.toString().length > 15
                                ? '${metadata!.artist.toString().substring(0, 15)}...'
                                : metadata!.artist.toString(),
                            style: TextStyle(
                              color: accent,
                              fontSize: 15,
                            ),
                          )
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ValueListenableBuilder<PlayerState>(
                          valueListenable: playerState,
                          builder: (_, value, __) {
                            if (value.processingState ==
                                    ProcessingState.loading ||
                                value.processingState ==
                                    ProcessingState.buffering) {
                              return Container(
                                margin: const EdgeInsets.all(8),
                                width: MediaQuery.of(context).size.width * 0.08,
                                height:
                                    MediaQuery.of(context).size.width * 0.08,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(accent),
                                ),
                              );
                            } else if (value.playing != true) {
                              return IconButton(
                                icon: Icon(MdiIcons.play, color: accent),
                                iconSize: 45,
                                onPressed: play,
                                splashColor: Colors.transparent,
                              );
                            } else if (value.processingState !=
                                ProcessingState.completed) {
                              return IconButton(
                                icon: Icon(MdiIcons.pause, color: accent),
                                iconSize: 45,
                                onPressed: pause,
                                splashColor: Colors.transparent,
                              );
                            } else {
                              return IconButton(
                                icon: Icon(MdiIcons.replay, color: accent),
                                iconSize: 45,
                                onPressed: () => audioPlayer.seek(
                                  Duration.zero,
                                  index: audioPlayer.effectiveIndices!.first,
                                ),
                                splashColor: Colors.transparent,
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        _buildBottomBar(context, items),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, List<BottomNavBarItem> items) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      height: 65,
      child: CustomAnimatedBottomBar(
        backgroundColor: Theme.of(context).bottomAppBarColor,
        selectedIndex: activeTab.value,
        onItemSelected: (index) => setState(() {
          activeTab.value = index;
        }),
        items: items,
      ),
    );
  }
}
