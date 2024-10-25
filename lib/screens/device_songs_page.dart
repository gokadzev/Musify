import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify/services/audio_handler.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';
import 'package:on_audio_query/on_audio_query.dart';

class DeviceSongsPage extends StatefulWidget {
  const DeviceSongsPage({super.key});

  @override
  _DeviceSongsPageState createState() => _DeviceSongsPageState();
}

class _DeviceSongsPageState extends State<DeviceSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late AudioHandler _audioHandler;
  List<SongModel> _songsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAudioHandler();
    _fetchSongsFromDevice();
  }

  Future<void> _initializeAudioHandler() async {
    _audioHandler = await initAudioHandler();
  }

  Future<void> _fetchSongsFromDevice() async {
    // Request permission to read external storage
    var permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      permissionStatus = await _audioQuery.permissionsRequest();
    }

    if (permissionStatus) {
      // Fetch the list of songs on the device
      final songs = await _audioQuery.querySongs();
      setState(() {
        _songsList = songs;
        _isLoading = false;
      });
    } else {
      // Handle permission denied scenario
      setState(() {
        _isLoading = false;
      });
      // Optionally, show a message to the user about permissions
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Device Songs'),
      ),
      body: _isLoading
          ? const Center(child: Spinner())
          : _songsList.isNotEmpty
              ? ListView.builder(
                  itemCount: _songsList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildSongListItem(_songsList[index]);
                  },
                )
              : const Center(
                  child: Text(
                    'No songs found on device',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
    );
  }

  Widget _buildSongListItem(SongModel song) {
    return SongBar(
      song,
      true,
      onPlay: () {
        _playSong(song);
      },
    );
  }

  Future<void> _playSong(SongModel song) async {
    final mediaItem = MediaItem(
      id: song.data,
      album: song.album ?? 'Unknown Album',
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      duration: Duration(milliseconds: song.duration ?? 0),
    );

    // Play the selected song using the audio handler
    await _audioHandler.stop(); // Stop any currently playing song
    await _audioHandler.playMediaItem(mediaItem);
  }

  @override
  void dispose() {
    _audioHandler.stop();
    super.dispose();
  }
}
