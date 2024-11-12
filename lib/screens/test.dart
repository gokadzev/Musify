import 'package:shared_preferences/shared_preferences.dart';
// other imports remain the same...

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
  bool _showEverything = false;
  bool displaySwitch = true;

  @override
  void initState() {
    super.initState();
    _loadToggleState(); // Load saved toggle state
    _fetchSongsFromDevice();
  }

  Future<void> _loadToggleState() async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve the saved value for _showEverything, defaulting to false if not set
    setState(() {
      _showEverything = prefs.getBool('showEverything') ?? false;
      header = _showEverything ? 'All Songs' : 'Folders';
    });
  }

  Future<void> _saveToggleState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showEverything', value); // Save the toggle state
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

        // Display either all songs or folders based on _showEverything
        _deviceSongsList = _showEverything
            ? _alldeviceSongsList
            : _folders.map((folder) {
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
                    displaySwitch = true;
                    header = context.l10n!.folders;
                  });
                },
              )import 'package:shared_preferences/shared_preferences.dart',;
// other imports remain the same...

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
  bool _showEverything = false;
  bool displaySwitch = true;

  @override
  void initState() {
    super.initState();
    _loadToggleState(); // Load saved toggle state
    _fetchSongsFromDevice();
  }

  Future<void> _loadToggleState() async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve the saved value for _showEverything, defaulting to false if not set
    setState(() {
      _showEverything = prefs.getBool('showEverything') ?? false;
      header = _showEverything ? 'All Songs' : 'Folders';
    });
  }

  Future<void> _saveToggleState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showEverything', value); // Save the toggle state
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

        // Display either all songs or folders based on _showEverything
        _deviceSongsList = _showEverything
            ? _alldeviceSongsList
            : _folders.map((folder) {
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
                    displaySwitch = true;
                    header = context.l10n!.folders;
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
                        header =
                            value ? 'All ${context.l10n!.songs}' : 'Folders';
                        _deviceSongsList = value
                            ? _alldeviceSongsList
                            : _folders.map((folder) {
                                return {
                                  'title': folder['folder'].split('/').last,
                                  'folder': folder['folder'],
                                };
                              }).toList();
                      });
                      _saveToggleState(value); // Save toggle state
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
            )
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

  // other methods remain the same...
}

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
                        header = value ? 'All ${context.l10n!.songs}' : 'Folders';
                        _deviceSongsList = value
                            ? _alldeviceSongsList
                            : _folders.map((folder) {
                                return {
                                  'title': folder['folder'].split('/').last,
                                  'folder': folder['folder'],
                                };
                              }).toList();
                      });
                      _saveToggleState(value); // Save toggle state
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
            )
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

  // other methods remain the same...
}
