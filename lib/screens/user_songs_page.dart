import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';

class UserSongsPage extends StatefulWidget {
  const UserSongsPage({
    super.key,
    required this.title,
    required this.songList,
    required this.currentSongsLength,
    this.showReorderableListView = false,
  });
  final String title;
  final List songList;
  final ValueListenable<int> currentSongsLength;
  final bool showReorderableListView;

  @override
  State<UserSongsPage> createState() => _UserSongsPageState();
}

class _UserSongsPageState extends State<UserSongsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          buildPlaylistHeader(),
          Expanded(
            child: buildSongList(),
          ),
        ],
      ),
    );
  }

  Widget buildPlaylistHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPlaylistImage(context),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '[ ${widget.songList.length} ${context.l10n!.songs} ]'
                    .toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                ),
              ),
              buildPlayButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistImage(BuildContext context) {
    return PlaylistCube(
      title: widget.title,
      onClickOpen: false,
      showFavoriteButton: false,
      size: context.screenSize.width / 2.2,
      cubeIcon: widget.title == context.l10n!.userOfflineSongs
          ? FluentIcons.cellular_off_24_regular
          : FluentIcons.music_note_1_24_regular,
    );
  }

  Widget buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setActivePlaylist({
          'ytid': '',
          'title': widget.title,
          'header_desc': '',
          'image': '',
          'list': widget.songList,
        });
        showToast(
          context,
          context.l10n!.queueInitText,
        );
      },
      child: Icon(
        FluentIcons.play_circle_48_filled,
        color: Theme.of(context).colorScheme.primary,
        size: 60,
      ),
    );
  }

  Widget buildSongList() {
    return ValueListenableBuilder(
      valueListenable: widget.currentSongsLength,
      builder: (_, value, __) {
        return widget.showReorderableListView
            ? ReorderableListView(
                shrinkWrap: true,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    moveLikedSong(oldIndex, newIndex);
                  });
                },
                children: widget.songList
                    .asMap()
                    .entries
                    .map(
                      (entry) => SongBar(
                        entry.value,
                        true,
                        key: Key(entry.value['ytid'].toString()),
                        songIndexInPlaylist: entry.key,
                      ),
                    )
                    .toList(),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.songList.length,
                itemBuilder: (context, index) {
                  final song = widget.songList[index];
                  song['isOffline'] =
                      widget.title == context.l10n!.userOfflineSongs;
                  return SongBar(song, true);
                },
              );
      },
    );
  }
}
