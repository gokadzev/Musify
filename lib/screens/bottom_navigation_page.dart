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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({required this.child, super.key});

  final StatefulNavigationShell child;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  bool? _previousOfflineMode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: offlineMode,
      builder: (context, isOfflineMode, _) {
        // Handle offline mode changes
        if (_previousOfflineMode != null &&
            _previousOfflineMode != isOfflineMode) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _handleOfflineModeChange(isOfflineMode);
          });
        }
        _previousOfflineMode = isOfflineMode;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = MediaQuery.of(context).size.width >= 600;
            final items = _getNavigationItems(isOfflineMode);

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
                                    selectedIcon: Icon(item.selectedIcon),
                                    label: Text(item.label),
                                  ),
                                )
                                .toList(),
                        selectedIndex: _getCurrentIndex(items, isOfflineMode),
                        onDestinationSelected:
                            (index) => _onTabTapped(index, items),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: widget.child),
                          const MiniPlayer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar:
                  !isLargeScreen
                      ? NavigationBar(
                        selectedIndex: _getCurrentIndex(items, isOfflineMode),
                        labelBehavior:
                            languageSetting == const Locale('en', '')
                                ? NavigationDestinationLabelBehavior
                                    .onlyShowSelected
                                : NavigationDestinationLabelBehavior.alwaysHide,
                        onDestinationSelected:
                            (index) => _onTabTapped(index, items),
                        destinations:
                            items
                                .map(
                                  (item) => NavigationDestination(
                                    icon: Icon(item.icon),
                                    selectedIcon: Icon(item.selectedIcon),
                                    label: item.label,
                                  ),
                                )
                                .toList(),
                      )
                      : null,
            );
          },
        );
      },
    );
  }

  List<_NavigationItem> _getNavigationItems(bool isOfflineMode) {
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
    if (!isOfflineMode) {
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
    final libraryIndex = isOfflineMode ? 1 : 2;
    final settingsIndex = isOfflineMode ? 2 : 3;

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

  void _handleOfflineModeChange(bool isOfflineMode) {
    if (!mounted) return;

    final currentRoute = GoRouterState.of(context).matchedLocation;

    // If we're switching to offline mode and currently on search tab
    if (isOfflineMode && currentRoute.startsWith('/search')) {
      // Navigate to home
      widget.child.goBranch(0);
    }
  }

  void _onTabTapped(int index, List<_NavigationItem> items) {
    if (index < items.length) {
      final item = items[index];
      // Use the shell navigation index instead of the route
      widget.child.goBranch(item.shellIndex);
    }
  }

  int _getCurrentIndex(List<_NavigationItem> items, bool isOfflineMode) {
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
    if (isOfflineMode && currentIndex == 1) {
      return 0; // Search -> Home
    }

    if (isOfflineMode && currentIndex > 1) {
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
