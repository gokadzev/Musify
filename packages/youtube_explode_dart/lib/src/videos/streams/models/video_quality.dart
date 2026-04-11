/// Video quality.
enum VideoQuality {
  /// Unknown video quality.
  /// (This should be reported to the project's repo if this is *NOT* a DASH Stream .)
  unknown,

  /// Low quality (144p).
  low144,

  /// Low quality (240p).
  low240,

  /// Medium quality (360p).
  medium360,

  /// Medium quality (480p).
  medium480,

  /// High quality (720p).
  high720,

  /// High quality (1080p).
  high1080,

  /// High quality (1440p).
  high1440,

  /// High quality (2160p).
  high2160,

  /// High quality (2880p).
  high2880,

  /// High quality (3072p).
  high3072,

  /// High quality (4320p).
  high4320
}

extension QString on VideoQuality {
  String get qualityString {
    return switch (this) {
      VideoQuality.unknown => 'Unknown',
      VideoQuality.low144 => '144p',
      VideoQuality.low240 => '240p',
      VideoQuality.medium360 => '360p',
      VideoQuality.medium480 => '480p',
      VideoQuality.high720 => '720p',
      VideoQuality.high1080 => '1080p',
      VideoQuality.high1440 => '1440p',
      VideoQuality.high2160 => '2160p',
      VideoQuality.high2880 => '2880p',
      VideoQuality.high3072 => '3072p',
      VideoQuality.high4320 => '4320p',
    };
  }
}
