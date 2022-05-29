import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/customWidgets/spinner.dart';
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
            SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
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
        children: <Widget>[
          const Padding(padding: EdgeInsets.only(top: 20)),
          FutureBuilder(
              future: getUserLikedSongs(),
              builder: (context, data) {
                return (data as dynamic).data != null
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        addAutomaticKeepAlives:
                            false, // may be problem with lazyload if it implemented
                        addRepaintBoundaries: false,
                        // Need to display a loading tile if more items are coming
                        itemCount: (data as dynamic).data.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child:
                                  SongBar(song: (data as dynamic).data[index]));
                        })
                    : Align(alignment: Alignment.center, child: Spinner());
              })
        ],
      )),
    );
  }
}
