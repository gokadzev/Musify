formatSongTitle(String title) {
  return title
      .replaceAll("&amp;", "&")
      .replaceAll("&#039;", "'")
      .replaceAll("&quot;", "\"")
      .replaceAll("[Official Music Video]", "")
      .replaceAll("(Official Music Video)", "")
      .replaceAll("[Official Video]", "")
      .replaceAll("(Official Video)", "")
      .replaceAll("[official music video]", "")
      .replaceAll("(Official Music Video)", "")
      .replaceAll("[Official Perfomance Video]", "")
      .replaceAll("[Lyrics]", "")
      .replaceAll("[Lyric Video]", "")
      .replaceAll("Lyric Video", "")
      .replaceAll("[Official Lyric Video]", "");
}
