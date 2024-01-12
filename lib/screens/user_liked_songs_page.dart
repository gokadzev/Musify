import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';

class UserLikedSongsPage extends StatefulWidget {
  const UserLikedSongsPage({super.key});

  @override
  State<UserLikedSongsPage> createState() => _UserLikedSongsPageState();
}

class _UserLikedSongsPageState extends State<UserLikedSongsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.userLikedSongs),
      ),
      body: Column(
        children: [
          buildPlaylistHeader(),
          const SizedBox(height: 30),
          Expanded(
            child: buildSongList(),
          ),
        ],
      ),
    );
  }

  Widget buildPlaylistHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlaylistImage(),
        const SizedBox(width: 20),
        Column(
          children: [
            Text(
              context.l10n!.yourFavoriteSongsHere,
              style: const TextStyle(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 10),
            buildPlayButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaylistImage() {
    return PlaylistCube(
      title: context.l10n!.userLikedSongs,
      onClickOpen: false,
      showFavoriteButton: false,
      size: 150,
      zoomNumber: 0.55,
    );
  }

  Widget buildPlayButton() {
    return GestureDetector(
      onTap: () {
        setActivePlaylist(
          {
            'ytid': '',
            'title': context.l10n!.userLikedSongs,
            'header_desc': '',
            'image': '',
            'list': userLikedSongsList,
          },
        );
        showToast(
          context,
          context.l10n!.queueInitText,
        );
      },
      child: Icon(
        FluentIcons.play_circle_48_filled,
        color: colorScheme.primary,
        size: 60,
      ),
    );
  }

  Widget buildSongList() {
    return ValueListenableBuilder(
      valueListenable: currentLikedSongsLength,
      builder: (_, value, __) {
        return ReorderableListView(
          shrinkWrap: true,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              moveLikedSong(oldIndex, newIndex);
            });
          },
          children: userLikedSongsList
              .asMap()
              .entries
              .map(
                (entry) => SongBar(
                  entry.value,
                  true,
                  key: Key(entry.value['ytid']),
                  songIndexInPlaylist: entry.key,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
