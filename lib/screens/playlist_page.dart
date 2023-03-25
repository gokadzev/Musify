import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/style/app_colors.dart';
import 'package:musify/style/app_themes.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key, required this.playlist});
  final dynamic playlist;

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
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
          AppLocalizations.of(context)!.playlist,
        ),
      ),
      body: SingleChildScrollView(
        child: widget.playlist != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildPlaylistImage(),
                  _buildPlaylistTitle(),
                  _buildPlaylistDescription(),
                  _buildPlayAllButton(),
                  const SizedBox(height: 30),
                  _songsList.isNotEmpty ? _buildSongList() : const Spinner()
                ],
              )
            : SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: const Spinner(),
              ),
      ),
    );
  }

  Widget _buildPlaylistImage() {
    return Card(
      color: Colors.transparent,
      child: PlaylistCube(
        id: widget.playlist['ytid'],
        image: widget.playlist['image'],
        title: widget.playlist['title'],
        onClickOpen: false,
      ),
    );
  }

  Widget _buildPlaylistTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        widget.playlist['title'].toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPlaylistDescription() {
    return Text(
      widget.playlist['header_desc'].toString(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colorScheme.primary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPlayAllButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          setActivePlaylist(widget.playlist);
          showToast(
            AppLocalizations.of(context)!.queueInitText,
          );
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            colorScheme.primary,
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.playAll.toUpperCase(),
          style: TextStyle(
            color: isAccentWhite(),
          ),
        ),
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
              return SongBar(
                _songsList[index],
                true,
              );
            },
          ),
        ],
      );
    else
      return SizedBox(
        height: MediaQuery.of(context).size.height - 100,
        child: const Spinner(),
      );
  }
}
