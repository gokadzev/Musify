import 'package:flutter/material.dart';
import 'package:musify/main.dart';
import 'package:musify/services/audio_service.dart';
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
      final songs = await _audioQuery.querySongs();
      setState(() {
        _deviceSongsList = songs.map((song) {
          return {
            'id': song.id,
            'title': song.title,
            'artist': song.artist ?? 'Unknown Artist',
            'album': song.album ?? 'Unknown Album',
            'duration': song.duration ?? 0,
            'filePath': song.data,
          };
        }).toList();
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
      appBar: AppBar(
        title: const Text('Device Songs'), // Change as needed
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deviceSongsList.isNotEmpty
              ? _buildCustomScrollView()
              : const Center(
                  child: Text(
                    'No songs found on device',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
    );
  }

  Widget _buildCustomScrollView() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Found ${_deviceSongsList.length} Songs', // Add header
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return _buildSongListItem(_deviceSongsList[index], index);
            },
            childCount: _deviceSongsList.length,
          ),
        ),
      ],
    );
  }

  Widget _buildSongListItem(Map<String, dynamic> song, int index) {
    final _playlist = {
      'ytid': Key(song['id'].toString()),
      'title': song['title'],
      'list': getDeviceSongNames(),
    };

    return SongBar(
      song,
      true,
      onPlay: () => mah.playPlaylistSong(playlist: _playlist, songIndex: index),
    );
  }

  List<String> getDeviceSongNames() {
    return _deviceSongsList.map((song) => song['title'] as String).toList();
  }

  @override
  void dispose() {
    audioHandler.stop();
    super.dispose();
  }
}
