import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalSongsPage extends StatelessWidget {
  const LocalSongsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.localSongs,
          style: TextStyle(
            color: accent,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
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
                          MdiIcons.download,
                          size: 30,
                          color: accent,
                        ),
                        Text(
                          AppLocalizations.of(context)!.localSongs,
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
                      AppLocalizations.of(context)!.localSongs,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      "${AppLocalizations.of(context)!.yourDownloadedSongsHere}!",
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
                        setActivePlaylist(localSongs),
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: accent,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .playAll
                            .toString()
                            .toUpperCase(),
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
            itemCount: localSongs.length,
            itemBuilder: (BuildContext context, int index) {
              final lsong = {
                "id": index,
                "ytid": "",
                "title": localSongs[index].displayName,
                "image": "",
                "lowResImage": "",
                "highResImage": "",
                "songUrl": localSongs[index].data,
                "album": "",
                "type": "song",
                "localSongId": localSongs[index].id,
                "more_info": {
                  "primary_artists": "",
                  "singers": "",
                }
              };

              return Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: Card(
                    color: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.0),
                      onTap: () {
                        playSong(lsong);
                      },
                      splashColor: accent,
                      hoverColor: accent,
                      focusColor: accent,
                      highlightColor: accent,
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            visualDensity: VisualDensity(vertical: 3),
                            leading: Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0,
                                  bottom: 8.0,
                                  left: 8.0,
                                  right: 25.0),
                              child: QueryArtworkWidget(
                                id: lsong["localSongId"] as int,
                                type: ArtworkType.AUDIO,
                                artworkBorder: BorderRadius.circular(8),
                                nullArtworkWidget: Icon(
                                  MdiIcons.musicNoteOutline,
                                  size: 30,
                                  color: accent,
                                ),
                                keepOldArtwork: true,
                              ),
                            ),
                            title: Text(
                              overflow: TextOverflow.ellipsis,
                              lsong['title'].toString(),
                              style: TextStyle(color: accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ));
            },
          )
        ],
      )),
    );
  }
}
