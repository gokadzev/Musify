import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/delayed_display.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appTheme.dart';
import 'package:musify/ui/playlistPage.dart';

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
            color: accent,
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
                            child: Text(
                              AppLocalizations.of(context)!.suggestedPlaylists,
                              style: TextStyle(
                                color: accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
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
                                  child: CubeContainer(
                                    id: (data as dynamic)
                                        .data[index]['ytid']
                                        .toString(),
                                    image: (data as dynamic)
                                        .data[index]['image']
                                        .toString(),
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
                      style: TextStyle(color: accent, fontSize: 18),
                    ),
                  );
                }
                if (!data.hasData) {
                  return Center(
                    child: Text(
                      'Nothing Found!',
                      style: TextStyle(color: accent, fontSize: 18),
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
                          color: accent,
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
                          return SongBar(
                            (data as dynamic).data[index],
                            false,
                          );
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

class CubeContainer extends StatelessWidget {
  const CubeContainer({
    required this.id,
    required this.image,
  });
  final String id;
  final String image;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return DelayedDisplay(
      delay: const Duration(milliseconds: 200),
      fadingDuration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () {
          getPlaylistInfoForWidget(id).then(
            (value) => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(playlist: value),
                ),
              )
            },
          );
        },
        child: Column(
          children: [
            SizedBox(
              height: size.height / 4.15,
              width: size.width / 1.9,
              child: Card(
                color: Colors.transparent,
                child: CachedNetworkImage(
                  imageUrl: image,
                  imageBuilder: (context, imageProvider) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(30, 255, 255, 255),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          MdiIcons.musicNoteOutline,
                          size: 30,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
