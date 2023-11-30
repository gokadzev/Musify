import 'package:flutter/material.dart';
import 'package:musify/screens/home_page.dart';
import 'package:musify/screens/more_page.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/screens/user_added_playlists_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (_) => HomePage(),
  '/search': (_) => SearchPage(),
  '/userPlaylists': (_) => UserPlaylistsPage(),
  '/more': (_) => MorePage(),
};

final destinations = routes.keys.toList();

Route<dynamic> generateRoute(RouteSettings settings) {
  final builder = routes[settings.name] ??
      (_) => throw Exception('Invalid route: ${settings.name}');
  return MaterialPageRoute(builder: builder);
}
