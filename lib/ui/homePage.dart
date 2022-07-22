import 'package:cached_network_image/cached_network_image.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appColors.dart';
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
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        centerTitle: true,
        title: Text(
          'Musify.',
          style: TextStyle(
            color: accent,
            fontSize: 35,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
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
                              left: 25,
                              right: 25,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.suggestedPlaylists,
                              style: TextStyle(
                                color: accent,
                                fontSize: 20.0,
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
                                    horizontal: 15.0,
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
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(35.0),
                          child: Spinner(),
                        ),
                      );
              },
            ),
            FutureBuilder(
              future: get10Music('PLgzTt0k8mXzEk586ze4BjvDXR7c-TUSnx'),
              builder: (context, data) {
                return data.hasData
                    ? Wrap(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height / 55,
                              bottom: 10,
                              left: 25,
                              right: 25,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.recommendedForYou,
                              style: TextStyle(
                                color: accent,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15.0,
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
                                );
                              },
                            ),
                          )
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(35.0),
                          child: Spinner(),
                        ),
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
  final String id;
  final String image;

  const CubeContainer({
    required this.id,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
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
                      borderRadius: BorderRadius.circular(10.0),
                      gradient: LinearGradient(
                        colors: [
                          accent.withAlpha(30),
                          Colors.white.withAlpha(30)
                        ],
                      ),
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
