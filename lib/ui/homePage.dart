import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/marque.dart';
import 'package:musify/customWidgets/playlist_cube.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appTheme.dart';
import 'package:musify/ui/playlistsPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Musify.',
          style: TextStyle(
            color: accent.primary,
            fontSize: 35,
            fontWeight: FontWeight.w800,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FutureBuilder(
              future: getPlaylists(5),
              builder: (context, data) {
                return data.hasData
                    ? Wrap(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height / 55,
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
                                        color: accent.primary,
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
                                    color: accent.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (data as dynamic).data.length as int,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  child: SizedBox(
                                    width: 230,
                                    height: 230,
                                    child: PlaylistCube(
                                      id: (data as dynamic).data[index]['ytid'],
                                      image: (data as dynamic)
                                          .data[index]['image']
                                          .toString(),
                                      title: (data as dynamic)
                                          .data[index]['title']
                                          .toString(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
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
              builder: (context, data) {
                if (data.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: Spinner(),
                    ),
                  );
                }
                if (data.hasError) {
                  return Center(
                    child: Text(
                      'Error!',
                      style: TextStyle(color: accent.primary, fontSize: 18),
                    ),
                  );
                }
                if (!data.hasData) {
                  return Center(
                    child: Text(
                      'Nothing Found!',
                      style: TextStyle(color: accent.primary, fontSize: 18),
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
                        AppLocalizations.of(context)!.recommendedForYou,
                        style: TextStyle(
                          color: accent.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: false,
                        physics: const BouncingScrollPhysics(),
                        itemCount: (data as dynamic).data.length as int,
                        itemBuilder: (context, index) {
                          return SongBar((data as dynamic).data[index], true);
                        },
                      ),
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
