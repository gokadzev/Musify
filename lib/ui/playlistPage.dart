import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';

class PlaylistPage extends StatefulWidget {
  final int id;
  const PlaylistPage({Key? key, required this.id}) : super(key: key);

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  @override
  Widget build(BuildContext context) {
    final int id = widget.id;
    return Material(
        child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff384850),
            Color(0xff263238),
            Color(0xff263238),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          centerTitle: true,
          title: GradientText(
            "Playlist",
            shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
            gradient: LinearGradient(colors: [
              accent,
              accent,
            ]),
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
                        padding: EdgeInsets.only(
                            top: 30, bottom: 20.0, right: 10.0, left: 10.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: (data as dynamic).data["image"],
                                  height: 200.0,
                                  width: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PLAYLIST',
                                        style: TextStyle(
                                            color: accent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 12.0),
                                      Text(
                                        (data as dynamic).data["title"],
                                        style: TextStyle(
                                            color: accent,
                                            fontSize: 14,
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
                                      const SizedBox(height: 16.0),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            (data as dynamic).data["list"].isNotEmpty
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount:
                                        (data as dynamic).data["list"].length,
                                    itemBuilder:
                                        (BuildContext ctxt, int index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 5, bottom: 5),
                                        child: Card(
                                          color: Colors.black12,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          elevation: 0,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            onTap: () {
                                              playSong((data as dynamic)
                                                  .data["list"][index]);
                                              Navigator.pop(context, false);
                                            },
                                            splashColor: accent,
                                            hoverColor: accent,
                                            focusColor: accent,
                                            highlightColor: accent,
                                            child: Column(
                                              children: <Widget>[
                                                ListTile(
                                                  leading: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Icon(
                                                      MdiIcons.musicNoteOutline,
                                                      size: 30,
                                                      color: accent,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    ((data as dynamic)
                                                                .data["list"]
                                                            [index]['title'])
                                                        .toString()
                                                        .split("(")[0]
                                                        .replaceAll(
                                                            "&quot;", "\"")
                                                        .replaceAll(
                                                            "&amp;", "&"),
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  subtitle: Text(
                                                    (data as dynamic)
                                                                .data["list"]
                                                            [index]['more_info']
                                                        ["singers"],
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  trailing: IconButton(
                                                    color: accent,
                                                    icon: Icon(MdiIcons
                                                        .downloadOutline),
                                                    onPressed: () =>
                                                        downloadSong((data
                                                                    as dynamic)
                                                                .data["list"]
                                                            [index]),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container()
                          ],
                        ))
                    : Container();
              }),
        ),
      ),
    ));
  }
}
