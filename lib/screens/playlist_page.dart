import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/extensions/screen_size.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/marque.dart';
import 'package:musify/widgets/play_button.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({
    super.key,
    this.playlistId,
    this.playlistData,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
  });

  final String? playlistId;
  final dynamic playlistData;
  final IconData cubeIcon;

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final List<dynamic> _songsList = [];
  dynamic _playlist;

  bool _isLoading = true;
  bool _hasMore = true;
  final int _itemsPerPage = 35;
  var _currentPage = 0;
  var _currentLastLoadedId = 0;
  late final playlistLikeStatus =
      ValueNotifier<bool>(isPlaylistAlreadyLiked(widget.playlistId));

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
  }

  Future<void> _initializePlaylist() async {
    _playlist = (widget.playlistId != null)
        ? await getPlaylistInfoForWidget(widget.playlistId)
        : widget.playlistData;

    if (_playlist != null) {
      _loadMore();
    }
  }

  void _loadMore() {
    _isLoading = true;
    fetch().then((List<dynamic> fetchedList) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (fetchedList.isEmpty) {
            _hasMore = false;
          } else {
            _songsList.addAll(fetchedList);
          }
        });
      }
    });
  }

  Future<List<dynamic>> fetch() async {
    final list = <dynamic>[];
    final _count = _playlist['list'].length as int;
    final n = min(_itemsPerPage, _count - _currentPage * _itemsPerPage);
    for (var i = 0; i < n; i++) {
      list.add(_playlist['list'][_currentLastLoadedId]);
      _currentLastLoadedId++;
    }

    _currentPage++;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pop(context, widget.playlistData == _playlist),
        ),
        actions: [
          if (widget.playlistId != null) ...[
            _buildLikeButton(),
          ],
          const SizedBox(width: 10),
          _buildSyncButton(),
          const SizedBox(width: 10),
          if (_playlist != null && _playlist['isCustom'] == true) ...[
            _buildEditButton(),
            const SizedBox(width: 10),
          ],
        ],
      ),
      body: _playlist != null
          ? CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: buildPlaylistHeader(),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return _buildSongListItem(index);
                    },
                    childCount:
                        _hasMore ? _songsList.length + 1 : _songsList.length,
                  ),
                ),
              ],
            )
          : SizedBox(
              height: context.screenSize.height - 100,
              child: const Spinner(),
            ),
    );
  }

  Widget _buildPlaylistImage() {
    return PlaylistCube(
      id: _playlist['ytid'],
      image: _playlist['image'],
      title: _playlist['title'],
      isAlbum: _playlist['isAlbum'],
      onClickOpen: false,
      cubeIcon: widget.cubeIcon,
      showFavoriteButton: false,
    );
  }

  Widget buildPlaylistHeader() {
    final playlistLength = _playlist['list'].length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPlaylistImage(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: MarqueeWidget(
              child: Text(
                _playlist['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_playlist['header_desc'] != null)
            Text(
              _playlist['header_desc'],
              style: const TextStyle(
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '[ $playlistLength ${context.l10n!.songs} ]'.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                ),
              ),
              PlayButton(
                onTap: () {
                  setActivePlaylist(_playlist);
                  showToast(
                    context,
                    context.l10n!.queueInitText,
                  );
                },
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildSyncButton() {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.arrow_sync_24_filled),
      iconSize: 26,
      onPressed: _handleSyncPlaylist,
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.edit_24_filled),
      iconSize: 26,
      onPressed: () => showDialog(
        context: context,
        builder: (BuildContext context) {
          var customPlaylistName = _playlist['title'];
          var imageUrl = _playlist['image'];
          var description = _playlist['header_desc'];

          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 7),
                  TextField(
                    controller: TextEditingController(text: customPlaylistName),
                    decoration: InputDecoration(
                      labelText: context.l10n!.customPlaylistName,
                    ),
                    onChanged: (value) {
                      customPlaylistName = value;
                    },
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: TextEditingController(text: imageUrl),
                    decoration: InputDecoration(
                      labelText: context.l10n!.customPlaylistImgUrl,
                    ),
                    onChanged: (value) {
                      imageUrl = value;
                    },
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: TextEditingController(text: description),
                    decoration: InputDecoration(
                      labelText: context.l10n!.customPlaylistDesc,
                    ),
                    onChanged: (value) {
                      description = value;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  context.l10n!.add.toUpperCase(),
                ),
                onPressed: () {
                  setState(() {
                    final index =
                        userCustomPlaylists.indexOf(widget.playlistData);

                    if (index != -1) {
                      final newPlaylist = {
                        'title': customPlaylistName,
                        'isCustom': true,
                        if (imageUrl != null) 'image': imageUrl,
                        if (description != null) 'header_desc': description,
                        'list': widget.playlistData['list'],
                      };
                      userCustomPlaylists[index] = newPlaylist;
                      addOrUpdateData(
                        'user',
                        'customPlaylists',
                        userCustomPlaylists,
                      );
                      _playlist = newPlaylist;
                      showToast(context, context.l10n!.playlistUpdated);
                    }

                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSyncPlaylist() async {
    if (_playlist['ytid'] != null &&
        (_playlist['isCustom'] == null || !_playlist['isCustom']))
      _playlist = await updatePlaylistList(context, _playlist['ytid']);
    _hasMore = true;
    _songsList.clear();
    setState(() {
      _currentPage = 0;
      _currentLastLoadedId = 0;
      _loadMore();
    });
  }

  void _updateSongsListOnRemove(int indexOfRemovedSong) {
    final dynamic songToRemove = _songsList.elementAt(indexOfRemovedSong);
    showToastWithButton(
      context,
      context.l10n!.songRemoved,
      context.l10n!.undo.toUpperCase(),
      () => {
        addSongInCustomPlaylist(
          _playlist['title'],
          songToRemove,
          indexToInsert: indexOfRemovedSong,
        ),
        _songsList.insert(indexOfRemovedSong, songToRemove),
        setState(() {}),
      },
    );

    setState(() {
      _songsList.removeAt(indexOfRemovedSong);
    });
  }

  Widget _buildSongListItem(int index) {
    if (index >= _songsList.length) {
      if (!_isLoading) {
        _loadMore();
      }
      return const Spinner();
    }
    return SongBar(
      _songsList[index],
      true,
      updateOnRemove: () => _playlist['isCustom'] == true
          ? _updateSongsListOnRemove(index)
          : null,
      passingPlaylist: widget.playlistData,
      songIndexInPlaylist: _playlist['isCustom'] == true ? index : null,
    );
  }
}
