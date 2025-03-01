package com.alexmercerind.flutter_media_metadata;
import android.media.MediaMetadataRetriever;
import java.util.HashMap;

public class MetadataRetriever extends MediaMetadataRetriever {
  public MetadataRetriever() {
    super();
  }

  public void setFilePath(String filePath) {
    setDataSource(filePath);
  }

  public HashMap<String, Object> getMetadata() {
    HashMap<String, Object> metadata = new HashMap<String, Object>();
    metadata.put("trackName", extractMetadata(METADATA_KEY_TITLE));
    metadata.put("trackArtistNames", extractMetadata(METADATA_KEY_ARTIST));
    metadata.put("albumName", extractMetadata(METADATA_KEY_ALBUM));
    metadata.put("albumArtistName", extractMetadata(METADATA_KEY_ALBUMARTIST));
    String trackNumber = extractMetadata(METADATA_KEY_CD_TRACK_NUMBER);
    try {
      metadata.put("trackNumber", trackNumber.split("/")[0].trim());
      metadata.put("albumLength", trackNumber.split("/")[trackNumber.split("/").length - 1].trim());
    } catch (Exception error) {
      metadata.put("trackNumber", null);
      metadata.put("albumLength", null);
    }
    String year = extractMetadata(METADATA_KEY_YEAR);
    String date = extractMetadata(METADATA_KEY_DATE);
    try {
      metadata.put("year", Integer.parseInt(year.trim()));
    } catch (Exception yearException) {
      try {
        metadata.put("year", date.split("-")[0].trim());
      } catch (Exception dateException) {
        metadata.put("year", null);
      }
    }
    metadata.put("genre", extractMetadata(METADATA_KEY_GENRE));
    metadata.put("authorName", extractMetadata(METADATA_KEY_AUTHOR));
    metadata.put("writerName", extractMetadata(METADATA_KEY_WRITER));
    metadata.put("discNumber", extractMetadata(METADATA_KEY_DISC_NUMBER));
    metadata.put("mimeType", extractMetadata(METADATA_KEY_MIMETYPE));
    metadata.put("trackDuration", extractMetadata(METADATA_KEY_DURATION));
    metadata.put("bitrate", extractMetadata(METADATA_KEY_BITRATE));
    return metadata;
  }

  public byte[] getAlbumArt() {
    return getEmbeddedPicture();
  }
}
