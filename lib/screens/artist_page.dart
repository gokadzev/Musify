import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/colorScheme.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/artist_cube.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key, required this.playlist});

  final Map<String, dynamic> playlist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist['title']),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildArtistHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildPlayButton(context),
            ),
            _buildSongsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistHeader() {
    return Column(
      children: <Widget>[
        ArtistCube(playlist['title']),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            playlist['title'].toString(),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setActivePlaylist(playlist);
        showToast(
          context,
          context.l10n!.queueInitText,
        );
      },
      child: Icon(
        FluentIcons.play_circle_48_filled,
        color: context.colorScheme.primary,
        size: 60,
      ),
    );
  }

  Widget _buildSongsList() {
    return FutureBuilder(
      future: fetchSongsList(playlist['title'].toString()),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(35),
              child: Spinner(),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError || snapshot.data.isEmpty) {
            return Center(
              child: Text(
                '${context.l10n!.nothingFound}!',
                style: TextStyle(
                  color: context.colorScheme.primary,
                  fontSize: 18,
                ),
              ),
            );
          }
          playlist['list'] = snapshot.data;
          return _buildSongsListView(snapshot.data);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildSongsListView(List<dynamic> songs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return SongBar(
          songs[index],
          true,
        );
      },
    );
  }
}
