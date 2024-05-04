/*
 *     Copyright (C) 2024 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/widgets/artist_cube.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_cube.dart';
import 'package:musify/widgets/spinner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Musify.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontFamily: 'paytoneOne',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildTopNavBar(),
            _buildSuggestedPlaylists(),
            _buildRecommendedSongsAndArtists(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(
                    playlistData: {
                      'title': context.l10n!.recentlyPlayed,
                      'list': userRecentlyPlayed,
                    },
                  ),
                ),
              ),
              icon: const Icon(FluentIcons.history_24_filled),
              label: Text(context.l10n!.recentlyPlayed),
            ),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: () => NavigationManager.router.go(
                '/home/playlists',
              ),
              icon: const Icon(FluentIcons.list_24_filled),
              label: Text(context.l10n!.playlists),
            ),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: () => NavigationManager.router.go(
                '/home/userSongs/liked',
              ),
              icon: const Icon(FluentIcons.heart_24_filled),
              label: Text(context.l10n!.likedSongs),
            ),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: () => NavigationManager.router.go(
                '/home/userSongs/offline',
              ),
              icon: const Icon(FluentIcons.cellular_off_24_filled),
              label: Text(context.l10n!.offlineSongs),
            ),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: () => NavigationManager.router.go(
                '/home/userLikedPlaylists',
              ),
              icon: const Icon(
                FluentIcons.star_24_filled,
              ),
              label: Text(context.l10n!.likedPlaylists),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists() {
    return FutureBuilder(
      future: getPlaylists(playlistsNum: 5),
      builder: _buildSuggestedPlaylistsWidget,
    );
  }

  Widget _buildSuggestedPlaylistsWidget(
    BuildContext context,
    AsyncSnapshot<List<dynamic>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingWidget();
    } else if (snapshot.hasError) {
      logger.log(
        'Error in _buildSuggestedPlaylistsWidget',
        snapshot.error,
        snapshot.stackTrace,
      );
      return _buildErrorWidget(context);
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const SizedBox.shrink();
    }

    final _suggestedPlaylists = snapshot.data!;
    final calculatedSize = MediaQuery.of(context).size.height * 0.25;
    final _suggestedPlaylistsSize = calculatedSize / 1.1;

    return Column(
      children: [
        _buildSectionHeader(
          context.l10n!.suggestedPlaylists,
          IconButton(
            onPressed: () {
              NavigationManager.router.go(
                '/home/playlists',
              );
            },
            icon: Icon(
              FluentIcons.more_horizontal_24_regular,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          height: _suggestedPlaylistsSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemCount: _suggestedPlaylists.length,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemBuilder: (context, index) {
              final playlist = _suggestedPlaylists[index];
              return PlaylistCube(
                id: playlist['ytid'],
                image: playlist['image'],
                title: playlist['title'],
                isAlbum: playlist['isAlbum'],
                size: _suggestedPlaylistsSize,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSongsAndArtists() {
    return FutureBuilder(
      future: getRecommendedSongs(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        final calculatedSize = MediaQuery.of(context).size.height * 0.25;
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return _buildLoadingWidget();
          case ConnectionState.done:
            if (snapshot.hasError) {
              logger.log(
                'Error in _buildRecommendedSongsAndArtists',
                snapshot.error,
                snapshot.stackTrace,
              );
              return _buildErrorWidget(context);
            }
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            return _buildRecommendedContent(
              context,
              snapshot.data,
              calculatedSize,
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(35),
        child: Spinner(),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Text(
        '${context.l10n!.error}!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildRecommendedContent(
    BuildContext context,
    List<dynamic> data,
    double calculatedSize,
  ) {
    return Column(
      children: <Widget>[
        _buildSectionHeader(context.l10n!.suggestedArtists),
        SizedBox(
          height: calculatedSize,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemCount: 5,
            itemBuilder: (context, index) {
              final artist = data[index]['artist'].split('~')[0];
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistPage(
                        cubeIcon: FluentIcons.mic_sparkle_24_regular,
                        playlistId: artist,
                        isArtist: true,
                      ),
                    ),
                  );
                },
                child: ArtistCube(artist),
              );
            },
          ),
        ),
        _buildSectionHeader(
          context.l10n!.recommendedForYou,
          IconButton(
            onPressed: () {
              setActivePlaylist({
                'title': context.l10n!.recommendedForYou,
                'list': data,
              });
            },
            iconSize: 30,
            icon: Icon(
              FluentIcons.play_circle_24_filled,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          height: calculatedSize + 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemCount: data.length,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemBuilder: (context, index) {
              return SongCube(
                data[index],
                size: calculatedSize / 1.1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, [IconButton? actionButton]) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.4,
            child: MarqueeWidget(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (actionButton != null) actionButton,
        ],
      ),
    );
  }
}
