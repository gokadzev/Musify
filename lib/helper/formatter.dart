String formatSongTitle(String title) {
  return title
      .replaceAll("&amp;", "&")
      .replaceAll("&#039;", "'")
      .replaceAll("&quot;", '"')
      .replaceAll("[Official Music Video]", "")
      .replaceAll("(Official Music Video)", "")
      .replaceAll("OFFICIAL MUSIC VIDEO", "")
      .replaceAll("Video", "")
      .replaceAll("[Official Video]", "")
      .replaceAll("[OFFICIAL VIDEO]", "")
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

Map<String, dynamic> returnSongLayout(
  index,
  String ytid,
  String title,
  String image,
  String lowResImage,
  String highResImage,
  String artist,
) {
  return {
    "id": index,
    "ytid": ytid,
    "title": formatSongTitle(title.split('-')[title.split('-').length - 1]),
    "image": image,
    "lowResImage": lowResImage,
    "highResImage": highResImage,
    "album": "",
    "type": "song",
    "more_info": {
      "primary_artists": artist,
      "singers": artist,
    }
  };
}
