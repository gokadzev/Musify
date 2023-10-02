import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/services/download_manager.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key, this.playlistId, this.playlistData});

  final dynamic playlistId;
  final dynamic playlistData;

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final _songsList = [];
  dynamic _playlist;

  bool _isLoading = true;
  bool _hasMore = true;
  final _itemsPerPage = 35;
  var _currentPage = 0;
  var _currentLastLoadedId = 0;
  late final playlistLikeStatus =
      ValueNotifier<bool>(isPlaylistAlreadyLiked(widget.playlistId));

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    if (widget.playlistId != null) {
      getPlaylistInfoForWidget(widget.playlistId).then(
        (value) => {
          if (value != null)
            {
              _playlist = value,
              _hasMore = true,
              _loadMore(),
            },
        },
      );
    } else if (widget.playlistData != null) {
      setState(() {
        _playlist = widget.playlistData;
        _hasMore = true;
        _loadMore();
      });
    }
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
    final _count = _playlist['list'].length as int;
    final n = min(_itemsPerPage, _count - _currentPage * _itemsPerPage);
    await Future.delayed(const Duration(seconds: 1), () {
      for (var i = 0; i < n; i++) {
        list.add(_playlist['list'][_currentLastLoadedId]);
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
        title: MarqueeWidget(
          child: Text(
            _playlist != null ? _playlist['title'] : context.l10n()!.playlist,
          ),
        ),
      ),
      body: _playlist != null
          ? CustomScrollView(
              slivers: [
                buildSongList(),
              ],
            )
          : SizedBox(
              height: context.screenSize.height - 100,
              child: const Spinner(),
            ),
    );
  }

  Widget _buildPlaylistImage() {
    return Card(
      color: Colors.transparent,
      child: PlaylistCube(
        id: _playlist['ytid'],
        image: _playlist['image'],
        title: _playlist['title'],
        onClickOpen: false,
        showFavoriteButton: false,
        zoomNumber: 0.55,
      ),
    );
  }

  Widget buildSongList() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Stack(
          children: [
            buildPlaylistHeader(),
            Positioned(
              bottom: 10,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: buildPlayButton(),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        _buildSongListView(),
      ]),
    );
  }

  Widget buildPlaylistHeader() {
    final screenHeight = context.screenSize.height;
    final playlistLength = _playlist['list'].length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Column(
            children: [
              _buildPlaylistImage(),
              if (_playlist['header_desc'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    _playlist['header_desc'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    '[ $playlistLength ${context.l10n()!.songs} ]'
                        .toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
            ],
          ),
        ),
        Row(
          children: [
            if (widget.playlistId != null) _buildLikeButton(),
            _buildDownloadButton(),
            _buildSyncButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildLikeButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: playlistLikeStatus,
      builder: (_, value, __) {
        return IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: value
              ? const Icon(FluentIcons.heart_24_filled)
              : const Icon(FluentIcons.heart_24_regular),
          padding: const EdgeInsets.only(left: 20),
          iconSize: 26,
          onPressed: () {
            playlistLikeStatus.value = !playlistLikeStatus.value;
            updatePlaylistLikeStatus(
              _playlist['ytid'],
              _playlist['image'],
              _playlist['title'],
              playlistLikeStatus.value,
            );
            currentLikedPlaylistsLength.value = value
                ? currentLikedPlaylistsLength.value + 1
                : currentLikedPlaylistsLength.value - 1;
          },
        );
      },
    );
  }

  Widget _buildDownloadButton() {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.arrow_download_24_regular),
      padding: const EdgeInsets.only(left: 20, top: 5),
      iconSize: 26,
      onPressed: () {
        downloadSongsFromPlaylist(context, _playlist['list']);
      },
    );
  }

  Widget _buildSyncButton() {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.arrow_sync_24_filled),
      padding: const EdgeInsets.only(left: 20, top: 5),
      iconSize: 26,
      onPressed: _handleSyncPlaylist,
    );
  }

  void _handleSyncPlaylist() async {
    if (_playlist['ytid'] != null && (_playlist['isCustom'] == null || !_playlist['isCustom']))
      _playlist = await updatePlaylistList(context, _playlist['ytid']);
    _hasMore = true;
    _songsList.clear();
    setState(() {
      _currentPage = 0;
      _currentLastLoadedId = 0;
    });
    _loadMore();
    setState(() {});
  }

  void _updateSongsListonRemove(int indexOfRemovedSong) {
    final dynamic songToRemove = _songsList.elementAt(indexOfRemovedSong);
    showToastwithButton(context,
    context.l10n()!.songRemoved,
    context.l10n()!.undo,
    () => {addSongInCustomPlaylist(_playlist['title'], songToRemove, indexToInsert: indexOfRemovedSong),
      _songsList.insert(indexOfRemovedSong, songToRemove),
      setState(() {})
    });
    _songsList.removeAt(indexOfRemovedSong);
    setState(() {});
  }

  Widget buildPlayButton() {
    return GestureDetector(
      onTap: () {
        setActivePlaylist(_playlist);
        showToast(
          context,
          context.l10n()!.queueInitText,
        );
      },
      child: Icon(
        FluentIcons.play_circle_48_filled,
        color: colorScheme.primary,
        size: 60,
      ),
    );
  }

  Widget _buildSongListView() {
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
              return SongBar(
                _songsList[index],
                true,
                isFromPlaylist: widget.playlistData != null,
                updateOnRemove: () => _updateSongsListonRemove(index),
                passingPlaylist: _playlist,
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
}
