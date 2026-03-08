/*
 *     Copyright (C) 2026 Valeri Gokadze
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/constants/version.dart';
import 'package:musify/screens/about_page.dart';
import 'package:musify/screens/bottom_navigation_page.dart';
import 'package:musify/screens/equalizer_page.dart';
import 'package:musify/screens/home_page.dart';
import 'package:musify/screens/library_page.dart';
import 'package:musify/screens/playlist_folder_page.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/screens/settings_page.dart';
import 'package:musify/screens/user_songs_page.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/widgets/offline_search_placeholder.dart';

class NavigationManager {
  factory NavigationManager() {
    return _instance;
  }

  NavigationManager._internal() {
    _setupRouter();
  }

  void _setupRouter() {
    final routes = [
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: parentNavigatorKey,
        branches: _getRouteBranches(),
        pageBuilder: (context, state, navigationShell) {
          return getPage(
            child: BottomNavigationPage(child: navigationShell),
            state: state,
          );
        },
      ),
    ];

    router = GoRouter(
      navigatorKey: parentNavigatorKey,
      initialLocation: homePath,
      routes: routes,
      restorationScopeId: 'router',
      debugLogDiagnostics: kDebugMode,
      routerNeglect: true,
      redirect: (context, state) {
        // Handle offline mode redirects
        final isOffline = offlineMode.value;
        final currentPath = state.matchedLocation;

        if (isOffline && currentPath == searchPath) {
          // Redirect search to home in offline mode
          return homePath;
        }

        return null; // No redirect needed
      },
    );
  }

  static final NavigationManager _instance = NavigationManager._internal();

  static NavigationManager get instance => _instance;

  static late final GoRouter router;

  static final GlobalKey<NavigatorState> parentNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> homeTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> searchTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> libraryTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> settingsTabNavigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext get context {
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) {
      throw StateError(
        'NavigationManager.context was accessed before the navigator context was available.',
      );
    }
    return ctx;
  }

  GoRouterDelegate get routerDelegate => router.routerDelegate;

  GoRouteInformationParser get routeInformationParser =>
      router.routeInformationParser;

  static const String homePath = '/home';
  static const String settingsPath = '/settings';
  static const String searchPath = '/search';
  static const String libraryPath = '/library';

  /// Refresh the router configuration when offline mode changes
  static void refreshRouter() {
    // Force router to re-evaluate redirect logic
    router.refresh();
  }

  List<StatefulShellBranch> _getRouteBranches() {
    // Always return all branches, but handle visibility in the UI
    return [
      // Branch 0: Home
      StatefulShellBranch(
        navigatorKey: homeTabNavigatorKey,
        routes: [
          GoRoute(
            path: homePath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(
                child: ValueListenableBuilder<bool>(
                  valueListenable: offlineMode,
                  builder: (context, isOffline, _) {
                    return isOffline
                        ? const UserSongsPage(page: 'offline')
                        : const HomePage();
                  },
                ),
                state: state,
              );
            },
            routes: [
              GoRoute(
                path: 'library',
                pageBuilder: (context, state) =>
                    _pushPage(child: const LibraryPage(), state: state),
              ),
              GoRoute(
                path: 'playlist/:playlistId',
                pageBuilder: (context, state) => _pushPage(
                  child: PlaylistPage(
                    playlistId: state.pathParameters['playlistId'],
                  ),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'folder/:folderId/:folderName',
                pageBuilder: (context, state) => _pushPage(
                  child: PlaylistFolderPage(
                    folderId: state.pathParameters['folderId'] ?? '',
                    folderName: state.pathParameters['folderName'] ?? '',
                  ),
                  state: state,
                ),
              ),
            ],
          ),
        ],
      ),
      // Branch 1: Search
      StatefulShellBranch(
        navigatorKey: searchTabNavigatorKey,
        routes: [
          GoRoute(
            path: searchPath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(
                child: ValueListenableBuilder<bool>(
                  valueListenable: offlineMode,
                  builder: (context, isOffline, _) {
                    return isOffline
                        ? const OfflineSearchPlaceholder()
                        : const SearchPage();
                  },
                ),
                state: state,
              );
            },
          ),
        ],
      ),
      // Branch 2: Library
      StatefulShellBranch(
        navigatorKey: libraryTabNavigatorKey,
        routes: [
          GoRoute(
            path: libraryPath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(child: const LibraryPage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'userSongs/:page',
                pageBuilder: (context, state) => _pushPage(
                  child: UserSongsPage(
                    page: state.pathParameters['page'] ?? 'liked',
                  ),
                  state: state,
                ),
              ),
            ],
          ),
        ],
      ),
      // Branch 3: Settings
      StatefulShellBranch(
        navigatorKey: settingsTabNavigatorKey,
        routes: [
          GoRoute(
            path: settingsPath,
            pageBuilder: (context, state) {
              return getPage(child: const SettingsPage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'license',
                pageBuilder: (context, state) => _pushPage(
                  child: const LicensePage(
                    applicationName: 'Musify',
                    applicationVersion: appVersion,
                  ),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'about',
                pageBuilder: (context, state) =>
                    _pushPage(child: const AboutPage(), state: state),
              ),
              GoRoute(
                path: 'equalizer',
                pageBuilder: (context, state) =>
                    _pushPage(child: const EqualizerPage(), state: state),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static Page<void> getPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        );
      },
    );
  }

  static Page<void> _pushPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
