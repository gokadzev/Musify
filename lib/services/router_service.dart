import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musify/screens/about_page.dart';
import 'package:musify/screens/bottom_navigation_page.dart';
import 'package:musify/screens/home_page.dart';
import 'package:musify/screens/more_page.dart';
import 'package:musify/screens/playlists_page.dart';
import 'package:musify/screens/recently_played_page.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/screens/user_added_playlists_page.dart';
import 'package:musify/screens/user_liked_playlists_page.dart';

class NavigationManager {
  factory NavigationManager() {
    return _instance;
  }

  NavigationManager._internal() {
    final routes = [
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: parentNavigatorKey,
        branches: [
          StatefulShellBranch(
            navigatorKey: homeTabNavigatorKey,
            routes: [
              GoRoute(
                path: homePath,
                pageBuilder: (context, GoRouterState state) {
                  return getPage(
                    child: const HomePage(),
                    state: state,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'playlists',
                    builder: (context, state) => const PlaylistsPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: searchTabNavigatorKey,
            routes: [
              GoRoute(
                path: searchPath,
                pageBuilder: (context, GoRouterState state) {
                  return getPage(
                    child: const SearchPage(),
                    state: state,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: userPlaylistsTabNavigatorKey,
            routes: [
              GoRoute(
                path: userPlaylistsPath,
                pageBuilder: (context, GoRouterState state) {
                  return getPage(
                    child: const UserPlaylistsPage(),
                    state: state,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: moreTabNavigatorKey,
            routes: [
              GoRoute(
                path: morePath,
                pageBuilder: (context, state) {
                  return getPage(
                    child: const MorePage(),
                    state: state,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'recentlyPlayed',
                    builder: (context, state) => const RecentlyPlayedPage(),
                  ),
                  GoRoute(
                    path: 'playlists',
                    builder: (context, state) => const PlaylistsPage(),
                  ),
                  GoRoute(
                    path: 'userLikedPlaylists',
                    builder: (context, state) => const UserLikedPlaylistsPage(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
        pageBuilder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return getPage(
            child: BottomNavigationPage(
              child: navigationShell,
            ),
            state: state,
          );
        },
      ),
    ];

    router = GoRouter(
      navigatorKey: parentNavigatorKey,
      initialLocation: homePath,
      routes: routes,
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
  static final GlobalKey<NavigatorState> userPlaylistsTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> moreTabNavigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext get context =>
      router.routerDelegate.navigatorKey.currentContext!;

  GoRouterDelegate get routerDelegate => router.routerDelegate;

  GoRouteInformationParser get routeInformationParser =>
      router.routeInformationParser;

  static const String homePath = '/home';
  static const String morePath = '/more';
  static const String searchPath = '/search';
  static const String userPlaylistsPath = '/userPlaylists';

  static Page getPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return MaterialPage(
      key: state.pageKey,
      child: child,
    );
  }
}
