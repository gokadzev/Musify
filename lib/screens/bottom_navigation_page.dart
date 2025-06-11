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
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({
    required this.child,
    this.isOfflineMode = false,
    super.key,
  });

  final StatefulNavigationShell child;
  final bool isOfflineMode;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = MediaQuery.of(context).size.width >= 600;
        final items = _getNavigationItems;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (isLargeScreen)
                  NavigationRail(
                    labelType: NavigationRailLabelType.selected,
                    destinations:
                        items
                            .map(
                              (item) => NavigationRailDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.icon),
                                label: Text(item.label),
                              ),
                            )
                            .toList(),
                    selectedIndex: _getCurrentIndex,
                    onDestinationSelected: _onTabTapped,
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
          ),
          bottomNavigationBar:
              !isLargeScreen
                  ? NavigationBar(
                    selectedIndex: _getCurrentIndex,
                    labelBehavior:
                        languageSetting == const Locale('en', '')
                            ? NavigationDestinationLabelBehavior
                                .onlyShowSelected
                            : NavigationDestinationLabelBehavior.alwaysHide,
                    onDestinationSelected: _onTabTapped,
                    destinations:
                        items
                            .map(
                              (item) => NavigationDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.icon),
                                label: item.label,
                              ),
                            )
                            .toList(),
                  )
                  : null,
        );
      },
    );
  }

  List<_NavigationItem> get _getNavigationItems {
    final items = <_NavigationItem>[
      _NavigationItem(
        icon: FluentIcons.home_24_regular,
        selectedIcon: FluentIcons.home_24_filled,
        label: context.l10n?.home ?? 'Home',
        route: '/home',
        index: 0,
      ),
    ];

    // Only add search tab in online mode
    if (!widget.isOfflineMode) {
      items.add(
        _NavigationItem(
          icon: FluentIcons.search_24_regular,
          selectedIcon: FluentIcons.search_24_filled,
          label: context.l10n?.search ?? 'Search',
          route: '/search',
          index: 1,
        ),
      );
    }

    // Adjust indices based on whether search is included
    final libraryIndex = widget.isOfflineMode ? 1 : 2;
    final settingsIndex = widget.isOfflineMode ? 2 : 3;

    items.addAll([
      _NavigationItem(
        icon: FluentIcons.book_24_regular,
        selectedIcon: FluentIcons.book_24_filled,
        label: context.l10n?.library ?? 'Library',
        route: '/library',
        index: libraryIndex,
      ),
      _NavigationItem(
        icon: FluentIcons.settings_24_regular,
        selectedIcon: FluentIcons.settings_24_filled,
        label: context.l10n?.settings ?? 'Settings',
        route: '/settings',
        index: settingsIndex,
      ),
    ]);

    return items;
  }

  @override
  void didUpdateWidget(BottomNavigationPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle offline mode transition
    if (oldWidget.isOfflineMode != widget.isOfflineMode) {
      _handleOfflineModeChange();
    }
  }

  void _handleOfflineModeChange() {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // If we're switching to offline mode and currently on search tab
    if (widget.isOfflineMode && currentRoute.startsWith('/search')) {
      // Navigate to home
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.child.goBranch(0);
        }
      });
    }
  }

  void _onTabTapped(int index) {
    final items = _getNavigationItems;
    if (index < items.length) {
      final item = items[index];
      // Use the shell navigation index instead of the route
      widget.child.goBranch(item.shellIndex);
    }
  }

  int get _getCurrentIndex {
    final items = _getNavigationItems;
    final currentIndex = widget.child.currentIndex;

    // Add bounds checking
    if (currentIndex < 0 || items.isEmpty) {
      return 0;
    }

    // Map shell index to navigation items index
    for (var i = 0; i < items.length; i++) {
      if (items[i].shellIndex == currentIndex) {
        return i;
      }
    }

    // Handle edge cases more robustly
    if (widget.isOfflineMode && currentIndex == 1) {
      return 0; // Search -> Home
    }

    if (widget.isOfflineMode && currentIndex > 1) {
      return (currentIndex - 1).clamp(0, items.length - 1);
    }

    return currentIndex.clamp(0, items.length - 1);
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    required this.index,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final int index;

  // Shell index maps to the actual StatefulShellRoute branch index
  int get shellIndex {
    if (route == '/home') return 0;
    if (route == '/search') return 1;
    if (route == '/library') return 2;
    if (route == '/settings') return 3;
    return 0;
  }
}
