import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';

class UserLikedSongs extends StatefulWidget {
  const UserLikedSongs({super.key});

  @override
  State<UserLikedSongs> createState() => _UserLikedSongsState();
}

class _UserLikedSongsState extends State<UserLikedSongs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n()!.userLikedSongs,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Stack(
                  children: [
                    Column(
                      children: [
                        Center(
                          child: buildPlaylistHeader(),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        buildPlayButton(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: currentLikedSongsLength,
                      builder: (_, value, __) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false,
                          itemCount: userLikedSongsList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: SongBar(
                                userLikedSongsList[index],
                                true,
                              ),
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPlaylistHeader() {
    return Column(
      children: [
        _buildPlaylistImage(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            '${context.l10n()!.yourFavoriteSongsHere}!',
            style: const TextStyle(
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: context.screenSize.height * 0.01),
      ],
    );
  }

  Widget _buildPlaylistImage() {
    return Card(
      color: Colors.transparent,
      child: PlaylistCube(
        title: context.l10n()!.userLikedSongs,
        onClickOpen: false,
        showFavoriteButton: false,
        zoomNumber: 0.55,
      ),
    );
  }

  Widget buildPlayButton() {
    return GestureDetector(
      onTap: () {
        setActivePlaylist(
          {
            'ytid': '',
            'title': context.l10n()!.userLikedSongs,
            'header_desc': '',
            'image': '',
            'list': userLikedSongsList
          },
        );
        showToast(
          context,
          context.l10n()!.queueInitText,
        );
      },
      child: Icon(
        FluentIcons.play_circle_48_filled,
        color: colorScheme.primary,
        size: 60,
      ),
    );
  }
}
