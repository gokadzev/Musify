import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/style/appColors.dart';

class PlaylistPage extends StatefulWidget {
  final dynamic id;
  const PlaylistPage({Key? key, required this.id}) : super(key: key);

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  @override
  Widget build(BuildContext context) {
    final dynamic id = widget.id;
    return Material(
        child: Container(
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          centerTitle: true,
          title: Text(
            "Playlist",
            style: TextStyle(
              color: accent,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: accent,
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: FutureBuilder(
              future: getPlaylistInfoForWidget(id),
              builder: (context, data) {
                return (data as dynamic).data != null
                    ? Padding(
                        padding: const EdgeInsets.only(
                            top: 30, bottom: 20.0, right: 10.0, left: 10.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 200.0,
                                  width: 200.0,
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    color: Colors.transparent,
                                    child: (data as dynamic).data["image"] != ""
                                        ? Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image:
                                                    CachedNetworkImageProvider(
                                                        (data as dynamic)
                                                            .data["image"]),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 200,
                                            height: 200,
                                            decoration: new BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              gradient: new LinearGradient(
                                                colors: [
                                                  accent.withAlpha(30),
                                                  Colors.white.withAlpha(30)
                                                ],
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Icon(MdiIcons.musicNoteOutline,
                                                    size: 30, color: accent),
                                                Text(
                                                  (data as dynamic)
                                                      .data["title"],
                                                  style:
                                                      TextStyle(color: accent),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12.0),
                                      Text(
                                        (data as dynamic).data["title"],
                                        style: TextStyle(
                                            color: accent,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 16.0),
                                      Text(
                                        (data as dynamic).data["header_desc"],
                                        style: TextStyle(
                                            color: accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              top: 5, bottom: 5)),
                                      TextButton(
                                          onPressed: () => {
                                                setActivePlaylist(
                                                    (data as dynamic)
                                                        .data["list"]),
                                                Navigator.pop(context, false)
                                              },
                                          style: TextButton.styleFrom(
                                              backgroundColor: accent),
                                          child: Text(
                                            "PLAY ALL",
                                            style:
                                                TextStyle(color: Colors.white),
                                          )),
                                      const SizedBox(height: 16.0),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            if ((data as dynamic).data["list"].isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                addAutomaticKeepAlives:
                                    false, // may be problem with lazyload if it implemented
                                addRepaintBoundaries: false,
                                itemCount:
                                    (data as dynamic).data["list"].length,
                                itemBuilder: (BuildContext ctxt, int index) {
                                  return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 5),
                                      child: songBar((data as dynamic)
                                          .data["list"][index]));
                                },
                              )
                          ],
                        ))
                    : Container(
                        height: MediaQuery.of(context).size.height - 100,
                        child: Align(
                            alignment: Alignment.center,
                            child: Center(
                                child: CircularProgressIndicator(
                              color: accent,
                              strokeWidth: 3,
                            ))));
              }),
        ),
      ),
    ));
  }
}
