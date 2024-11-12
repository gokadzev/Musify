/// `AudioFile` class represent the MP3 header of the file.
/// It contains useful and tecnhical informations about the file.
///
/// It is a read-only class. You can't actually edit this infos in the MP3 file.
class AudioFile {
  /// Track length in seconds
  int? length;

  /// Bitrate of the file
  int? bitRate;

  /// The channel mode (such as `Stereo` or `Mono`)
  String? channels;

  /// The audio file type (such as `mp3`)
  String? encodingType;

  /// The audio file format (such as `MPEG-1 Layer 3`)
  String? format;

  /// The sampling rate
  int? sampleRate;

  /// If the bitrate is variable
  bool? isVariableBitRate;

  /// Default constructor
  AudioFile({
    this.length,
    this.bitRate,
    this.channels,
    this.encodingType,
    this.format,
    this.sampleRate,
    this.isVariableBitRate,
  });

  /// Create an `AudioFile` object from a `Map` of the infos.
  AudioFile.fromMap(Map map) {
    this.length = map["length"];
    this.bitRate = map["bitRate"];
    this.channels = map["channels"];
    this.encodingType = map["encodingType"];
    this.format = map["format"];
    this.sampleRate = map["sampleRate"];
    this.isVariableBitRate = map["isVariableBitRate"];
  }

  /// Get a `Map` of the infos from an `AudioFile` object.
  Map<String, dynamic?> toMap() {
    return <String, dynamic?>{
      "length": length,
      "bitRate": bitRate,
      "channels": channels,
      "encodingType": encodingType,
      "format": format,
      "sampleRate": sampleRate,
      "isVariableBitRate": isVariableBitRate,
    };
  }
}
