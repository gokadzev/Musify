final metadata = await MetadataRetriever.fromFile(File(song.data));
if (metadata.albumArt != null && metadata.albumArt!.isNotEmpty) {
  albumArt = metadata.albumArt;
} else {
  albumArt = null; // or provide a default image
}
