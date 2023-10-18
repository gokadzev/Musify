import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/playlist_cube.dart';

class UserLikedPlaylistsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n()!.userLikedPlaylists,
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: currentLikedPlaylistsLength,
        builder: (_, value, __) {
          return userLikedPlaylists.isEmpty
              ? Center(
                  child: Text(
                    context.l10n()!.noLikedPlaylists,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: GridView.builder(
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
                    itemCount: userLikedPlaylists.length,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemBuilder: (BuildContext context, index) {
                      return Center(
                        child: PlaylistCube(
                          id: userLikedPlaylists[index]['ytid'],
                          image: userLikedPlaylists[index]['image'],
                          title: userLikedPlaylists[index]['title'].toString(),
                        ),
                      );
                    },
                  ),
                );
        },
      ),
    );
  }
}
