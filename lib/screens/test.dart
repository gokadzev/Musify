Widget _buildOnDeviceButton(BuildContext context) {
  return GestureDetector(
    onTap: () => _checkPermissionAndScanDevice(context),
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      padding: const EdgeInsets.all(16), // Padding inside the button
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Margin around the button
      child: Stack(
        alignment: Alignment.bottomRight, // Align the like button
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.music_note_2_24_regular,
                size: 48,
              ), // Example icon
              const SizedBox(height: 8),
              Text(
                'ON Device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              FluentIcons.heart_24_filled,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              // Handle like action here
            },
          ),
        ],
      ),
    ),
  );
}
