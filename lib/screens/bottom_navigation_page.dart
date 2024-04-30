import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({
    super.key,
    required this.child,
  });

  final StatefulNavigationShell child;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  final _selectedIndex = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    // can be wrapped in the SafeArea:
    // body: SafeArea(
    //   child: widget.child,
    // ),

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                logger.log(
                  'Error in mini player bar',
                  snapshot.error,
                  snapshot.stackTrace,
                );
              }
              final metadata = snapshot.data;
              if (metadata == null) {
                return const SizedBox.shrink();
              } else {
                return MiniPlayer(metadata: metadata);
              }
            },
          ),
          NavigationBar(
            selectedIndex: _selectedIndex.value,
            labelBehavior: languageSetting == const Locale('en', '')
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: (index) {
              widget.child.goBranch(
                index,
                initialLocation: index == widget.child.currentIndex,
              );
              setState(() {
                _selectedIndex.value = index;
              });
            },
            destinations: isOnline
                ? [
                    NavigationDestination(
                      icon: const Icon(FluentIcons.home_24_regular),
                      selectedIcon: const Icon(FluentIcons.home_24_filled),
                      label: context.l10n?.home ?? 'Home',
                    ),
                    NavigationDestination(
                      icon: const Icon(FluentIcons.search_24_regular),
                      selectedIcon: const Icon(FluentIcons.search_24_filled),
                      label: context.l10n?.search ?? 'Search',
                    ),
                    NavigationDestination(
                      icon: const Icon(FluentIcons.book_24_regular),
                      selectedIcon: const Icon(FluentIcons.book_24_filled),
                      label: context.l10n?.userPlaylists ?? 'User Playlists',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        FluentIcons.more_horizontal_24_regular,
                      ),
                      selectedIcon: const Icon(
                        FluentIcons.more_horizontal_24_filled,
                      ),
                      label: context.l10n?.more ?? 'More',
                    ),
                  ]
                : [
                    NavigationDestination(
                      icon: const Icon(FluentIcons.home_24_regular),
                      selectedIcon: const Icon(FluentIcons.home_24_filled),
                      label: context.l10n?.home ?? 'Home',
                    ),
                    NavigationDestination(
                      icon: const Icon(
                        FluentIcons.more_horizontal_24_regular,
                      ),
                      selectedIcon: const Icon(
                        FluentIcons.more_horizontal_24_filled,
                      ),
                      label: context.l10n?.more ?? 'More',
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}
