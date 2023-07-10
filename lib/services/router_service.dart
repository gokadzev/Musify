import 'package:flutter/material.dart';
import 'package:musify/screens/home_page.dart';
import 'package:musify/screens/more_page.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/screens/user_added_playlists_page.dart';

class RoutePaths {
  static const String home = '/';
  static const String search = '/search';
  static const String userPlaylists = '/userPlaylists';
  static const String more = '/more';
}

final destinations = [
  RoutePaths.home,
  RoutePaths.search,
  RoutePaths.userPlaylists,
  RoutePaths.more
];

// ignore: avoid_classes_with_only_static_members
class RouterService {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutePaths.home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case RoutePaths.search:
        return MaterialPageRoute(builder: (_) => SearchPage());
      case RoutePaths.userPlaylists:
        return MaterialPageRoute(builder: (_) => UserPlaylistsPage());
      case RoutePaths.more:
        return MaterialPageRoute(builder: (_) => MorePage());
      default:
        throw Exception('Invalid route: ${settings.name}');
    }
  }
}
