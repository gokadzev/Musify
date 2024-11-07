void _handlePlaybackEvent(PlaybackEvent event) {
  try {
    if (event.processingState == ProcessingState.completed &&
        audioPlayer.playing) {
      if (!hasNext) {
        skipToNext();
      } else {
        final currentSong = queue.value[audioPlayer.currentIndex ?? 0];
        if (currentSong['isOffline'] == true) {
          // Check the next song in the queue
          int nextIndex = audioPlayer.currentIndex! + 1;
          if (nextIndex < queue.value.length &&
              queue.value[nextIndex]['isOffline'] == true) {
            skipToNext(); // Proceed to the next local song
          } else {
            // Stop or don't play internet songs
            stop(); // Or handle the logic you prefer (e.g., do nothing)
          }
        } else {
          // Proceed with internet-based songs or other logic
          if (playNextSongAutomatically.value && nextRecommendedSong != null) {
            playSong(nextRecommendedSong);
          }
        }
      }
    }
    _updatePlaybackState();
  } catch (e, stackTrace) {
    logger.log('Error handling playback event', e, stackTrace);
  }
}
