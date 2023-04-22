import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/screens/artist_page.dart';
import 'package:musify/screens/playlists_page.dart';
import 'package:musify/services/offline_audio.dart';
import 'package:musify/style/app_themes.dart';
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
        title: const Text(
          'Musify.',
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
                                  width:
                                      MediaQuery.of(context).size.width / 1.4,
                                  child: MarqueeWidget(
                                    direction: Axis.horizontal,
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .suggestedPlaylists,
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
                            height: MediaQuery.of(context).size.height * 0.25,
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
              future: getArtists(),
              builder: (context, AsyncSnapshot<List<ArtistModel>> data) {
                final calculatedSize =
                    MediaQuery.of(context).size.height * 0.25;
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
                                  width:
                                      MediaQuery.of(context).size.width / 1.4,
                                  child: MarqueeWidget(
                                    direction: Axis.horizontal,
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .suggestedArtists,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              scrollDirection: Axis.horizontal,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 15),
                              itemCount: 10,
                              itemBuilder: (context, index) {
                                final artist = data.data![index].artist;
                                return DelayedDisplay(
                                  delay: const Duration(milliseconds: 200),
                                  fadingDuration:
                                      const Duration(milliseconds: 400),
                                  child: GestureDetector(
                                    onTap: () {
                                      getMusic(
                                        searchQuery: artist.split('~')[0],
                                      ).then(
                                        (songs) => {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ArtistPage(
                                                playlist: {
                                                  'ytid': '',
                                                  'title': artist,
                                                  'header_desc': '',
                                                  'image': '',
                                                  'list': songs,
                                                },
                                              ),
                                            ),
                                          )
                                        },
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(150),
                                      child: Container(
                                        height: calculatedSize,
                                        width: calculatedSize,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: colorScheme.secondary,
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              const Icon(
                                                FluentIcons.person_24_regular,
                                                size: 30,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Text(
                                                  artist,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
              future: get10Music('PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx'),
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
                      return Center(
                        child: Text(
                          'Nothing Found!',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      );
                    }
                    return Wrap(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height / 55,
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
                        )
                      ],
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
