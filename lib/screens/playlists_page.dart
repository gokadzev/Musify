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
        title: Text(
          context.l10n!.playlists,
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
              future: _searchBar.text.isEmpty
                  ? getPlaylists(type: _showOnlyAlbums ? 'album' : 'playlist')
                  : getPlaylists(
                      query: _searchBar.text,
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
