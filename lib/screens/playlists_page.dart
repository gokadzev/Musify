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

import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/widgets/custom_search_bar.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/spinner.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.playlists),
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
                  thumbIcon: MaterialStateProperty.resolveWith<Icon>(
                    (Set<MaterialState> states) {
                      return Icon(
                        states.contains(MaterialState.selected)
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
            child: FutureBuilder(
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

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: _playlists.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (BuildContext context, index) {
                    final playlist = _playlists[index];

                    return PlaylistCube(
                      id: playlist['ytid'],
                      image: playlist['image'],
                      title: playlist['title'],
                      isAlbum: playlist['isAlbum'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
