import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/screens/home_page.dart';
import 'package:musify/screens/more_page.dart';
import 'package:musify/screens/player.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/screens/setup_page.dart';
import 'package:musify/screens/user_playlists_page.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/custom_animated_bottom_bar.dart';
import 'package:on_audio_query/on_audio_query.dart' hide context;

class Musify extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

ValueNotifier<int> activeTabIndex = ValueNotifier<int>(0);
ValueNotifier<String> activeTab = ValueNotifier<String>('/');
final _navigatorKey = GlobalKey<NavigatorState>();

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
    checkNecessaryPermissions(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          if (_navigatorKey.currentState!.canPop() &&
              _navigatorKey.currentState != null) {
            _navigatorKey.currentState?.pop();
            return false;
          }
          return true;
        },
        child: Navigator(
          key: _navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case '/':
                builder = (BuildContext context) => HomePage();
                break;
              case '/search':
                builder = (BuildContext context) => SearchPage();
                break;
              case '/userPlaylists':
                builder = (BuildContext context) => UserPlaylistsPage();
                break;
              case '/more':
                builder = (BuildContext context) => MorePage();
                break;
              case '/setup':
                builder = (BuildContext context) => SetupPage();
                break;
              default:
                throw Exception('Invalid route: ${settings.name}');
            }
            return MaterialPageRoute(
              builder: builder,
              settings: settings,
            );
          },
        ),
      ),
      bottomNavigationBar: getFooter(),
    );
  }

  Widget getFooter() {
    final items = <BottomNavBarItem>[
      BottomNavBarItem(
        icon: const Icon(FluentIcons.home_24_regular),
        title: Text(
          AppLocalizations.of(context)!.home,
          maxLines: 1,
        ),
        routeName: '/',
        activeColor: colorScheme.primary,
        inactiveColor: Theme.of(context).hintColor,
      ),
      BottomNavBarItem(
        icon: const Icon(FluentIcons.search_24_regular),
        title: Text(
          AppLocalizations.of(context)!.search,
          maxLines: 1,
        ),
        routeName: '/search',
        activeColor: colorScheme.primary,
        inactiveColor: Theme.of(context).hintColor,
      ),
      BottomNavBarItem(
        icon: const Icon(FluentIcons.book_24_regular),
        title: Text(
          AppLocalizations.of(context)!.userPlaylists,
          maxLines: 1,
        ),
        routeName: '/userPlaylists',
        activeColor: colorScheme.primary,
        inactiveColor: Theme.of(context).hintColor,
      ),
      BottomNavBarItem(
        icon: const Icon(FluentIcons.more_horizontal_24_regular),
        title: Text(
          AppLocalizations.of(context)!.more,
          maxLines: 1,
        ),
        routeName: '/more',
        activeColor: colorScheme.primary,
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
                          FluentIcons.arrow_up_24_filled,
                          size: 22,
                        ),
                        onPressed: null,
                        disabledColor: colorScheme.primary,
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
                                  FluentIcons.music_note_1_24_regular,
                                  size: 30,
                                  color: colorScheme.primary,
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
                                          FluentIcons.music_note_1_24_regular,
                                          size: 30,
                                          color: colorScheme.primary,
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
                              color: colorScheme.primary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            metadata!.artist.toString().length > 15
                                ? '${metadata!.artist.toString().substring(0, 15)}...'
                                : metadata!.artist.toString(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 15,
                            ),
                          )
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: StreamBuilder<PlayerState>(
                          stream: audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState =
                                playerState?.processingState;
                            final playing = playerState?.playing;
                            if (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering) {
                              return Container(
                                margin: const EdgeInsets.all(8),
                                width: MediaQuery.of(context).size.width * 0.08,
                                height:
                                    MediaQuery.of(context).size.width * 0.08,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              );
                            } else if (playing != true) {
                              return IconButton(
                                icon: Icon(
                                  FluentIcons.play_12_filled,
                                  color: colorScheme.primary,
                                ),
                                iconSize: 45,
                                onPressed: audioPlayer.play,
                                splashColor: Colors.transparent,
                              );
                            } else if (processingState !=
                                ProcessingState.completed) {
                              return IconButton(
                                icon: Icon(
                                  FluentIcons.pause_12_filled,
                                  color: colorScheme.primary,
                                ),
                                iconSize: 45,
                                onPressed: audioPlayer.pause,
                                splashColor: Colors.transparent,
                              );
                            } else {
                              return IconButton(
                                icon: Icon(
                                  FluentIcons.replay_20_filled,
                                  color: colorScheme.primary,
                                ),
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
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        selectedIndex: activeTabIndex.value,
        onItemSelected: (index) => setState(() {
          activeTabIndex.value = index;
          _navigatorKey.currentState!.pushReplacementNamed(activeTab.value);
        }),
        items: items,
      ),
    );
  }
}
