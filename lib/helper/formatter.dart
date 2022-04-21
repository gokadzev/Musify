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
      .replaceAll("(Lyrics)", "")
      .replaceAll("[Lyrics]", "")
      .replaceAll("[Lyric Video]", "")
      .replaceAll("Lyric Video", "")
      .replaceAll("[Official Lyric Video]", "");
}

returnSongLayout(index, String ytid, String title, String image,
    String highResImage, String artist) {
  return {
    "id": index,
    "ytid": ytid,
    "title": formatSongTitle(title.split('-')[title.split('-').length - 1]),
    "image": image,
    "highResImage": highResImage,
    "album": "",
    "type": "song",
    "more_info": {
      "primary_artists": artist,
      "singers": artist,
    }
  };
}
