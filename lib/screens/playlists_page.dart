import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/spinner.dart';

class PlaylistsPage extends StatefulWidget {
  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  String _searchQuery = '';

  Future<void> search() async {
    _searchQuery = _searchBar.text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n()!.playlists,
          style: paytoneOneStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 20,
                left: 12,
                right: 12,
              ),
              child: TextField(
                onSubmitted: (String value) {
                  search();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                textInputAction: TextInputAction.search,
                controller: _searchBar,
                focusNode: _inputNode,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.primary,
                ),
                cursorColor: Colors.green[50],
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(15),
                    ),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      FluentIcons.search_24_regular,
                      color: colorScheme.primary,
                    ),
                    color: colorScheme.primary,
                    onPressed: () {
                      search();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  hintText: '${context.l10n()!.search}...',
                  hintStyle: TextStyle(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            FutureBuilder(
              future: _searchQuery.isEmpty
                  ? getPlaylists()
                  : getPlaylists(query: _searchQuery),
              builder: (context, data) {
                return (data as dynamic).data != null
                    ? GridView.builder(
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: false,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        shrinkWrap: true,
                        physics: const ScrollPhysics(),
                        itemCount: (data as dynamic).data.length as int,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 20,
                        ),
                        itemBuilder: (BuildContext context, index) {
                          return Center(
                            child: PlaylistCube(
                              id: (data as dynamic).data[index]['ytid'],
                              image: (data as dynamic).data[index]['image'],
                              title: (data as dynamic)
                                  .data[index]['title']
                                  .toString(),
                            ),
                          );
                        },
                      )
                    : const Spinner();
              },
            )
          ],
        ),
      ),
    );
  }
}
