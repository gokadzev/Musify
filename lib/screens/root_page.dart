import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/widgets/mini_player.dart';

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
      body: PopScope(
        canPop: _navigatorKey.currentState?.canPop() == true,
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
                return MiniPlayer(metadata: metadata);
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
                label: context.l10n!.home,
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.search_24_regular),
                selectedIcon: const Icon(FluentIcons.search_24_filled),
                label: context.l10n!.search,
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.book_24_regular),
                selectedIcon: const Icon(FluentIcons.book_24_filled),
                label: context.l10n!.userPlaylists,
              ),
              NavigationDestination(
                icon: const Icon(FluentIcons.more_horizontal_24_regular),
                selectedIcon: const Icon(FluentIcons.more_horizontal_24_filled),
                label: context.l10n!.more,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
