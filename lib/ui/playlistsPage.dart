import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appColors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:musify/ui/playlistPage.dart';

class PlaylistsPage extends StatefulWidget {
  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          const Padding(padding: EdgeInsets.only(top: 10, bottom: 20.0)),
          Center(
            child: Row(children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Center(
                    child: Text(
                      "Playlists",
                      style: TextStyle(
                        color: accent,
                        fontSize: 35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const Padding(padding: EdgeInsets.only(top: 20)),
          FutureBuilder(
              future: getPlaylists(),
              builder: (context, data) {
                return (data as dynamic).data != null
                    ? Container(
                        child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 200,
                                    childAspectRatio: 1,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20),
                            shrinkWrap: true,
                            physics: ScrollPhysics(),
                            itemCount: (data as dynamic).data.length,
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16.0, top: 16.0, bottom: 20),
                            itemBuilder: (BuildContext context, index) {
                              return Center(
                                  child: GetPlaylist(
                                      index: index,
                                      image: (data as dynamic).data[index]
                                          ["image"],
                                      title: (data as dynamic).data[index]
                                          ["title"],
                                      id: (data as dynamic).data[index]
                                          ["ytid"]));
                            }))
                    : Spinner();
              })
        ])));
  }
}

class GetPlaylist extends StatelessWidget {
  final int index;
  final dynamic image;
  final String title;
  final dynamic id;

  const GetPlaylist({
    required this.index,
    required this.image,
    required this.title,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
        child: GestureDetector(
      onTap: () {
        getPlaylistInfoForWidget(id).then((value) => {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PlaylistPage(playlist: value)))
            });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 15.0),
        child: SizedBox(
          width: size.width * 0.4,
          height: size.height * 0.18,
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Container(
                decoration: new BoxDecoration(boxShadow: [
                  BoxShadow(
                      blurRadius: 6,
                      color: Colors.black.withAlpha(40),
                      offset: const Offset(0, 0))
                ]),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: image != ""
                        ? CachedNetworkImage(
                            width: size.width * 0.4,
                            height: size.height * 0.18,
                            imageUrl: image,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(MdiIcons.musicNoteOutline,
                                    size: 30, color: accent),
                                Text(
                                  title,
                                  style: TextStyle(color: accent),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )),
              ),
              Positioned.fill(
                  child: Container(
                width: size.width * 0.4,
                height: size.height * 0.18,
                decoration: new BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    gradient: new LinearGradient(
                      colors: [
                        accent.withAlpha(30),
                        Colors.white.withAlpha(30)
                      ],
                      begin: index % 2 == 1
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      end: index % 2 == 1
                          ? Alignment.topCenter
                          : Alignment.bottomCenter,
                    )),
              )),
            ],
          ),
        ),
      ),
    ));
  }
}
