import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/style/appColors.dart';

class UserLikedSongs extends StatefulWidget {
  const UserLikedSongs({Key? key}) : super(key: key);

  @override
  State<UserLikedSongs> createState() => _UserLikedSongsState();
}

class _UserLikedSongsState extends State<UserLikedSongs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.userLikedSongs,
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  height: 200,
                  width: 200,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: Colors.transparent,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(30, 255, 255, 255),
                            Color.fromARGB(30, 233, 233, 233),
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
                            AppLocalizations.of(context)!.userLikedSongs,
                            style: TextStyle(color: accent),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.userLikedSongs,
                        style: TextStyle(
                          color: accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${AppLocalizations.of(context)!.yourFavoriteSongsHere}!',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 5, bottom: 5),
                      ),
                      ElevatedButton(
                        onPressed: () => {
                          setActivePlaylist(userLikedSongsList),
                          Navigator.pop(context, false)
                        },
                        style: ElevatedButton.styleFrom(
                          primary: accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.playAll.toUpperCase(),
                          style: TextStyle(
                              color: accent != const Color(0xFFFFFFFF)
                                  ? Colors.white
                                  : Colors.black),
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
        ),
      ),
    );
  }
}
