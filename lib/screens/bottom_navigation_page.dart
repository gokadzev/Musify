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
  final _selectedIndex = ValueNotifier<int>(0);

  List<NavigationDestination> _getNavigationDestinations(BuildContext context) {
    return !offlineMode.value
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
            label: context.l10n?.library ?? 'Library',
          ),
          NavigationDestination(
            icon: const Icon(FluentIcons.settings_24_regular),
            selectedIcon: const Icon(FluentIcons.settings_24_filled),
            label: context.l10n?.settings ?? 'Settings',
          ),
        ]
        : [
          NavigationDestination(
            icon: const Icon(FluentIcons.home_24_regular),
            selectedIcon: const Icon(FluentIcons.home_24_filled),
            label: context.l10n?.home ?? 'Home',
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
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
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
                      _getNavigationDestinations(context)
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: destination.icon,
                              selectedIcon: destination.selectedIcon,
                              label: Text(destination.label),
                            ),
                          )
                          .toList(),
                  selectedIndex: _selectedIndex.value,
                  onDestinationSelected: (index) {
                    widget.child.goBranch(
                      index,
                      initialLocation: index == widget.child.currentIndex,
                    );
                    setState(() {
                      _selectedIndex.value = index;
                    });
                  },
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
                    selectedIndex: _selectedIndex.value,
                    labelBehavior:
                        languageSetting == const Locale('en', '')
                            ? NavigationDestinationLabelBehavior
                                .onlyShowSelected
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
                    destinations: _getNavigationDestinations(context),
                  )
                  : null,
        );
      },
    );
  }
}
