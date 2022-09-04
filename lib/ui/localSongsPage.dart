import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/appTheme.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalSongsPage extends StatefulWidget {
  @override
  State<LocalSongsPage> createState() => _LocalSongsPageState();
}

class _LocalSongsPageState extends State<LocalSongsPage> {
  final _songsList = [];

  bool _isLoading = true;
  bool _hasMore = true;
  final _itemsPerPage = 15;
  var _currentPage = 0;
  var _currentLastLoadedId = 0;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _hasMore = true;
    _loadMore();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadMore() {
    _isLoading = true;
    fetch().then((List fetchedList) {
      if (!mounted) return;
      if (fetchedList.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _songsList.addAll(fetchedList);
        });
      }
    });
  }

  Future<List> fetch() async {
    final list = [];
    final _count = localSongs.length;
    final n = min(_itemsPerPage, _count - _currentPage * _itemsPerPage);
    await Future.delayed(const Duration(seconds: 1), () {
      for (var i = 0; i < n; i++) {
        list.add(localSongs[_currentLastLoadedId]);
        _currentLastLoadedId++;
      }
    });
    _currentPage++;
    return list;
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: Colors.transparent,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color.fromARGB(30, 255, 255, 255),
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
                        onPressed: () => {
                          setActivePlaylist(localSongs),
                        },
                        child: Text(
                          AppLocalizations.of(context)!.playAll.toUpperCase(),
                          style: TextStyle(
                            color: accent != const Color(0xFFFFFFFF)
                                ? Colors.white
                                : Colors.black,
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
                return data.hasData
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        addAutomaticKeepAlives:
                            false, // may be problem with lazyload if it implemented
                        addRepaintBoundaries: false,
                        // Need to display a loading tile if more items are coming
                        itemCount: _hasMore
                            ? _songsList.length + 1
                            : _songsList.length,
                        itemBuilder: (BuildContext context, int index) {
                          if (index >= _songsList.length) {
                            if (!_isLoading) {
                              _loadMore();
                            }
                            return const Spinner();
                          }

                          final lsong = {
                            'id': index,
                            'ytid': '',
                            'title': localSongs[index].displayName,
                            'image': '',
                            'lowResImage': '',
                            'highResImage': '',
                            'songUrl': localSongs[index].data,
                            'album': '',
                            'type': 'song',
                            'localSongId': localSongs[index].id,
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
                              },
                              splashColor: accent.withOpacity(0.4),
                              hoverColor: accent.withOpacity(0.4),
                              focusColor: accent.withOpacity(0.4),
                              highlightColor: accent.withOpacity(0.4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                        color: accent != const Color(0xFFFFFFFF)
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    keepOldArtwork: true,
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                      )
                    : const Spinner();
              },
            )
          ],
        ),
      ),
    );
  }
}
