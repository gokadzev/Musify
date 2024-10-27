import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/audio_service.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/playlist_header.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:on_audio_query/on_audio_query.dart';

class DeviceSongsPage extends StatefulWidget {
  const DeviceSongsPage({super.key});

  @override
  _DeviceSongsPageState createState() => _DeviceSongsPageState();
}

class _DeviceSongsPageState extends State<DeviceSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _isLoading = true;
  List<Map<String, dynamic>> _deviceSongsList = [];
  MusifyAudioHandler mah = MusifyAudioHandler();
  final bool _isSortedAscending = true;
  final bool _isShuffled = false;
  dynamic _playlist;
  final bool _hasMore = true;
  int songCount = 0;
  String _selectedSortOption = 'Sort by'; // Initial hint text for sorting

  @override
  void initState() {
    super.initState();
    _fetchSongsFromDevice();
  }

  Future<void> _fetchSongsFromDevice() async {
    var permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      permissionStatus = await _audioQuery.permissionsRequest();
    }

    if (permissionStatus) {
      print('LIST OF SONGS');
      final songs = await _audioQuery.querySongs();
      setState(() {
        _deviceSongsList = songs.map((song) {
          print(song);
          return {
            'id': song.id,
            'title': song.title,
            'artist': song.artist ?? 'Unknown Artist',
            'album': song.album ?? 'Unknown Album',
            'duration': song.duration ?? 0,
            'filePath': song.data,
            'size': song.size,
            'dateModified': song.dateModified,
          };
        }).toList();
        songCount = _deviceSongsList.length;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: buildPlaylistHeader(
                'Local Songs',
                Icons.music_note_outlined,
                songCount,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
              child: buildSongActionsRow(),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _deviceSongsList.isNotEmpty
                ? _buildSongsList()
                : const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No songs found on device',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildShuffleSongActionButton() {
    return IconButton(
      color: Theme.of(context).colorScheme.primary,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.arrow_shuffle_16_filled),
      iconSize: 25,
      onPressed: () {
        final _newList = List.of(_playlist['list'])..shuffle();
        setActivePlaylist({
          'title': _playlist['title'],
          'image': _playlist['image'],
          'list': _newList,
        });
      },
    );
  }

  Widget _buildSortSongActionButton() {
    return DropdownButton<String>(
      hint: Text(_selectedSortOption), // Use the selected option as hint text
      borderRadius: BorderRadius.circular(5),
      dropdownColor: Theme.of(context).colorScheme.secondaryContainer,
      underline: const SizedBox.shrink(),
      iconEnabledColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      iconSize: 25,
      icon: const Icon(FluentIcons.filter_16_filled),
      items: <String>[
        context.l10n!.name,
        context.l10n!.artist,
        'Latest',
        'Oldest',
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (item) {
        setState(() {
          _selectedSortOption = item!; // Update hint text with selected item

          void sortBy(String key, {bool asc = true}) {
            _deviceSongsList.sort((a, b) {
              var valueA = a[key];
              var valueB = b[key];
              if (key == 'dateModified' || key == 'size') {
                valueA = valueA ?? 0;
                valueB = valueB ?? 0;
                if (asc) {
                  return (valueA as int).compareTo(valueB as int);
                } else {
                  return (valueB as int).compareTo(valueA as int);
                }
              } else {
                valueA = valueA?.toString().toLowerCase() ?? '';
                valueB = valueB?.toString().toLowerCase() ?? '';
                if (asc) {
                  return valueA.compareTo(valueB);
                } else {
                  return valueB.compareTo(valueA);
                }
              }
            });
          }

          if (item == context.l10n!.name) {
            sortBy('title');
          } else if (item == context.l10n!.artist) {
            sortBy('artist');
          } else if (item == 'Latest') {
            sortBy('dateModified', asc: false);
          } else if (item == 'Oldest') {
            sortBy('dateModified');
          }

          _playlist = {
            'title': 'Local Songs',
            'list': _deviceSongsList.map((song) {
              return {
                'ytid': song['id'].toString(),
                'title': song['title'],
                'audioPath': song['filePath'],
                'isOffline': true,
              };
            }).toList(),
          };
        });
      },
    );
  }

  Widget buildSongActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildSortSongActionButton(),
        const SizedBox(width: 5),
        _buildShuffleSongActionButton(),
      ],
    );
  }

  Widget buildPlaylistHeader(String title, IconData icon, int songsLength) {
    return PlaylistHeader(
      _buildPlaylistImage(title, icon),
      title,
      songsLength,
    );
  }

  Widget _buildPlaylistImage(String title, IconData icon) {
    return PlaylistCube(
      {'title': title},
      onClickOpen: false,
      showFavoriteButton: false,
      size: MediaQuery.sizeOf(context).width / 2.5,
      cubeIcon: icon,
    );
  }

  Widget _buildSongsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return _buildSongListItem(_deviceSongsList[index], index);
        },
        childCount: _deviceSongsList.length,
      ),
    );
  }

  Widget _buildSongListItem(Map<String, dynamic> song, int index) {
    final songMaps = _deviceSongsList.map((song) {
      return {
        'ytid': song['id'].toString(),
        'title': song['title'],
        'audioPath': song['filePath'],
        'isOffline': true,
      };
    }).toList();

    _playlist = {
      'title': song['title'],
      'list': songMaps,
    };

    return SongBar(
      song,
      true,
      onPlay: () => mah.playPlaylistSong(playlist: _playlist, songIndex: index),
    );
  }

  @override
  void dispose() {
    mah.stop();
    super.dispose();
  }
}
