import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/colorScheme.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';

class UserOfflineSongsPage extends StatefulWidget {
  const UserOfflineSongsPage({super.key});

  @override
  State<UserOfflineSongsPage> createState() => _UserOfflineSongsPageState();
}

class _UserOfflineSongsPageState extends State<UserOfflineSongsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.userOfflineSongs),
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
              context.l10n!.userOfflineSongs,
              style: const TextStyle(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 10),
            buildPlayButton(context.colorScheme.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaylistImage() {
    return PlaylistCube(
      title: context.l10n!.userOfflineSongs,
      onClickOpen: false,
      showFavoriteButton: false,
      size: 150,
      zoomNumber: 0.55,
      cubeIcon: FluentIcons.cellular_off_24_regular,
    );
  }

  Widget buildPlayButton(Color iconColor) {
    return GestureDetector(
      onTap: () {
        setActivePlaylist(
          {
            'ytid': '',
            'title': context.l10n!.userOfflineSongs,
            'header_desc': '',
            'image': '',
            'list': userOfflineSongs,
          },
        );
        showToast(
          context,
          context.l10n!.queueInitText,
        );
      },
      child: Icon(
        FluentIcons.play_circle_48_filled,
        color: iconColor,
        size: 60,
      ),
    );
  }

  Widget buildSongList() {
    return ValueListenableBuilder(
      valueListenable: currentOfflineSongsLength,
      builder: (_, value, __) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: userOfflineSongs.length,
          itemBuilder: (context, index) {
            final _song = userOfflineSongs[index];
            _song['isOffline'] = true;
            return SongBar(
              _song,
              true,
            );
          },
        );
      },
    );
  }
}
