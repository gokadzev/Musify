import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/colorScheme.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/playlist_page.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/services/update_manager.dart';
import 'package:musify/widgets/artist_cube.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    if (!isFdroidBuild) {
      checkAppUpdates(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Musify.',
          style: GoogleFonts.paytoneOne(color: context.colorScheme.primary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildSuggestedPlaylists(),
            _buildRecommendedSongsAndArtists(),
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
              color: context.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          height: context.screenSize.height * 0.25,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemCount: _suggestedPlaylists.length,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemBuilder: (context, index) {
              final playlist = _suggestedPlaylists[index];
              return PlaylistCube(
                id: playlist['ytid'],
                image: playlist['image'].toString(),
                title: playlist['title'].toString(),
                isAlbum: playlist['isAlbum'],
                size: context.screenSize.height * 0.25,
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
        final calculatedSize = context.screenSize.height * 0.25;
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
          color: context.colorScheme.primary,
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
                  final result = await fetchSongsList(artist);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistPage(
                        cubeIcon: FluentIcons.mic_sparkle_24_regular,
                        playlistData: {
                          'title': artist,
                          'list': result,
                        },
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
              color: context.colorScheme.primary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: data.length,
          itemBuilder: (context, index) {
            return SongBar(data[index], true);
          },
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
            width: context.screenSize.width / 1.4,
            child: MarqueeWidget(
              child: Text(
                title,
                style: TextStyle(
                  color: context.colorScheme.primary,
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
