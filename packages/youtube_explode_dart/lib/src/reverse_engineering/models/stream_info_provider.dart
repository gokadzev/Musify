import 'package:http_parser/http_parser.dart';

import '../../videos/streams/models/audio_track.dart';
import 'fragment.dart';

enum StreamSource { muxed, adaptive, dash, hls }

///
abstract class StreamInfoProvider {
  ///
  static final RegExp contentLenExp = RegExp(r'clen=(\d+)');

  ///
  StreamSource get source;

  ///
  int get tag;

  ///
  String get url;

  MediaType get codec;

  ///
  String? get signature => null;

  ///
  String? get signatureParameter => null;

  ///
  int? get contentLength => null;

  ///
  int? get bitrate => null;

  ///
  String? get container;

  ///
  String? get audioCodec => null;

  ///
  String? get videoCodec => null;

  ///
  @Deprecated('Use qualityLabel')
  String? get videoQualityLabel => null;

  ///
  String? get qualityLabel;

  ///
  int? get videoWidth => null;

  ///
  int? get videoHeight => null;

  ///
  int? get framerate => null;

  ///
  List<Fragment>? get fragments => null;

  ///
  AudioTrack? get audioTrack => null;

  bool get audioOnly => false;

  bool get videoOnly => false;

  int? get audioItag => null;

  /// Whether the stream is DRM protected (encrypted).
  bool get isDrmProtected => false;

  /// Whether the stream is an OTF fragmented format needing `sq` requests.
  bool get isOtf => false;

  /// Whether this is the dynamic-range-compressed variant of an audio format.
  bool get isDrc => false;
}
