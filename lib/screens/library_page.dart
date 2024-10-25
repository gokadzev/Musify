/*
 *     Copyright (C) 2024 Valeri Gokadze
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
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/widgets/custom_search_bar.dart';
import 'package:musify/widgets/playlist_bar.dart';
import 'package:musify/widgets/section_title.dart';
import 'package:musify/widgets/spinner.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  bool _showOnlyAlbums = false;

  void toggleShowOnlyAlbums(bool value) {
    setState(() {
      _showOnlyAlbums = value;
    });
  }

  @override
  void dispose() {
    _searchBar.dispose();
    _inputNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.library),
      ),
      body: Column(
        children: <Widget>[
          CustomSearchBar(
            onSubmitted: (String value) {
              setState(() {});
            },
            controller: _searchBar,
            focusNode: _inputNode,
            labelText: '${context.l10n!.search}...',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Switch(
                  value: _showOnlyAlbums,
                  onChanged: toggleShowOnlyAlbums,
                  thumbIcon: WidgetStateProperty.resolveWith<Icon>(
                    (Set<WidgetState> states) {
                      return Icon(
                        states.contains(WidgetState.selected)
                            ? Icons.album
                            : Icons.featured_play_list,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SectionTitle(context.l10n!.userPlaylists, primaryColor),
                  Column(
                    children: <Widget>[
                      PlaylistBar(
                        context.l10n!.recentlyPlayed,
                        onPressed: () => NavigationManager.router
                            .go('/playlists/userSongs/recents'),
                        cubeIcon: FluentIcons.history_24_filled,
                      ),
                      PlaylistBar(
                        context.l10n!.likedSongs,
                        onPressed: () => NavigationManager.router
                            .go('/playlists/userSongs/liked'),
                        cubeIcon: FluentIcons.music_note_2_24_regular,
                      ),
                      PlaylistBar(
                        context.l10n!.likedPlaylists,
                        onPressed: () => NavigationManager.router
                            .go('/playlists/userLikedPlaylists'),
                        cubeIcon: FluentIcons.task_list_ltr_24_regular,
                      ),
                      PlaylistBar(
                        context.l10n!.offlineSongs,
                        onPressed: () => NavigationManager.router
                            .go('/playlists/userSongs/offline'),
                        cubeIcon: FluentIcons.cellular_off_24_filled,
                      ),
                    ],
                  ),
                  SectionTitle(context.l10n!.playlists, primaryColor),
                  FutureBuilder(
                    future: getPlaylists(
                      query: _searchBar.text.isEmpty ? null : _searchBar.text,
                      type: _showOnlyAlbums ? 'album' : 'playlist',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Spinner();
                      } else if (snapshot.hasError) {
                        logger.log(
                          'Error on playlists page',
                          snapshot.error,
                          snapshot.stackTrace,
                        );
                        return Center(
                          child: Text(context.l10n!.error),
                        );
                      }

                      final _playlists = snapshot.data as List;

                      return ListView.builder(
                        shrinkWrap:
                            true, // Allows ListView to fit within SingleChildScrollView
                        physics:
                            const NeverScrollableScrollPhysics(), // Disable ListView scrolling
                        itemCount: _playlists.length,
                        itemBuilder: (BuildContext context, index) {
                          final playlist = _playlists[index];

                          return PlaylistBar(
                            playlist['title'],
                            playlistId: playlist['ytid'],
                            playlistArtwork: playlist['image'],
                            isAlbum: playlist['isAlbum'],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
