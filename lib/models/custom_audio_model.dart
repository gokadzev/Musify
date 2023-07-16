import 'package:on_audio_query/on_audio_query.dart';

class AudioModelWithArtwork extends AudioModel {
  AudioModelWithArtwork({
    required Map<dynamic, dynamic> info,
    this.albumArtwork,
  }) : super(info);
  final String? albumArtwork;
}
