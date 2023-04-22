import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/widgets/playlist_cube.dart';

class UserLikedPlaylistsPage extends StatefulWidget {
  @override
  _UserLikedPlaylistsPageState createState() => _UserLikedPlaylistsPageState();
}

class _UserLikedPlaylistsPageState extends State<UserLikedPlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n()!.userLikedPlaylists,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ValueListenableBuilder(
              valueListenable: currentLikedPlaylistsLength,
              builder: (_, value, __) {
                return GridView.builder(
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemCount: userLikedPlaylists.length,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 20,
                  ),
                  itemBuilder: (BuildContext context, index) {
                    return Center(
                      child: PlaylistCube(
                        id: userLikedPlaylists[index]['ytid'],
                        image: userLikedPlaylists[index]['image'],
                        title: userLikedPlaylists[index]['title'].toString(),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
