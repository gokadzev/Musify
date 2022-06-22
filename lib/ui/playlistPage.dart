import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/customWidgets/song_bar.dart';
import 'package:musify/customWidgets/spinner.dart';
import 'package:musify/style/appColors.dart';

class PlaylistPage extends StatefulWidget {
  final dynamic playlist;
  const PlaylistPage({Key? key, required this.playlist}) : super(key: key);

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final _songsList = [];
  late final itemFetcher;

  bool _isLoading = true;
  bool _hasMore = true;
  final _itemsPerPage = 10;
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
    final int _count = widget.playlist["list"].length;
    final n = min(_itemsPerPage, _count - _currentPage * _itemsPerPage);
    await Future.delayed(const Duration(seconds: 1), () {
      for (int i = 0; i < n; i++) {
        list.add(widget.playlist["list"][_currentLastLoadedId]);
        _currentLastLoadedId++;
      }
    });
    _currentPage++;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
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
        child: widget.playlist != null
            ? Column(
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
                          child: widget.playlist["image"] != ""
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: CachedNetworkImageProvider(
                                        widget.playlist["image"].toString(),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
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
                                        widget.playlist["title"].toString(),
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
                              widget.playlist["title"].toString(),
                              style: TextStyle(
                                color: accent,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              widget.playlist["header_desc"].toString(),
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            TextButton(
                              onPressed: () => {
                                setActivePlaylist(
                                  widget.playlist["list"] as List,
                                ),
                                Fluttertoast.showToast(
                                  msg:
                                      "Initialising queue... Because of perfomance, only first 20 songs will be added in the queue.",
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: accent,
                                  textColor: Colors.white,
                                ),
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
                  const SizedBox(height: 30.0),
                  if (_songsList.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      addAutomaticKeepAlives:
                          false, // may be problem with lazyload if it implemented
                      addRepaintBoundaries: false,
                      // Need to display a loading tile if more items are coming
                      itemCount:
                          _hasMore ? _songsList.length + 1 : _songsList.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (index >= _songsList.length) {
                          if (!_isLoading) {
                            _loadMore();
                          }
                          return SizedBox(child: Spinner());
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 5),
                          child: SongBar(_songsList[index]),
                        );
                      },
                    )
                  else
                    Align(alignment: Alignment.center, child: Spinner())
                ],
              )
            : Container(
                height: MediaQuery.of(context).size.height - 100,
                child: Align(alignment: Alignment.center, child: Spinner()),
              ),
      ),
    );
  }
}
