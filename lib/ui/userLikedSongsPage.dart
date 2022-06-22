import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/style/appColors.dart';

class UserLikedSongs extends StatefulWidget {
  @override
  State<UserLikedSongs> createState() => _UserLikedSongsState();
}

class _UserLikedSongsState extends State<UserLikedSongs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        centerTitle: true,
        title: Text(
          "User Liked Songs",
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
          child: Column(
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                height: 200.0,
                width: 200.0,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  color: Colors.transparent,
                  child: Container(
                    width: 200,
                    height: 200,
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
                        Text(
                          "User Liked Songs",
                          style: TextStyle(color: accent),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12.0),
                    Text(
                      "User Liked Songs",
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      "Your favorite songs here!",
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                    ),
                    TextButton(
                      onPressed: () => {
                        setActivePlaylist(userLikedSongsList),
                        Navigator.pop(context, false)
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: accent,
                      ),
                      child: const Text(
                        "PLAY ALL",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const Padding(padding: EdgeInsets.only(top: 20)),
          ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            addAutomaticKeepAlives:
                false, // may be problem with lazyload if it implemented
            addRepaintBoundaries: false,
            // Need to display a loading tile if more items are coming
            itemCount: userLikedSongsList.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: SongBar(userLikedSongsList[index]),
              );
            },
          )
        ],
      )),
    );
  }
}
