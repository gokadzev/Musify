import 'package:musify/API/musify.dart';
import 'package:musify/style/appColors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
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
          Padding(padding: EdgeInsets.only(top: 10, bottom: 20.0)),
          Center(
            child: Row(children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: Center(
                    child: GradientText(
                      "Playlists",
                      shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
                      gradient: LinearGradient(colors: [
                        accent,
                        accent,
                      ]),
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Padding(padding: EdgeInsets.only(top: 20)),
          FutureBuilder(
              future: getPlaylists(),
              builder: (context, data) {
                return (data as dynamic).data != null
                    ? Container(
                        child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: ScrollPhysics(),
                            padding: EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                top: 16.0,
                                bottom: 150),
                            children: List.generate(playlists.length, (index) {
                              return Center(
                                  child: getPlaylist(
                                      index,
                                      (data as dynamic).data[index]["image"],
                                      (data as dynamic).data[index]["title"],
                                      (data as dynamic).data[index]["id"]));
                            })))
                    : Container();
              })
        ])));
  }

  Widget getPlaylist(int index, String image, String title, dynamic id) {
    Size size = MediaQuery.of(context).size;

    return SingleChildScrollView(
        child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PlaylistPage(id: id)));
            },
            child: DelayedDisplay(
              delay: Duration(milliseconds: 100 * index + 1),
              fadingDuration: Duration(milliseconds: 600 * index + 1),
              child: Padding(
                padding: EdgeInsets.only(right: 15.0),
                child: SizedBox(
                  width: size.width * 0.4,
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
                          child: CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                          child: Container(
                        width: size.width * 0.4,
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
            )));
  }
}
