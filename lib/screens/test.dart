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
                  _showEverything = false;
                  _saveToggleState(_showEverything,
                      folderPath: folder['folder']);
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
