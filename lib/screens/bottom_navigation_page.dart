/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({super.key, required this.child});

  final StatefulNavigationShell child;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  ({
    List<NavigationDestination> destinations,
    int selectedIndex,
    List<int> visibleIndexes,
  })
  _getNavigationDestinations(
    BuildContext context,
    bool isOffline,
    int currentBranchIndex,
  ) {
    final allDestinations = <NavigationDestination>[
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
        label: context.l10n?.library ?? 'Library',
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.settings_24_regular),
        selectedIcon: const Icon(FluentIcons.settings_24_filled),
        label: context.l10n?.settings ?? 'Settings',
      ),
    ];
    // The branch index always maps to the original allDestinations index (0:home, 1:search, 2:library, 3:settings)
    // visibleIndexes is the list of branch indexes to show
    final visibleIndexes = !isOffline ? [0, 1, 2, 3] : [0, 2, 3];
    final destinations = visibleIndexes.map((i) => allDestinations[i]).toList();
    // selectedIndex is the index in visibleIndexes that matches the current branch index
    var selectedIndex = visibleIndexes.indexOf(currentBranchIndex);
    // If not found (e.g. current branch is search but offline), fallback to first
    if (selectedIndex == -1) selectedIndex = 0;
    return (
      destinations: destinations,
      selectedIndex: selectedIndex,
      visibleIndexes: visibleIndexes,
    );
  }

  void _onDestinationSelected(int visibleIndex, List<int> visibleIndexes) {
    final branchIndex = visibleIndexes[visibleIndex];
    widget.child.goBranch(
      branchIndex,
      initialLocation: branchIndex != widget.child.currentIndex,
    );
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: offlineMode,
      builder: (context, isOffline, _) {
        final navigationData = _getNavigationDestinations(
          context,
          isOffline,
          widget.child.currentIndex,
        );
        final destinations = navigationData.destinations;
        final visibleIndexes = navigationData.visibleIndexes;
        final selectedVisibleIndex = navigationData.selectedIndex;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = _isLargeScreen(context);
            return Scaffold(
              body: Row(
                children: [
                  if (isLargeScreen)
                    NavigationRail(
                      labelType: NavigationRailLabelType.selected,
                      destinations:
                          destinations
                              .map(
                                (destination) => NavigationRailDestination(
                                  icon: destination.icon,
                                  selectedIcon: destination.selectedIcon,
                                  label: Text(destination.label),
                                ),
                              )
                              .toList(),
                      selectedIndex: selectedVisibleIndex,
                      onDestinationSelected:
                          (index) =>
                              _onDestinationSelected(index, visibleIndexes),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: widget.child),
                        StreamBuilder<MediaItem?>(
                          stream: audioHandler.mediaItem.distinct((prev, curr) {
                            if (prev == null || curr == null) return false;
                            return prev.id == curr.id &&
                                prev.title == curr.title &&
                                prev.artist == curr.artist &&
                                prev.artUri == curr.artUri;
                          }),
                          builder: (context, snapshot) {
                            final metadata = snapshot.data;
                            if (metadata == null) {
                              return const SizedBox.shrink();
                            }
                            return MiniPlayer(metadata: metadata);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar:
                  !isLargeScreen
                      ? NavigationBar(
                        selectedIndex: selectedVisibleIndex,
                        labelBehavior:
                            languageSetting == const Locale('en', '')
                                ? NavigationDestinationLabelBehavior
                                    .onlyShowSelected
                                : NavigationDestinationLabelBehavior.alwaysHide,
                        onDestinationSelected:
                            (index) =>
                                _onDestinationSelected(index, visibleIndexes),
                        destinations: destinations,
                      )
                      : null,
            );
          },
        );
      },
    );
  }
}
