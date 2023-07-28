import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/artist_cube.dart';
import 'package:musify/widgets/local_music_bar.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key, required this.playlist});
  final dynamic playlist;

  @override
  _ArtistPagePageState createState() => _ArtistPagePageState();
}

class _ArtistPagePageState extends State<ArtistPage> {
  final _songsList = [];

  bool _isLoading = true;
  bool _hasMore = true;
  final _itemsPerPage = 35;
  var _currentPage = 0;
  var _currentLastLoadedId = 0;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _hasMore = true;
    _loadMore();
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
    final _count = widget.playlist['list'].length as int;
    final n = min(_itemsPerPage, _count - _currentPage * _itemsPerPage);
    await Future.delayed(const Duration(seconds: 1), () {
      for (var i = 0; i < n; i++) {
        list.add(widget.playlist['list'][_currentLastLoadedId]);
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
        title: Text(
          widget.playlist['title'],
        ),
      ),
      body: SingleChildScrollView(
        child: widget.playlist != null
            ? Column(
                children: [
                  ArtistCube(artist: widget.playlist['title']),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      widget.playlist['title'].toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setActivePlaylist(widget.playlist);
                      showToast(
                        context,
                        context.l10n()!.queueInitText,
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        colorScheme.primary,
                      ),
                    ),
                    child: Text(
                      context.l10n()!.playAll.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_songsList.isNotEmpty) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount:
                          _hasMore ? _songsList.length + 1 : _songsList.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (index >= _songsList.length) {
                          if (!_isLoading) {
                            _loadMore();
                          }
                          return const Spinner();
                        }

                        return LocalMusicBar(index, _songsList[index]);
                      },
                    ),
                  ] else
                    const Spinner(),
                  FutureBuilder(
                    future: fetchSongsList(widget.playlist['title'].toString()),
                    builder: (context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(35),
                            child: Spinner(),
                          ),
                        );
                      } else if (snapshot.connectionState ==
                          ConnectionState.done) {
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data.isEmpty) {
                          return Center(
                            child: Text(
                              'Nothing Found!',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 18,
                              ),
                            ),
                          );
                        }
                        return Wrap(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(
                                top: context.screenSize.height / 55,
                                bottom: 10,
                                left: 20,
                                right: 20,
                              ),
                              child: Text(
                                'Online Results',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: false,
                              physics: const BouncingScrollPhysics(),
                              itemCount: snapshot.data.length as int,
                              itemBuilder: (context, index) {
                                return SongBar(snapshot.data[index], true);
                              },
                            )
                          ],
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              )
            : SizedBox(
                height: context.screenSize.height - 100,
                child: const Spinner(),
              ),
      ),
    );
  }
}
