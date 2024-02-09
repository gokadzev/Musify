import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
    required this.page,
  });

  final String page;

  @override
  State<UserSongsPage> createState() => _UserSongsPageState();
}

class _UserSongsPageState extends State<UserSongsPage> {
  @override
  Widget build(BuildContext context) {
    final title = getTitle(widget.page, context);
    final icon = getIcon(widget.page);
    final songsList = getSongsList(widget.page);
    final length = getLength(widget.page);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          buildPlaylistHeader(title, icon, songsList),
          Expanded(
            child: buildSongList(title, songsList, length),
          ),
        ],
      ),
    );
  }

  String getTitle(String page, BuildContext context) {
    return {
          'liked': context.l10n!.userLikedSongs,
          'offline': context.l10n!.userOfflineSongs,
        }[page] ??
        context.l10n!.playlist;
  }

  IconData getIcon(String page) {
    return {
          'liked': FluentIcons.heart_24_regular,
          'offline': FluentIcons.cellular_off_24_regular,
        }[page] ??
        FluentIcons.heart_24_regular;
  }

  List getSongsList(String page) {
    return {
          'liked': userLikedSongsList,
          'offline': userOfflineSongs,
        }[page] ??
        userLikedSongsList;
  }

  ValueNotifier getLength(String page) {
    return {
          'liked': currentLikedSongsLength,
          'offline': currentOfflineSongsLength,
        }[page] ??
        currentLikedSongsLength;
  }

  Widget buildPlaylistHeader(String title, IconData icon, List songsList) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPlaylistImage(title, icon),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              title,
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
                '[ ${songsList.length} ${context.l10n!.songs} ]'.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                ),
              ),
              buildPlayButton(title, songsList),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistImage(String title, IconData icon) {
    return PlaylistCube(
      title: title,
      onClickOpen: false,
      showFavoriteButton: false,
      size: context.screenSize.width / 2.2,
      cubeIcon: icon,
    );
  }

  Widget buildPlayButton(String title, List songList) {
    return GestureDetector(
      onTap: () {
        setActivePlaylist({
          'ytid': '',
          'title': title,
          'header_desc': '',
          'image': '',
          'list': songList,
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

  Widget buildSongList(
    String title,
    List songList,
    ValueNotifier currentSongsLength,
  ) {
    return ValueListenableBuilder(
      valueListenable: currentSongsLength,
      builder: (_, value, __) {
        if (title == context.l10n!.userLikedSongs) {
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
            children: songList
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
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: songList.length,
            itemBuilder: (context, index) {
              final song = songList[index];
              song['isOffline'] = title == context.l10n!.userOfflineSongs;
              return SongBar(song, true);
            },
          );
        }
      },
    );
  }
}
