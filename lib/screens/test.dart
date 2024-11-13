leading: _showEverything
    ? IconButton(
        icon = const Icon(Icons.arrow_back),
        onPressed = () {
          setState(() {
            // If showing everything, toggle back to folders view
            if (_showEverything) {
              _showEverything = false;
              _saveToggleState(_showEverything);
              displaySwitch = true;
              header = context.l10n!.folders;
              songCount = _alldeviceSongsList.length;

              // Reset the song list to show all songs
              _deviceSongsList = _alldeviceSongsList;
            } else {
              // If inside a folder, go back to all songs
              _deviceSongsList = _alldeviceSongsList;
              songCount = _deviceSongsList.length;
              displaySwitch = true;
              header = context.l10n!.folders;
            }
          });
        },
      )
    : null,
