import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/ui/playlistsPage.dart';

class UserPlaylistsPage extends StatefulWidget {
  @override
  State<UserPlaylistsPage> createState() => _UserPlaylistsPageState();
}

class _UserPlaylistsPageState extends State<UserPlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          centerTitle: true,
          title: Text(
            "User Playlists",
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
            child: Column(children: <Widget>[
          const Padding(padding: EdgeInsets.only(top: 20)),
          FutureBuilder(
              future: getUserPlaylists(),
              builder: (context, data) {
                return (data as dynamic).data != null &&
                        (data as dynamic).data.length > 0
                    ? Container(
                        child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: ScrollPhysics(),
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16.0, top: 16.0, bottom: 20),
                            children: List.generate(playlists.length, (index) {
                              return Center(
                                  child: GetPlaylist(
                                      index: index,
                                      image: (data as dynamic).data[index]
                                          ["image"],
                                      title: (data as dynamic).data[index]
                                          ["title"],
                                      id: (data as dynamic).data[index]
                                          ["ytid"]));
                            })))
                    : Container();
              })
        ])));
  }
}
