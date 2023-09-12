import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/screens/artist_page.dart';
import 'package:musify/screens/playlists_page.dart';
import 'package:musify/services/offline_audio.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/widgets/artist_cube.dart';
import 'package:musify/widgets/delayed_display.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomePage extends StatefulWidget {
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
          style: GoogleFonts.paytoneOne(color: colorScheme.primary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FutureBuilder(
              future: getPlaylists(playlistsNum: 5),
              builder: (context, AsyncSnapshot<List<dynamic>> data) {
                return data.hasData
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 16,
                              bottom: 10,
                              left: 20,
                              right: 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: context.screenSize.width / 1.4,
                                  child: MarqueeWidget(
                                    child: Text(
                                      context.l10n()!.suggestedPlaylists,
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlaylistsPage(),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    FluentIcons.more_horizontal_24_regular,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: context.screenSize.height * 0.25,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 15),
                              itemCount: data.data!.length,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              itemBuilder: (context, index) {
                                final playlist = data.data![index];
                                return PlaylistCube(
                                  id: playlist['ytid'],
                                  image: playlist['image'].toString(),
                                  title: playlist['title'].toString(),
                                  size: context.screenSize.height * 0.25,
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(35),
                          child: Spinner(),
                        ),
                      );
              },
            ),
            FutureBuilder(
              future: getRandomArtists(),
              builder: (context, AsyncSnapshot<List<ArtistModel>> data) {
                final calculatedSize = context.screenSize.height * 0.25;

                if (data.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: Spinner(),
                    ),
                  );
                } else if (data.hasData && data.data!.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          bottom: 10,
                          left: 20,
                          right: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: context.screenSize.width / 1.4,
                              child: MarqueeWidget(
                                child: Text(
                                  context.l10n()!.suggestedArtists,
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: calculatedSize,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 15),
                          itemCount: data.data!.length,
                          itemBuilder: (context, index) {
                            final artist =
                                data.data![index].artist.split('~')[0];
                            return DelayedDisplay(
                              delay: const Duration(milliseconds: 200),
                              fadingDuration: const Duration(milliseconds: 400),
                              child: GestureDetector(
                                onTap: () {
                                  getMusic(searchQuery: artist).then((songs) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ArtistPage(
                                          playlist: {
                                            'title': artist,
                                            'list': songs,
                                          },
                                        ),
                                      ),
                                    );
                                  });
                                },
                                child: ArtistCube(artist),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            FutureBuilder(
              future: getRecommendedSongs(),
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),
                        child: Spinner(),
                      ),
                    );
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error!',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return Wrap(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                            top: context.screenSize.height / 55,
                            bottom: 10,
                            left: 20,
                            right: 20,
                          ),
                          child: Text(
                            context.l10n()!.recommendedForYou,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false,
                          physics: const BouncingScrollPhysics(),
                          itemCount: snapshot.data.length as int,
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            return SongBar(snapshot.data[index], true);
                          },
                        ),
                      ],
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
