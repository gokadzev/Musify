import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/services/audio_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/formatter.dart';
import 'package:musify/widgets/artist_cube.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:on_audio_query/on_audio_query.dart' hide context;

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ArtistCube(artist: widget.playlist['title']),
                  _buildPlaylistTitle(),
                  _buildPlayAllButton(),
                  const SizedBox(height: 30),
                  if (_songsList.isNotEmpty)
                    _buildSongList()
                  else
                    const Spinner(),
                  _buildOnlineSongList(),
                ],
              )
            : SizedBox(
                height: context.screenSize.height - 100,
                child: const Spinner(),
              ),
      ),
    );
  }

  Widget _buildPlaylistTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        widget.playlist['title'].toString(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildPlayAllButton() {
    return ElevatedButton(
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
    );
  }

  Widget _buildSongList() {
    if (_songsList.isNotEmpty)
      return Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 7),
            itemCount: _hasMore ? _songsList.length + 1 : _songsList.length,
            itemBuilder: (BuildContext context, int index) {
              if (index >= _songsList.length) {
                if (!_isLoading) {
                  _loadMore();
                }
                return const Spinner();
              }

              final lsong =
                  returnSongLayoutFromAudioModel(index, _songsList[index]);

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
                  splashColor: colorScheme.primary.withOpacity(0.4),
                  hoverColor: colorScheme.primary.withOpacity(0.4),
                  focusColor: colorScheme.primary.withOpacity(0.4),
                  highlightColor: colorScheme.primary.withOpacity(0.4),
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
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            FluentIcons.music_note_1_24_regular,
                            size: 25,
                            color:
                                colorScheme.primary != const Color(0xFFFFFFFF)
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
                                lsong['artist'].toString() == ''
                                    ? lsong['title'].toString()
                                    : '${lsong['artist']} - ${lsong['title']}',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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
          ),
        ],
      );
    else
      return SizedBox(
        height: context.screenSize.height - 100,
        child: const Spinner(),
      );
  }

  Widget _buildOnlineSongList() {
    return FutureBuilder(
      future: fetchSongsList(widget.playlist['title'].toString()),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(35),
                child: Spinner(),
              ),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return const SizedBox();
            }
            if (!snapshot.hasData) {
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
                ListView.separated(
                  shrinkWrap: true,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: snapshot.data.length as int,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    return SongBar(snapshot.data[index], true);
                  },
                )
              ],
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
