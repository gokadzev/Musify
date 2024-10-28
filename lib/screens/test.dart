Widget _buildFolderList() {
  final screenWidth = MediaQuery.of(context).size.width;
  final crossAxisCount =
      screenWidth > 600 ? 4 : 3; // Columns based on screen size
  final folderSize =
      screenWidth / crossAxisCount - 24; // Adjust size for padding and spacing

  return SliverPadding(
    padding: const EdgeInsets.all(12), // Add padding around the grid
    sliver: SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1, // Keeps each folder a square
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
                  _showEverything = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey
                    .shade200, // Light background color for better contrast
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Folder Icon on top
                  Icon(
                    Icons.folder,
                    size: folderSize * 0.4, // Adjust icon size
                    color: Colors.grey.shade600, // Color for folder icon
                  ),
                  SizedBox(height: 8), // Space between icon and text
                  // Folder name text below the icon
                  Text(
                    folder['folder'].split('/').last,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
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
