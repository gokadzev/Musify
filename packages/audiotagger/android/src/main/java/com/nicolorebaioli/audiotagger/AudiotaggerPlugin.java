package com.nicolorebaioli.audiotagger;

import android.annotation.SuppressLint;
import android.content.Context;
import android.media.MediaScannerConnection;
import android.net.Uri;

import org.jaudiotagger.StandardCharsets;
import org.jaudiotagger.audio.AudioFile;
import org.jaudiotagger.audio.AudioFileIO;
import org.jaudiotagger.audio.AudioHeader;
import org.jaudiotagger.audio.mp3.MP3File;
import org.jaudiotagger.tag.FieldDataInvalidException;
import org.jaudiotagger.tag.FieldKey;
import org.jaudiotagger.tag.Tag;
import org.jaudiotagger.tag.flac.FlacTag;
import org.jaudiotagger.tag.id3.valuepair.ImageFormats;
import org.jaudiotagger.tag.id3.ID3v23Tag;
import org.jaudiotagger.tag.images.Artwork;
import org.jaudiotagger.tag.images.ArtworkFactory;
import org.jaudiotagger.tag.mp4.Mp4Tag;
import org.jaudiotagger.tag.reference.PictureTypes;
import org.jaudiotagger.tag.vorbiscomment.VorbisCommentFieldKey;
import org.jaudiotagger.tag.vorbiscomment.VorbisCommentTag;
import org.jaudiotagger.tag.vorbiscomment.util.Base64Coder;

import java.io.File;
import java.io.RandomAccessFile;
import java.util.HashMap;
import java.util.Map;
import java.nio.charset.Charset;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * AudiotaggerPlugin
 */
public class AudiotaggerPlugin implements MethodCallHandler, FlutterPlugin {
    /**
     * Plugin registration.
     */
    private Context context;
    private MethodChannel channel;

    /* Plugin registration */
    @SuppressWarnings("deprecation")
    public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        final AudiotaggerPlugin instance = new AudiotaggerPlugin();
        instance.onAttachedToEngine(registrar.context(), registrar.messenger());
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.context = applicationContext;
        this.channel = new MethodChannel(messenger, "audiotagger");
        this.channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        this.context = null;
        this.channel.setMethodCallHandler(null);
        this.channel = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "writeTags":
                if (call.hasArgument("path") && call.hasArgument("tags") && call.hasArgument("artwork")) {
                    String path = call.argument("path");
                    Map<String, String> map = call.argument("tags");
                    String artwork = call.argument("artwork");
                    result.success(writeTags(path, map, artwork));
                } else
                    result.error("400", "Missing parameters", null);
                break;
            case "readTags":
                if (call.hasArgument("path"))
                    result.success(readTags((String) call.argument("path")));
                else
                    result.error("400", "Missing parameter", null);
                break;
            case "readArtwork":
                if (call.hasArgument("path"))
                    result.success(readArtwork((String) call.argument("path")));
                else
                    result.error("400", "Missing parameter", null);
                break;
            case "readAudioFile":
                if (call.hasArgument("path"))
                    result.success(readAudioFile((String) call.argument("path")));
                else
                    result.error("400", "Missing parameter", null);
                break;
            default:
                result.notImplemented();
        }
    }

    private boolean writeTags(String path, Map<String, String> map, String artwork) {
        try {
            File mp3File = new File(path);
            AudioFile audioFile = AudioFileIO.read(mp3File);

            
            Tag newTag = audioFile.getTag();
            if (newTag==null)
                throw new Exception("File tag not found");
            
            // Convert ID3v1 tag to ID3v23
            if (audioFile instanceof MP3File) {
                MP3File mp3 = (MP3File) audioFile;
                if (mp3.hasID3v1Tag() && !mp3.hasID3v2Tag()) {
                    newTag = new ID3v23Tag(mp3.getID3v1Tag());
                    mp3.setID3v1Tag(null);  // remove v1 tags
                    mp3.setTag(newTag);     // add v2 tags
                }
            }

            Util.setFieldIfExist(newTag, FieldKey.TITLE, map, "title");
            Util.setFieldIfExist(newTag, FieldKey.ARTIST, map, "artist");
            Util.setFieldIfExist(newTag, FieldKey.GENRE, map, "genre");
            Util.setFieldIfExist(newTag, FieldKey.TRACK, map, "trackNumber");
            Util.setFieldIfExist(newTag, FieldKey.TRACK_TOTAL, map, "trackTotal");
            Util.setFieldIfExist(newTag, FieldKey.DISC_NO, map, "discNumber");
            Util.setFieldIfExist(newTag, FieldKey.DISC_TOTAL, map, "discTotal");
            Util.setFieldIfExist(newTag, FieldKey.LYRICS, map, "lyrics");
            Util.setFieldIfExist(newTag, FieldKey.COMMENT, map, "comment");
            Util.setFieldIfExist(newTag, FieldKey.ALBUM, map, "album");
            Util.setFieldIfExist(newTag, FieldKey.ALBUM_ARTIST, map, "albumArtist");
            Util.setFieldIfExist(newTag, FieldKey.YEAR, map, "year");

            Artwork cover = null;
            // If field is null, it is ignored
            if (artwork != null) {
                // If field is set to an empty string, the field is deleted, otherwise it is set
                if (artwork.trim().length() > 0) {

                    // Delete existing album art
                    newTag.deleteArtworkField();

                    // The following content is treated specially
                    cover = ArtworkFactory.createArtworkFromFile(new File(artwork));

                    if (newTag instanceof Mp4Tag) {
                        RandomAccessFile imageFile = new RandomAccessFile(new File(artwork), "r");
                        byte[] imageData = new byte[(int) imageFile.length()];
                        imageFile.read(imageData);
                        newTag.setField(((Mp4Tag) newTag).createArtworkField(imageData));
                    }else if (newTag instanceof FlacTag) {
                        RandomAccessFile imageFile = new RandomAccessFile(new File(artwork), "r");
                        byte[] imageData = new byte[(int) imageFile.length()];
                        imageFile.read(imageData);
                        newTag.setField(((FlacTag) newTag).createArtworkField(imageData,
                                PictureTypes.DEFAULT_ID,
                                ImageFormats.MIME_TYPE_JPEG,
                                "artwork",
                                0,
                                0,
                                24,
                                0));
                    }else if (newTag instanceof VorbisCommentTag) {
                        RandomAccessFile imageFile = new RandomAccessFile(new File(artwork), "r");
                        byte[] imageData = new byte[(int) imageFile.length()];
                        imageFile.read(imageData);
                        char[] base64Data = Base64Coder.encode(imageData);
                        String base64image = new String(base64Data);
                        newTag.setField(((VorbisCommentTag) newTag).createField(VorbisCommentFieldKey.COVERART, base64image));
                        newTag.setField(((VorbisCommentTag) newTag).createField(VorbisCommentFieldKey.COVERARTMIME, "image/png"));
                    }else {
                        cover = ArtworkFactory.createArtworkFromFile(new File(artwork));
                        newTag.setField(cover);
                    }
                } else {
                    newTag.deleteArtworkField();
                }
            }
            audioFile.commit();

            String[] urls = {path};
            String[] mimes = {"audio/mpeg"};
            MediaScannerConnection.scanFile(context, urls, mimes, new MediaScannerConnection.OnScanCompletedListener() {
                @Override
                public void onScanCompleted(String path, Uri uri) {
                    Log.i("Audiotagger", "Media scanning success");
                }
            });
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private Map<String, String> readTags(String path) {
        try {
            File mp3File = new File(path);
            AudioFile audioFile = AudioFileIO.read(mp3File);

            Map<String, String> map = new HashMap<>();
            Tag tag = audioFile.getTag();

            if (tag != null) {
                map.put("title", tag.getFirst(FieldKey.TITLE));
                map.put("artist", tag.getFirst(FieldKey.ARTIST));
                map.put("genre", tag.getFirst(FieldKey.GENRE));
                map.put("trackNumber", tag.getFirst(FieldKey.TRACK));
                map.put("trackTotal", tag.getFirst(FieldKey.TRACK_TOTAL));
                map.put("discNumber", tag.getFirst(FieldKey.DISC_NO));
                map.put("discTotal", tag.getFirst(FieldKey.DISC_TOTAL));
                map.put("lyrics", tag.getFirst(FieldKey.LYRICS));
                map.put("comment", tag.getFirst(FieldKey.COMMENT));
                map.put("album", tag.getFirst(FieldKey.ALBUM));
                map.put("albumArtist", tag.getFirst(FieldKey.ALBUM_ARTIST));
                map.put("year", tag.getFirst(FieldKey.YEAR));
            }

            return map;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private byte[] readArtwork(String path) {
        try {
            File mp3File = new File(path);
            AudioFile audioFile = AudioFileIO.read(mp3File);
            Tag tag = audioFile.getTag();
            if (tag != null) {
                Artwork artwork = tag.getFirstArtwork();
                if (artwork != null)
                    return artwork.getBinaryData();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private Map<String, Object> readAudioFile(String path) {
        try {
            File mp3File = new File(path);
            AudioFile audioFile = AudioFileIO.read(mp3File);

            Map<String, Object> map = new HashMap<>();
            AudioHeader audioHeader = audioFile.getAudioHeader();

            if (audioHeader != null) {
                map.put("length", audioHeader.getTrackLength());
                map.put("bitRate", audioHeader.getBitRateAsNumber());
                map.put("channels", audioHeader.getChannels());
                map.put("encodingType", audioHeader.getEncodingType());
                map.put("format", audioHeader.getFormat());
                map.put("sampleRate", audioHeader.getSampleRateAsNumber());
                map.put("isVariableBitRate", audioHeader.isVariableBitRate());
            }

            return map;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    enum Version {ID3V1, ID3V2}

    static class Util {
        static void setFieldIfExist(Tag tag, FieldKey field, Map<String, String> map, String key) throws FieldDataInvalidException {
            String value = map.get(key);
            // If field is null, it is ignored
            if (value != null) {
                // If field is set to an empty string, the field is deleted, otherwise it is set
                if (value.trim().length() > 0) {
                    tag.setField(field, value);
                } else {
                    tag.deleteField(field);
                }
            }
        }
    }
}
