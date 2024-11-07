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
    leadingWidget: _buildCoverImage(song['artUri']),
  );
}
