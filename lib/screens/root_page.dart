import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/style/app_themes.dart';

class Musify extends StatefulWidget {
  @override
  _MusifyState createState() => _MusifyState();
}

final _navigatorKey = GlobalKey<NavigatorState>();

class _MusifyState extends State<Musify> {
  @override
  void initState() {
    super.initState();
    if (!isFdroidBuild) {
      unawaited(checkAppUpdates(context));
    }

    unawaited(checkNecessaryPermissions(context));
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          if (_navigatorKey.currentState?.canPop() == true) {
            _navigatorKey.currentState?.pop();
            return false;
          }
          return true;
        },
        child: Navigator(
          key: _navigatorKey,
          initialRoute: RoutePaths.home,
          onGenerateRoute: RouterService.generateRoute,
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              final metadata = snapshot.data;
              if (metadata == null) {
                return const SizedBox();
              } else {
                return Container(
                  height: 75,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        icon: Icon(
                          FluentIcons.arrow_up_24_filled,
                          size: 22,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NowPlayingPage(),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 7,
                          bottom: 7,
                          right: 15,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: metadata.artUri.toString(),
                            fit: BoxFit.cover,
                            width: 55,
                            height: 55,
                            errorWidget: (context, url, error) =>
                                _buildNullArtworkWidget(),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            metadata.title.length > 15
                                ? '${metadata.title.substring(0, 15)}...'
                                : metadata.title,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            metadata.artist.toString().length > 15
                                ? '${metadata.artist.toString().substring(0, 15)}...'
                                : metadata.artist.toString(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      PlaybackControls(),
                    ],
                  ),
                );
              }
            },
          ),
          NavigationBar(
            selectedIndex: _selectedIndex,
            labelBehavior: locale == const Locale('en', '')
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: (int index) {
              if (_selectedIndex == index) {
                if (_navigatorKey.currentState?.canPop() == true) {
                  _navigatorKey.currentState?.pop();
                }
              } else {
                setState(() {
                  _selectedIndex = index;
                });
                _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  destinations[index],
                  ModalRoute.withName(destinations[index]),
                );
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(FluentIcons.home_24_regular),
                selectedIcon: const Icon(FluentIcons.home_24_filled),
                label: context.l10n()!.home,
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.search_24_regular),
                selectedIcon: const Icon(FluentIcons.search_24_filled),
                label: context.l10n()!.search,
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.book_24_regular),
                selectedIcon: const Icon(FluentIcons.book_24_filled),
                label: context.l10n()!.userPlaylists,
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.more_horizontal_24_regular),
                selectedIcon: const Icon(FluentIcons.more_horizontal_24_filled),
                label: context.l10n()!.more,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNullArtworkWidget() => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: colorScheme.secondary,
          ),
          child: const Center(
            child: Icon(
              FluentIcons.music_note_1_24_regular,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      );
}

class PlaybackControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: StreamBuilder<PlaybackState>(
            stream: audioHandler.playbackState,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;

              IconData icon;
              VoidCallback? onPressed;

              if (processingState == AudioProcessingState.loading ||
                  processingState == AudioProcessingState.buffering) {
                icon = FluentIcons.spinner_ios_16_filled;
                onPressed = null;
              } else if (playing != true) {
                icon = FluentIcons.play_12_filled;
                onPressed = audioHandler.play;
              } else if (processingState != AudioProcessingState.completed) {
                icon = FluentIcons.pause_12_filled;
                onPressed = audioHandler.pause;
              } else {
                icon = FluentIcons.replay_20_filled;
                onPressed = () => audioHandler.seek(
                      Duration.zero,
                    );
              }

              return IconButton(
                icon: Icon(icon, color: colorScheme.primary),
                iconSize: 45,
                onPressed: onPressed,
                splashColor: Colors.transparent,
              );
            },
          ),
        );
      },
    );
  }
}
