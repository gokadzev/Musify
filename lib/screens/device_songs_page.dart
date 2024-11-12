import 'package:audiotagger/audiotagger.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/audio_service.dart';
import 'package:musify/services/user_shared_pref.dart';
import 'package:musify/widgets/playlist_cube.dart';
import 'package:musify/widgets/playlist_header.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSongsPage extends StatefulWidget {
  const DeviceSongsPage({super.key});

  @override
  _DeviceSongsPageState createState() => _DeviceSongsPageState();
}

class _DeviceSongsPageState extends State<DeviceSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _isLoading = true;
  List<Map<String, dynamic>> _deviceSongsList = [];
  List<Map<String, dynamic>> _alldeviceSongsList = [];
  List<Map<String, dynamic>> _folders = [];
  String header = 'Folders';
  MusifyAudioHandler mah = MusifyAudioHandler();
  late MusifyAudioHandler audioHandler;
  dynamic _playlist;
  int songCount = 0;
  var selected = 'Name';
  bool displaySwitch = true;
  UserSharedPrefs usp = UserSharedPrefs();
  bool _showEverything = false;

  @override
  void initState() {
    super.initState();
    _fetchSongsFromDevice();
  }

  Future<void> _loadToggleState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showEverything = prefs.getBool('showEverything') ?? false;
      header = _showEverything ? 'All Songs' : 'Folders';
    });
  }

  Future<void> _saveToggleState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showEverything', value);
  }

  Future<void> _fetchSongsFromDevice() async {
    var permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      permissionStatus = await _audioQuery.permissionsRequest();
    }

    if (permissionStatus) {
      final songs = await _audioQuery.querySongs();

      final folderMap = <String, List<Map<String, dynamic>>>{};
      for (final song in songs) {
        final folder = song.data
            .split('/')
            .sublist(0, song.data.split('/').length - 1)
            .join('/');

        folderMap.putIfAbsent(folder, () => []).add({
          'id': song.id,
          'title': song.title,
          'artist': song.artist ?? 'Unknown Artist',
          'album': song.album ?? 'Unknown Album',
          'duration': song.duration ?? 0,
          'filePath': song.data,
          'size': song.size,
          'artUri': 'assets/images/music_icon.png',
          'highResImage': 'assets/images/music_icon.png',
          'lowResImage': 'assets/images/music_icon.png',
          'isLive': false,
          'isOffline': true,
          'dateModified': song.dateModified,
        });
      }

      setState(() {
        _alldeviceSongsList = songs.map((song) {
          return {
            'id': song.id,
            'title': song.title,
            'artist': song.artist ?? 'Unknown Artist',
            'album': song.album ?? 'Unknown Album',
            'duration': song.duration ?? 0,
            'filePath': song.data,
            'size': song.size,
            'artUri': 'assets/images/music_icon.png',
            'highResImage': 'assets/images/music_icon.png',
            'lowResImage': 'assets/images/music_icon.png',
            'isLive': false,
            'isOffline': true,
            'dateModified': song.dateModified,
          };
        }).toList();

        _folders = folderMap.entries.map((entry) {
          return {
            'folder': entry.key,
            'songs': entry.value,
          };
        }).toList();

        songCount = _alldeviceSongsList.length;
        _isLoading = false;
        _deviceSongsList = _folders.map((folder) {
          return {
            'title': folder['folder'].split('/').last,
            'folder': folder['folder'],
          };
        }).toList();
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
    await _loadToggleState();
  }

  Future<Map<String, dynamic>> _fetchSongMetadata(String filePath) async {
    final tagger = Audiotagger();

    try {
      final tag = await tagger.readTags(path: filePath);

      return {
        'title': tag?.title ?? 'Unknown Title',
        'artist': tag?.artist ?? 'Unknown Artist',
        'album': tag?.album ?? 'Unknown Album',
        'artwork': tag?.artwork,
      };
    } catch (e) {
      return {
        'title': 'Unknown Title',
        'artist': 'Unknown Artist',
        'album': 'Unknown Album',
        'artwork': null,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _showEverything
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showEverything = false;
                    _saveToggleState(_showEverything);
                    displaySwitch = true;
                    header = context.l10n!.folders;
                    songCount = _alldeviceSongsList.length;
                  });
                },
              )
            : null,
        actions: [
          if (displaySwitch)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
              child: Row(
                children: [
                  Text('All ${context.l10n!.songs}'),
                  Switch(
                    value: _showEverything,
                    onChanged: (value) {
                      setState(() {
                        _showEverything = value;
                        _saveToggleState(_showEverything);
                        if (value) {
                          header = 'All ${context.l10n!.songs}';
                        } else {
                          header = 'Folders';
                        }
                        _deviceSongsList = _showEverything
                            ? _alldeviceSongsList
                            : _folders.map((folder) {
                                return {
                                  'title': folder['folder'].split('/').last,
                                  'folder': folder['folder'],
                                };
                              }).toList();
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: buildPlaylistHeader(
                header,
                _showEverything
                    ? Icons.music_note_outlined
                    : Icons.folder_outlined,
                songCount,
              ),
            ),
          ),
          if (_showEverything)
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
            ),
          if (_showEverything)
            _buildSongsList()
          else
            _deviceSongsList.isNotEmpty
                ? _showEverything
                    ? _buildSongsList()
                    : _buildFolderList()
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

  Widget _buildFolderList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 5 : 4;
    final folderSize = screenWidth / crossAxisCount - 30;
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final folder = _folders[index];
            return SizedBox(
              width: folderSize,
              height: folderSize,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _deviceSongsList = folder['songs'];
                    songCount = _deviceSongsList.length;
                    displaySwitch = false;
                    header = folder['folder'].split('/').last;
                    _showEverything = true;
                    _saveToggleState(_showEverything);
                  });
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder,
                      size: folderSize * 0.5,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    Text(
                      folder['folder'].split('/').last,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _folders.length,
        ),
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
      hint: Text('   $selected  '),
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
          selected = item!;

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
          } else if (item == 'Size') {
            sortBy('size');
          } else if (item == 'Latest') {
            sortBy('dateModified', asc: false);
          } else if (item == 'Oldest') {
            sortBy('dateModified');
          }

          _playlist = {
            'title': 'Local ${context.l10n!.songs}',
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
        'artUri': song['artUri'],
        'highResImage': song['highResImage'],
        'lowResImage': song['lowResImage'],
        'isLive': false,
        'isOffline': true,
      };
    }).toList();

    _playlist = {
      'title': song['title'],
      'list': songMaps,
    };
    return SongBar(
      song,
      showBtns: false,
      true,
      onPlay: () => audioHandler.playLocalPlaylistSong(
        playlist: _playlist,
        songIndex: index,
      ),
    );
  }

  @override
  void dispose() {
    mah.stop();
    super.dispose();
  }
}
