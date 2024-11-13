return GestureDetector(
  onVerticalDragUpdate: (details) {
    if (details.primaryDelta! < 0) {
      // Navigate on upward drag
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NowPlayingPage(),
        ),
      );
    }
  },
  onTap: () {
    // Navigate on tap
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NowPlayingPage(),
      ),
    );
  },
  child: YourChildWidget(), // Replace with your widget here
);
