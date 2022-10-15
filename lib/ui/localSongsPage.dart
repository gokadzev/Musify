import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/style/appTheme.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalSongsPage extends StatefulWidget {
  @override
  State<LocalSongsPage> createState() => _LocalSongsPageState();
}

class _LocalSongsPageState extends State<LocalSongsPage> {
  @override
  void initState() async {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.localSongs,
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
                  margin: const EdgeInsets.only(left: 10, right: 26),
                  height: 200,
                  width: 200,
                  child: Card(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).backgroundColor.withAlpha(30),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.localSongs,
                        style: TextStyle(
                          color: accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${AppLocalizations.of(context)!.yourDownloadedSongsHere}!',
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
                        onPressed: () async => {
                          setActivePlaylist(await getLocalSongs()),
                          Navigator.pushReplacementNamed(context, '/'),
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(accent),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.playAll.toUpperCase(),
                          style: TextStyle(
                            color: isAccentWhite(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const Padding(padding: EdgeInsets.only(top: 40)),
            FutureBuilder(
              future: getLocalSongs(),
              builder: (context, data) {
                if (data.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: Spinner(),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  itemCount: (data as dynamic).data.length as int,
                  itemBuilder: (BuildContext context, int index) {
                    final lsong = {
                      'id': index,
                      'ytid': '',
                      'title': (data as dynamic).data[index].displayName,
                      'image': '',
                      'lowResImage': '',
                      'highResImage': '',
                      'songUrl': (data as dynamic).data[index].data,
                      'album': '',
                      'type': 'song',
                      'localSongId': (data as dynamic).data[index].id,
                      'more_info': {
                        'primary_artists': '',
                        'singers': '',
                      }
                    };

                    return Container(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 15,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          playSong(lsong);
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        splashColor: accent.withOpacity(0.4),
                        hoverColor: accent.withOpacity(0.4),
                        focusColor: accent.withOpacity(0.4),
                        highlightColor: accent.withOpacity(0.4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            QueryArtworkWidget(
                              id: lsong['localSongId'] as int,
                              type: ArtworkType.AUDIO,
                              artworkWidth: 60,
                              artworkHeight: 60,
                              artworkFit: BoxFit.cover,
                              artworkBorder: BorderRadius.circular(8),
                              nullArtworkWidget: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  MdiIcons.musicNoteOutline,
                                  size: 25,
                                  color: accent !=
                                          getMaterialColorFromColor(
                                            const Color(0xFFFFFFFF),
                                          )
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              keepOldArtwork: true,
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(
                                      left: 15,
                                    ),
                                    child: Text(
                                      overflow: TextOverflow.ellipsis,
                                      lsong['title'].toString(),
                                      style: TextStyle(
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
